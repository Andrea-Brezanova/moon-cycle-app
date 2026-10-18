-- Moon Cycle, Stage 3: accounts, entitlements, generation jobs, quotas and
-- private generated recipes.
--
-- LOCAL ONLY until the owner approves applying it to a hosted project.
-- Additive: creates new objects only; it changes and deletes nothing.
--
-- Security model
--   * Every user table has row-level security; users reach only their own rows.
--   * Clients can read their own data, and can rename or soft-delete their own
--     recipes. They cannot insert or change jobs, entitlements, usage or
--     recipe content: only the service role (Edge Functions) does.
--   * All business functions are security definer and executable by the service
--     role only.

-- ---------------------------------------------------------------- profiles
create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  -- Explicit consent before the first generation (health-adjacent filters).
  consent_generation_at timestamptz,
  consent_send_filters_at timestamptz,
  region text
);

-- ------------------------------------------------------------ entitlements
-- Written by the purchase webhook (service role) only. The client's own
-- Premium gate is presentation; this table is the server's truth.
create table public.entitlements (
  user_id uuid primary key references auth.users (id) on delete cascade,
  tier text not null check (tier in ('free', 'plus', 'premium')),
  source text not null check (source in ('purchase', 'server_grant')),
  valid_until timestamptz,
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------- app_config
-- Quotas, budget and the kill switch. No client policy: service role only.
create table public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

insert into public.app_config (key, value) values
  ('generation_enabled', 'true'),
  -- An initial proposal, not a final commercial limit.
  ('monthly_quota', '20'),
  ('rate_per_minute', '3'),
  ('rate_per_hour', '10'),
  -- Total spend allowed per UTC day, in millionths of a US dollar ($5).
  ('daily_budget_micros', '5000000'),
  -- A job still running after this long is failed by the sweeper.
  ('stuck_job_minutes', '10');

-- ----------------------------------------------------------- usage_counters
create table public.usage_counters (
  user_id uuid not null references auth.users (id) on delete cascade,
  period date not null, -- first day of the UTC month
  generations_used integer not null default 0 check (generations_used >= 0),
  primary key (user_id, period)
);

-- ---------------------------------------------------------- generation_jobs
create table public.generation_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- One per tap of "Create": a repeat is the same job.
  idempotency_key text not null check (char_length(idempotency_key) between 8 and 80),
  fingerprint text not null,
  phase text not null check (phase in ('menstrual', 'follicular', 'ovulatory', 'luteal')),
  protein_id text not null,
  base_id text not null,
  plant_ids text[] not null check (cardinality(plant_ids) between 2 and 3),
  status text not null default 'generating'
    check (status in ('generating', 'succeeded', 'failed')),
  failure_kind text,
  provider text,
  model text,
  attempts integer not null default 0,
  input_tokens integer,
  output_tokens integer,
  -- Millionths of a US dollar.
  cost_micros bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, idempotency_key)
);
create index generation_jobs_user_created on public.generation_jobs (user_id, created_at desc);
create index generation_jobs_created on public.generation_jobs (created_at);

-- -------------------------------------------------------- generated_recipes
-- Private to the owner. Lifecycle moves past 'private' only by an explicit,
-- authorised step (Stage 5); nothing is published automatically.
create table public.generated_recipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid not null unique references public.generation_jobs (id),
  fingerprint text not null,
  phase text not null check (phase in ('menstrual', 'follicular', 'ovulatory', 'luteal')),
  category text not null check (category in ('breakfast', 'lunch', 'dinner', 'snack')),
  title text not null check (char_length(title) between 3 and 80),
  intro text not null,
  minutes integer not null check (minutes between 5 and 180),
  serves integer not null check (serves between 1 and 8),
  key_food_ids text[] not null,
  ingredients jsonb not null,
  steps jsonb not null,
  lifecycle text not null default 'private'
    check (lifecycle in ('private', 'candidate', 'validated', 'approved', 'published')),
  origin text not null check (origin in ('cloud', 'local_stub')),
  provider text not null,
  model text not null,
  schema_version integer not null,
  validation_report jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index generated_recipes_user on public.generated_recipes (user_id, created_at desc)
  where deleted_at is null;
create index generated_recipes_fingerprint on public.generated_recipes (user_id, fingerprint);

-- ------------------------------------------------------------ recipe_images
-- Optional and independently recoverable: a recipe never depends on this row.
create table public.recipe_images (
  recipe_id uuid primary key references public.generated_recipes (id) on delete cascade,
  status text not null check (status in ('pending', 'ready', 'failed')),
  storage_path text,
  provider text,
  model text,
  attempts integer not null default 0,
  updated_at timestamptz not null default now()
);

-- -------------------------------------------------------------------- RLS
alter table public.profiles enable row level security;
alter table public.entitlements enable row level security;
alter table public.app_config enable row level security;
alter table public.usage_counters enable row level security;
alter table public.generation_jobs enable row level security;
alter table public.generated_recipes enable row level security;
alter table public.recipe_images enable row level security;

