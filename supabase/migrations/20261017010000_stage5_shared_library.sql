-- Moon Cycle, Stage 5: review and publication of recipes into the shared
-- library. LOCAL ONLY until the owner approves applying it. Additive.
--
-- Lifecycle: private -> candidate -> validated -> approved -> published.
--   * Nothing is ever published automatically. A user can only *suggest* a
--     recipe (private -> candidate), and can withdraw it.
--   * Validation, duplicate check and the editorial decision are separate
--     steps; approval needs a reviewer who is not the recipe's owner and a
--     completed checklist.
--   * Publishing copies a *sanitised* version (no user id, no provenance
--     beyond a source flag) into shared_recipes. The private original is
--     never changed or deleted by publication.
--   * Reviewer actions are audited in an append-only log.

-- ---------------------------------------------------------------- reviewers
-- Granted by the project owner with the service role; no client path.
create table public.reviewers (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create function public.is_reviewer(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.reviewers where user_id = p_user)
$$;

-- --------------------------------------------------------- submission data
alter table public.generated_recipes
  add column submitted_at timestamptz,
  add column submission_consent_at timestamptz;

create table public.publication_reviews (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.generated_recipes (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'validated', 'approved', 'rejected', 'published', 'withdrawn')),
  -- Automated report: structure, claims, food safety, duplicates.
  validation_report jsonb,
  duplicate_of uuid,
  duplicate_score numeric,
  reviewer_id uuid references auth.users (id),
  checklist jsonb,
  notes text,
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
create index publication_reviews_recipe on public.publication_reviews (recipe_id);

-- ---------------------------------------------------------- shared_recipes
-- Sanitised copies of approved recipes. No user id; the internal link back to
-- the source recipe is not exposed to clients.
create table public.shared_recipes (
  id uuid primary key default gen_random_uuid(),
  source_recipe_id uuid not null unique references public.generated_recipes (id),
  phase text not null,
  category text not null,
  title text not null,
  intro text not null,
  minutes integer not null,
  serves integer not null,
  key_food_ids text[] not null,
  ingredients jsonb not null,
  steps jsonb not null,
  -- 'generated' (an AI-assisted recipe, editorially approved).
  source_kind text not null default 'generated',
  published_at timestamptz not null default now()
);

create table public.review_audit (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  actor uuid not null,
  action text not null,
  recipe_id uuid not null,
  detail jsonb
);

alter table public.reviewers enable row level security;
alter table public.publication_reviews enable row level security;
alter table public.shared_recipes enable row level security;
alter table public.review_audit enable row level security;

-- Anyone signed in may read the shared library, minus the internal link.
create policy shared_select on public.shared_recipes
  for select to authenticated using (true);
revoke all on public.shared_recipes, public.reviewers, public.publication_reviews,
  public.review_audit from anon, authenticated;
grant select (id, phase, category, title, intro, minutes, serves, key_food_ids,
  ingredients, steps, source_kind, published_at) on public.shared_recipes to authenticated;
grant select, insert, update, delete on public.shared_recipes, public.reviewers,
  public.publication_reviews, public.review_audit to service_role;
grant usage on all sequences in schema public to service_role;

-- ---------------------------------------------------------------- helpers
create function public.recipe_food_set(p_ingredients jsonb) returns text[]
language sql immutable as $$
  select coalesce(array_agg(distinct x ->> 'food_id' order by x ->> 'food_id'), '{}')
  from jsonb_array_elements(p_ingredients) x where x ->> 'food_id' is not null
$$;

-- Jaccard similarity of two recipes' catalogue-food sets (0..1).
create function public.food_set_similarity(a text[], b text[]) returns numeric
language sql immutable as $$
  select case when cardinality(a) = 0 and cardinality(b) = 0 then 0
    else (select count(*) from (select unnest(a) intersect select unnest(b)) i)::numeric /
         (select count(*) from (select unnest(a) union select unnest(b)) u) end
$$;

-- ------------------------------------------------------------- owner actions
-- The user explicitly suggests a recipe. Only the owner, only from private.
create function public.submit_for_review(p_recipe uuid, p_consent boolean)
returns uuid
language plpgsql security definer set search_path = public as $$
declare r public.generated_recipes; v_review uuid;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  if not coalesce(p_consent, false) then raise exception 'consent_required'; end if;
  select * into r from public.generated_recipes
    where id = p_recipe and user_id = auth.uid() and deleted_at is null for update;
  if not found then raise exception 'not_found'; end if;
  if r.lifecycle <> 'private' then raise exception 'not_private'; end if;
  if r.origin <> 'cloud' then raise exception 'not_reviewable'; end if;
  update public.generated_recipes
    set lifecycle = 'candidate', submitted_at = now(), submission_consent_at = now(), updated_at = now()
    where id = p_recipe;
  insert into public.publication_reviews (recipe_id) values (p_recipe) returning id into v_review;
  insert into public.review_audit (actor, action, recipe_id) values (auth.uid(), 'submitted', p_recipe);
  return v_review;
end $$;

create function public.withdraw_submission(p_recipe uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r public.generated_recipes;
begin
  select * into r from public.generated_recipes
    where id = p_recipe and user_id = auth.uid() for update;
  if not found then raise exception 'not_found'; end if;
  if r.lifecycle not in ('candidate', 'validated') then raise exception 'cannot_withdraw'; end if;
  update public.generated_recipes set lifecycle = 'private', submitted_at = null, updated_at = now()
    where id = p_recipe;
  update public.publication_reviews set status = 'withdrawn', decided_at = now()
    where recipe_id = p_recipe and status in ('pending', 'validated');
  insert into public.review_audit (actor, action, recipe_id) values (auth.uid(), 'withdrawn', p_recipe);
end $$;

-- ----------------------------------------------------- automated validation
-- Called by the service (after the validator ran in the Edge Function). Stores
-- the report, runs the duplicate check, and moves candidate -> validated only
-- if the report passed and no near-duplicate exists.
create function public.record_validation(p_recipe uuid, p_report jsonb, p_passed boolean)
returns text
language plpgsql security definer set search_path = public as $$
declare
  r public.generated_recipes; v_set text[]; v_dup uuid; v_score numeric := 0; v_status text;
begin
  select * into r from public.generated_recipes where id = p_recipe for update;
  if not found or r.lifecycle <> 'candidate' then raise exception 'not_candidate'; end if;
  v_set := public.recipe_food_set(r.ingredients);
  select s.id, public.food_set_similarity(v_set, public.recipe_food_set(s.ingredients))
    into v_dup, v_score
    from public.shared_recipes s
    order by public.food_set_similarity(v_set, public.recipe_food_set(s.ingredients)) desc limit 1;
  if v_dup is not null and v_score < 0.8 then v_dup := null; end if;
  v_status := case when p_passed and v_dup is null then 'validated' else 'pending' end;
  update public.publication_reviews
    set validation_report = p_report, duplicate_of = v_dup, duplicate_score = v_score,
        status = v_status
    where recipe_id = p_recipe and status in ('pending', 'validated');
  if v_status = 'validated' then
    update public.generated_recipes set lifecycle = 'validated', updated_at = now() where id = p_recipe;
  end if;
  insert into public.review_audit (actor, action, recipe_id, detail)
    values ('00000000-0000-0000-0000-000000000000', 'validation_recorded', p_recipe,
            jsonb_build_object('passed', p_passed, 'duplicate_score', v_score));
  return v_status;
end $$;

-- ------------------------------------------------------- reviewer actions
create function public.list_review_queue()
returns table (recipe_id uuid, title text, phase text, lifecycle text, review_status text,
               validation_report jsonb, duplicate_of uuid, duplicate_score numeric)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_reviewer(auth.uid()) then raise exception 'not_reviewer'; end if;
  return query
    select r.id, r.title, r.phase, r.lifecycle, p.status, p.validation_report,
           p.duplicate_of, p.duplicate_score
    from public.generated_recipes r
    join public.publication_reviews p on p.recipe_id = r.id
    where r.lifecycle in ('candidate', 'validated', 'approved') and p.status in ('pending', 'validated', 'approved')
    order by p.created_at;
end $$;

-- Editorial approval: validated recipes only, never by the recipe's owner, and
-- only with every checklist item confirmed.
create function public.approve_recipe(p_recipe uuid, p_checklist jsonb, p_notes text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare r public.generated_recipes;
begin
  if not public.is_reviewer(auth.uid()) then raise exception 'not_reviewer'; end if;
  select * into r from public.generated_recipes where id = p_recipe for update;
  if not found then raise exception 'not_found'; end if;
  if r.user_id = auth.uid() then raise exception 'own_recipe'; end if;
  if r.lifecycle <> 'validated' then raise exception 'not_validated'; end if;
  if not (coalesce((p_checklist ->> 'food_safety')::boolean, false)
      and coalesce((p_checklist ->> 'claims')::boolean, false)
      and coalesce((p_checklist ->> 'duplicates')::boolean, false)
      and coalesce((p_checklist ->> 'ingredients')::boolean, false)) then
    raise exception 'checklist_incomplete';
  end if;
  update public.generated_recipes set lifecycle = 'approved', updated_at = now() where id = p_recipe;
  update public.publication_reviews
    set status = 'approved', reviewer_id = auth.uid(), checklist = p_checklist, notes = p_notes, decided_at = now()
    where recipe_id = p_recipe and status = 'validated';
  insert into public.review_audit (actor, action, recipe_id, detail)
    values (auth.uid(), 'approved', p_recipe, p_checklist);
end $$;

create function public.reject_recipe(p_recipe uuid, p_notes text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_reviewer(auth.uid()) then raise exception 'not_reviewer'; end if;
  update public.generated_recipes set lifecycle = 'private', updated_at = now()
    where id = p_recipe and lifecycle in ('candidate', 'validated', 'approved');
  update public.publication_reviews
    set status = 'rejected', reviewer_id = auth.uid(), notes = p_notes, decided_at = now()
    where recipe_id = p_recipe and status in ('pending', 'validated', 'approved');
  insert into public.review_audit (actor, action, recipe_id, detail)
    values (auth.uid(), 'rejected', p_recipe, jsonb_build_object('notes', p_notes));
end $$;

-- Publishes an approved recipe as a sanitised copy. The private original is
-- left exactly as it was (apart from its lifecycle label).
create function public.publish_recipe(p_recipe uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare r public.generated_recipes; v_shared uuid;
begin
  if not public.is_reviewer(auth.uid()) then raise exception 'not_reviewer'; end if;
  select * into r from public.generated_recipes where id = p_recipe for update;
  if not found then raise exception 'not_found'; end if;
  if r.lifecycle <> 'approved' then raise exception 'not_approved'; end if;
  insert into public.shared_recipes
    (source_recipe_id, phase, category, title, intro, minutes, serves, key_food_ids, ingredients, steps)
  values (r.id, r.phase, r.category, r.title, r.intro, r.minutes, r.serves,
          r.key_food_ids, r.ingredients, r.steps)
  returning id into v_shared;
  update public.generated_recipes set lifecycle = 'published', updated_at = now() where id = p_recipe;
  update public.publication_reviews set status = 'published' where recipe_id = p_recipe and status = 'approved';
  insert into public.review_audit (actor, action, recipe_id, detail)
    values (auth.uid(), 'published', p_recipe, jsonb_build_object('shared_id', v_shared));
  return v_shared;
end $$;

-- Owners keep the right to rename/delete only while the recipe is private:
-- once it is a candidate or beyond, edits to what reviewers see are blocked.
create function public.block_edit_after_submission() returns trigger
language plpgsql as $$
begin
  if old.lifecycle <> 'private' and new.title is distinct from old.title
     and auth.uid() is not null then
    raise exception 'locked_after_submission';
  end if;
  return new;
end $$;
create trigger generated_recipes_lock before update on public.generated_recipes
  for each row execute function public.block_edit_after_submission();

-- Privileges: owners call submit/withdraw; reviewers call the reviewer
-- functions (each checks is_reviewer itself); the rest is service-role only.
revoke all on function
  public.is_reviewer(uuid), public.recipe_food_set(jsonb), public.food_set_similarity(text[], text[]),
  public.submit_for_review(uuid, boolean), public.withdraw_submission(uuid),
  public.record_validation(uuid, jsonb, boolean), public.list_review_queue(),
  public.approve_recipe(uuid, jsonb, text), public.reject_recipe(uuid, text),
  public.publish_recipe(uuid)
  from public, anon, authenticated;
grant execute on function
  public.submit_for_review(uuid, boolean), public.withdraw_submission(uuid),
  public.list_review_queue(), public.approve_recipe(uuid, jsonb, text),
  public.reject_recipe(uuid, text), public.publish_recipe(uuid)
  to authenticated;
grant execute on function
  public.is_reviewer(uuid), public.recipe_food_set(jsonb), public.food_set_similarity(text[], text[]),
  public.record_validation(uuid, jsonb, boolean)
  to service_role;
