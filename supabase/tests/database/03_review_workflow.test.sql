-- pgTAP: the review and publication workflow (Stage 5).
begin;
select plan(39);

insert into auth.users (id, instance_id, aud, role, email) values
  ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'owner@example.test'),
  ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'reviewer@example.test'),
  ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'other@example.test');
insert into public.entitlements (user_id, tier, source) values
  ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'premium', 'purchase');
insert into public.reviewers (user_id) values ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2');

-- Three cloud recipes by the owner: r1 (will be published), r2 (a duplicate of
-- r1's foods), r3 (for withdraw/reject).
create temp table made (n int, job uuid, recipe uuid);
do $$
declare j uuid; r uuid; i int;
begin
  for i in 1..3 loop
    select job_id into j from public.begin_generation('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'review-key-' || i, 'fp' || i, 'luteal',
      case i when 3 then 'eggs' else 'tofu' end, 'farro', array['kale','carrot']);
    r := public.complete_generation(j,
      jsonb_build_object('schema_version', 1, 'category', 'dinner', 'title', 'Recipe number ' || i,
        'intro', 'A simple bowl.', 'minutes', 30, 'serves', 2,
        'ingredients', case i when 3
          then '[{"label":"Eggs","food_id":"eggs"},{"label":"Farro","food_id":"farro"},{"label":"Kale","food_id":"kale"},{"label":"Carrot","food_id":"carrot"}]'::jsonb
          else '[{"label":"Tofu","food_id":"tofu"},{"label":"Farro","food_id":"farro"},{"label":"Kale","food_id":"kale"},{"label":"Carrot","food_id":"carrot"}]'::jsonb end,
        'steps', '["a","b","c"]'::jsonb),
      'cloud', 'provider', 'model', 1, 1, 100);
    insert into made values (i, j, r);
    -- Space the jobs out so the per-minute rate limit does not apply.
    update public.generation_jobs set created_at = now() - make_interval(mins => 5 * i) where id = j;
  end loop;
end $$;

grant select on made to authenticated;
-- Reads a recipe's lifecycle regardless of the caller's RLS (for assertions).
create function pg_temp.lc(p uuid) returns text language sql security definer as
  $f$ select lifecycle from public.generated_recipes where id = p $f$;

-- ----------------------------------------------------------- as the owner
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1","role":"authenticated"}';

select throws_ok($$select public.submit_for_review((select recipe from made where n = 1), false)$$, 'P0001', 'consent_required', 'submitting needs explicit consent');
select lives_ok($$select public.submit_for_review((select recipe from made where n = 1), true)$$, 'the owner can suggest their recipe');
select is((select lifecycle from public.generated_recipes where id = (select recipe from made where n = 1)), 'candidate', 'it becomes a candidate, not published');
select is((select count(*)::int from public.shared_recipes), 0, 'and nothing is published');
select throws_ok($$select public.submit_for_review((select recipe from made where n = 1), true)$$, 'P0001', 'not_private', 'it cannot be submitted twice');
select throws_ok($$update public.generated_recipes set title = 'Edited after submit' where id = (select recipe from made where n = 1)$$, 'P0001', 'locked_after_submission', 'a submitted recipe can no longer be edited');
select throws_ok($$select * from public.list_review_queue()$$, 'P0001', 'not_reviewer', 'the owner cannot open the review queue');
select throws_ok($$select public.approve_recipe((select recipe from made where n = 1), '{}')$$, 'P0001', 'not_reviewer', 'the owner cannot approve');
select throws_ok($$select count(*) from public.review_audit$$, '42501', null, 'the audit log is not readable by clients');
select throws_ok($$insert into public.reviewers (user_id) values ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1')$$, '42501', null, 'a user cannot make themselves a reviewer');

-- ------------------------------------------------- another user is not owner
set local "request.jwt.claims" to '{"sub":"c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3","role":"authenticated"}';
select throws_ok($$select public.submit_for_review((select recipe from made where n = 2), true)$$, 'P0001', 'not_found', 'someone else cannot submit another user''s recipe');
select throws_ok($$select public.withdraw_submission((select recipe from made where n = 1))$$, 'P0001', 'not_found', 'or withdraw it');

-- ------------------------------------------------------ automated validation
reset role;
select is(public.record_validation((select recipe from made where n = 1), '{"passed":true}', true), 'validated', 'a passing report validates the candidate');
select is((select lifecycle from public.generated_recipes where id = (select recipe from made where n = 1)), 'validated', 'lifecycle: validated');

-- ------------------------------------------------------------ reviewer path
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2","role":"authenticated"}';
select is((select count(*)::int from public.list_review_queue()), 1, 'the reviewer sees the queue');
select throws_ok($$select public.publish_recipe((select recipe from made where n = 1))$$, 'P0001', 'not_approved', 'a validated recipe cannot be published before approval');
select throws_ok($$select public.approve_recipe((select recipe from made where n = 1), '{"food_safety":true,"claims":true}')$$, 'P0001', 'checklist_incomplete', 'approval needs the whole checklist');
select lives_ok($$select public.approve_recipe((select recipe from made where n = 1), '{"food_safety":true,"claims":true,"duplicates":true,"ingredients":true}', 'ok')$$, 'a reviewer approves with a complete checklist');
select is(pg_temp.lc((select recipe from made where n = 1)), 'approved', 'lifecycle: approved');
select is((select count(*)::int from public.shared_recipes), 0, 'approval alone does not publish');
select lives_ok($$select public.publish_recipe((select recipe from made where n = 1))$$, 'then it is published');
select throws_ok($$select public.publish_recipe((select recipe from made where n = 1))$$, 'P0001', 'not_approved', 'and cannot be published twice');
select is((select count(*)::int from public.shared_recipes), 1, 'one sanitised copy exists');

-- --------------------------------------------------- sanitised copy and RLS
set local "request.jwt.claims" to '{"sub":"c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3","role":"authenticated"}';
select is((select count(*)::int from public.shared_recipes), 1, 'any signed-in user can read the shared library');
select throws_ok($$select source_recipe_id from public.shared_recipes$$, '42501', null, 'but not the internal link to the source recipe');
select is((select count(*)::int from public.generated_recipes), 0, 'and still not the private original');
select ok(
  not exists (select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'shared_recipes' and column_name in ('user_id', 'provider', 'model', 'job_id')),
  'the shared copy has no user id, provider, model or job');

-- The owner's original is unchanged and still private to them.
set local "request.jwt.claims" to '{"sub":"a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1","role":"authenticated"}';
select is((select title from public.generated_recipes where id = (select recipe from made where n = 1)), 'Recipe number 1', 'the private original is preserved');
select is((select lifecycle from public.generated_recipes where id = (select recipe from made where n = 1)), 'published', 'and is labelled published');
select throws_ok($$update public.shared_recipes set title = 'x'$$, '42501', null, 'the owner cannot edit the shared copy');

-- ---------------------------------------------- duplicates, reject, withdraw
select lives_ok($$select public.submit_for_review((select recipe from made where n = 2), true)$$, 'a second recipe is suggested');
reset role;
select is(public.record_validation((select recipe from made where n = 2), '{"passed":true}', true), 'pending', 'a near-duplicate of a shared recipe is held back, not validated');
select is((select duplicate_of is not null from public.publication_reviews where recipe_id = (select recipe from made where n = 2)), true, 'with the duplicate recorded');
select cmp_ok((select duplicate_score from public.publication_reviews where recipe_id = (select recipe from made where n = 2)), '>=', 0.8, 'at or above the threshold');

set local role authenticated;
set local "request.jwt.claims" to '{"sub":"b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2","role":"authenticated"}';
select lives_ok($$select public.reject_recipe((select recipe from made where n = 2), 'duplicate')$$, 'a reviewer can reject');
select is(pg_temp.lc((select recipe from made where n = 2)), 'private', 'a rejected recipe goes back to private');

set local "request.jwt.claims" to '{"sub":"a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1","role":"authenticated"}';
select lives_ok($$select public.submit_for_review((select recipe from made where n = 3), true)$$, 'a third is suggested');
select lives_ok($$select public.withdraw_submission((select recipe from made where n = 3))$$, 'and withdrawn by its owner');
select is((select lifecycle from public.generated_recipes where id = (select recipe from made where n = 3)), 'private', 'back to private');

select * from finish();
rollback;