create policy profiles_select_own on public.profiles
  for select to authenticated using (user_id = auth.uid());
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (user_id = auth.uid());
create policy profiles_update_own on public.profiles
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy entitlements_select_own on public.entitlements
  for select to authenticated using (user_id = auth.uid());
create policy usage_select_own on public.usage_counters
  for select to authenticated using (user_id = auth.uid());
create policy jobs_select_own on public.generation_jobs
  for select to authenticated using (user_id = auth.uid());

create policy recipes_select_own on public.generated_recipes
  for select to authenticated using (user_id = auth.uid() and deleted_at is null);
create policy recipes_update_own on public.generated_recipes
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy images_select_own on public.recipe_images
  for select to authenticated using (
    exists (
      select 1 from public.generated_recipes r
      where r.id = recipe_id and r.user_id = auth.uid() and r.deleted_at is null
    )
  );

-- Table privileges: default-deny, then only what clients need.
revoke all on all tables in schema public from anon, authenticated;
grant select on public.profiles, public.entitlements, public.usage_counters,
  public.generation_jobs, public.generated_recipes, public.recipe_images
  to authenticated;
grant insert (user_id, consent_generation_at, consent_send_filters_at, region)
  on public.profiles to authenticated;
grant update (consent_generation_at, consent_send_filters_at, region)
  on public.profiles to authenticated;
-- Clients may rename or soft-delete their own recipe, nothing else.
grant update (title, deleted_at) on public.generated_recipes to authenticated;

-- -------------------------------------------------------------- functions
create function public.current_period() returns date
language sql stable as $$
  select date_trunc('month', now() at time zone 'utc')::date
$$;

create function public.config_int(p_key text, p_default integer) returns integer
language sql stable security definer set search_path = public as $$
  select coalesce((select (value #>> '{}')::integer from public.app_config where key = p_key), p_default)
$$;

-- The development bypass exists only where `supabase/seed.sql` created BOTH
-- rows. `supabase db push` to a hosted project never runs the seed, so the
-- bypass cannot exist there; the tests prove it is off without them.
create function public.dev_bypass_active() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select value = '"local"'::jsonb from public.app_config where key = 'environment'), false)
  and coalesce(
    (select value = 'true'::jsonb from public.app_config where key = 'dev_generation_bypass'), false)
$$;

create function public.is_entitled(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.entitlements e
    where e.user_id = p_user and e.tier = 'premium'
      and (e.valid_until is null or e.valid_until > now())
  ) or public.dev_bypass_active()
$$;

-- Starts (or finds) a generation job. Idempotent per (user, key).
-- Raises: generation_disabled, not_entitled, rate_limited, quota_exceeded,
-- budget_exhausted. Does NOT charge the quota: that happens on success only.
create function public.begin_generation(
  p_user uuid, p_key text, p_fingerprint text, p_phase text,
  p_protein text, p_base text, p_plants text[]
) returns table (job_id uuid, status text, recipe_id uuid, is_new boolean)
language plpgsql security definer set search_path = public as $$
declare
  v_job public.generation_jobs;
  v_used integer;
begin
  -- A repeat of the same request returns the existing job, whatever its state.
  select * into v_job from public.generation_jobs
    where user_id = p_user and idempotency_key = p_key;
  if found then
    return query select v_job.id, v_job.status,
      (select r.id from public.generated_recipes r where r.job_id = v_job.id), false;
    return;
  end if;

  if not coalesce((select (value #>> '{}')::boolean from public.app_config
                   where key = 'generation_enabled'), false) then
    raise exception 'generation_disabled' using errcode = 'P0001';
  end if;
  if not public.is_entitled(p_user) then
    raise exception 'not_entitled' using errcode = 'P0001';
  end if;
  if (select count(*) from public.generation_jobs
        where user_id = p_user and created_at > now() - interval '1 minute')
        >= public.config_int('rate_per_minute', 3)
     or (select count(*) from public.generation_jobs
        where user_id = p_user and created_at > now() - interval '1 hour')
        >= public.config_int('rate_per_hour', 10) then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  select coalesce(generations_used, 0) into v_used from public.usage_counters
    where user_id = p_user and period = public.current_period();
  if coalesce(v_used, 0) >= public.config_int('monthly_quota', 20) then
    raise exception 'quota_exceeded' using errcode = 'P0001';
  end if;
  if (select coalesce(sum(cost_micros), 0) from public.generation_jobs
        where created_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc')
        >= public.config_int('daily_budget_micros', 5000000) then
    raise exception 'budget_exhausted' using errcode = 'P0001';
  end if;

  insert into public.generation_jobs
    (user_id, idempotency_key, fingerprint, phase, protein_id, base_id, plant_ids)
  values (p_user, p_key, p_fingerprint, p_phase, p_protein, p_base, p_plants)
  on conflict (user_id, idempotency_key) do nothing
  returning * into v_job;
  if not found then
    -- Lost a race with the same request: return the winner.
    select * into v_job from public.generation_jobs
      where user_id = p_user and idempotency_key = p_key;
    return query select v_job.id, v_job.status,
      (select r.id from public.generated_recipes r where r.job_id = v_job.id), false;
    return;
  end if;
  return query select v_job.id, v_job.status, null::uuid, true;
end $$;

-- Records a validated recipe, completes the job and charges one unit, all in
-- one transaction. Calling it again for the same job returns the same recipe.
create function public.complete_generation(
  p_job uuid, p_recipe jsonb, p_origin text, p_provider text, p_model text,
  p_input_tokens integer, p_output_tokens integer, p_cost_micros bigint,
  p_validation jsonb default '{}'::jsonb
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_job public.generation_jobs;
  v_recipe uuid;
  v_used integer;
begin
  select * into v_job from public.generation_jobs where id = p_job for update;
  if not found then raise exception 'unknown_job' using errcode = 'P0001'; end if;
  select id into v_recipe from public.generated_recipes where job_id = p_job;
  if v_recipe is not null then return v_recipe; end if;
  if v_job.status = 'failed' then raise exception 'job_failed' using errcode = 'P0001'; end if;

  -- Lock this month's counter row so the cap is exact under concurrency.
  insert into public.usage_counters (user_id, period)
    values (v_job.user_id, public.current_period())
    on conflict do nothing;
  select generations_used into v_used from public.usage_counters
    where user_id = v_job.user_id and period = public.current_period() for update;
  if v_used >= public.config_int('monthly_quota', 20) then
    update public.generation_jobs
      set status = 'failed', failure_kind = 'quota_exceeded', cost_micros = coalesce(p_cost_micros, 0),
          provider = p_provider, model = p_model, updated_at = now(), completed_at = now()
      where id = p_job;
    raise exception 'quota_exceeded' using errcode = 'P0001';
  end if;

  insert into public.generated_recipes
    (user_id, job_id, fingerprint, phase, category, title, intro, minutes, serves,
     key_food_ids, ingredients, steps, origin, provider, model, schema_version,
     validation_report)
  values
    (v_job.user_id, p_job, v_job.fingerprint, v_job.phase,
     p_recipe ->> 'category', p_recipe ->> 'title', p_recipe ->> 'intro',
     (p_recipe ->> 'minutes')::integer, (p_recipe ->> 'serves')::integer,
     array_cat(array[v_job.protein_id, v_job.base_id], v_job.plant_ids),
     p_recipe -> 'ingredients', p_recipe -> 'steps', p_origin, p_provider, p_model,
     (p_recipe ->> 'schema_version')::integer, p_validation)
  returning id into v_recipe;

  update public.usage_counters set generations_used = generations_used + 1
    where user_id = v_job.user_id and period = public.current_period();
  update public.generation_jobs
    set status = 'succeeded', provider = p_provider, model = p_model,
        input_tokens = p_input_tokens, output_tokens = p_output_tokens,
        cost_micros = coalesce(p_cost_micros, 0), updated_at = now(), completed_at = now()
    where id = p_job;
  return v_recipe;
end $$;

-- Marks a job failed. Never charges the quota.
create function public.fail_generation(
  p_job uuid, p_kind text, p_cost_micros bigint default 0
) returns void
language sql security definer set search_path = public as $$
  update public.generation_jobs
    set status = 'failed', failure_kind = p_kind,
        cost_micros = cost_micros + coalesce(p_cost_micros, 0),
        updated_at = now(), completed_at = now()
    where id = p_job and status = 'generating'
$$;

-- Fails jobs stuck in 'generating' (a crashed function). Run on a schedule.
create function public.sweep_stuck_jobs() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  update public.generation_jobs
    set status = 'failed', failure_kind = 'timeout', updated_at = now(), completed_at = now()
    where status = 'generating'
      and created_at < now() - make_interval(mins => public.config_int('stuck_job_minutes', 10));
  get diagnostics n = row_count;
  return n;
end $$;

-- "Delete my data": removes everything the user owns (the auth user itself is
-- deleted by the Edge Function with the admin API, which cascades here too).
create function public.delete_user_data(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.recipe_images where recipe_id in
    (select id from public.generated_recipes where user_id = p_user);
  delete from public.generated_recipes where user_id = p_user;
  delete from public.generation_jobs where user_id = p_user;
  delete from public.usage_counters where user_id = p_user;
  delete from public.entitlements where user_id = p_user;
  delete from public.profiles where user_id = p_user;
end $$;

-- Business functions are for the service role only.
revoke all on function
  public.config_int(text, integer), public.dev_bypass_active(), public.is_entitled(uuid),
  public.begin_generation(uuid, text, text, text, text, text, text[]),
  public.complete_generation(uuid, jsonb, text, text, text, integer, integer, bigint, jsonb),
  public.fail_generation(uuid, text, bigint), public.sweep_stuck_jobs(),
  public.delete_user_data(uuid)
  from public, anon, authenticated;
grant execute on function
  public.config_int(text, integer), public.dev_bypass_active(), public.is_entitled(uuid),
  public.begin_generation(uuid, text, text, text, text, text, text[]),
  public.complete_generation(uuid, jsonb, text, text, text, integer, integer, bigint, jsonb),
  public.fail_generation(uuid, text, bigint), public.sweep_stuck_jobs(),
  public.delete_user_data(uuid)
  to service_role;
grant select, insert, update, delete on all tables in schema public to service_role;
