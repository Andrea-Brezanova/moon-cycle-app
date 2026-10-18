-- pgTAP: row-level security, entitlement, quota, idempotency, rate limits.
-- Run with: supabase test db   (needs Docker; local only).
begin;
select plan(48);

-- Two users and a premium entitlement for A. The seed's local-only bypass rows
-- are removed first so every test below runs with the production behaviour.
delete from public.app_config where key in ('environment', 'dev_generation_bypass');
insert into auth.users (id, instance_id, aud, role, email)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@example.test'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@example.test');
insert into public.entitlements (user_id, tier, source)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'premium', 'purchase');

-- ------------------------------------------------------------ entitlement
select is(public.dev_bypass_active(), false, 'no dev bypass without the local seed rows');
select is(public.is_entitled('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), true, 'premium user is entitled');
select is(public.is_entitled('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), false, 'user without a purchase is not');

select throws_ok(
  $$select * from public.begin_generation('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'key-b-00001', 'f1', 'luteal', 'tofu', 'farro', array['kale','carrot'])$$,
  'P0001', 'not_entitled', 'a user who is not entitled cannot start a job');

-- One of the two seed rows alone is not enough.
insert into public.app_config values ('environment', '"local"');
select is(public.dev_bypass_active(), false, 'environment row alone does not open the bypass');
insert into public.app_config values ('dev_generation_bypass', 'true');
select is(public.dev_bypass_active(), true, 'both local rows open the dev bypass');
select is(public.is_entitled('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), true, 'bypass entitles in local');
delete from public.app_config where key in ('environment', 'dev_generation_bypass');
select is(public.is_entitled('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), false, 'bypass gone again');

-- ------------------------------------------------------------ idempotency
create temp table j as
  select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00001', 'f1', 'luteal', 'tofu', 'farro', array['kale','carrot']);
select is((select is_new from j), true, 'first call creates a job');
select is((select status from j), 'generating', 'job is generating');
select is(
  (select job_id from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00001', 'f1', 'luteal', 'tofu', 'farro', array['kale','carrot'])),
  (select job_id from j), 'the same key returns the same job');
select is((select count(*)::int from public.generation_jobs where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'and creates no second job');

-- ------------------------------------------------------------- completion
create temp table r as
  select public.complete_generation(
    (select job_id from j),
    '{"schema_version":1,"category":"dinner","title":"Tofu & Farro Bowl","intro":"A simple bowl of tofu and farro.","minutes":30,"serves":2,"ingredients":[{"label":"Tofu","food_id":"tofu","amount":150,"unit":"g"}],"steps":["a","b","c"]}'::jsonb,
    'local_stub', 'stub', 'stub-v1', 100, 200, 1500) as id;
select isnt((select id from r), null, 'completing a job returns the recipe id');
select is((select generations_used from public.usage_counters where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'success charges one unit');
select is(
  public.complete_generation((select job_id from j), '{"schema_version":1,"category":"dinner","title":"Other","intro":"x","minutes":30,"serves":2,"ingredients":[],"steps":[]}'::jsonb, 'local_stub', 'stub', 'stub-v1', 1, 1, 1),
  (select id from r), 'completing twice returns the same recipe');
select is((select generations_used from public.usage_counters where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'and does not charge twice');
select is((select count(*)::int from public.generated_recipes where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'exactly one recipe row');
select is((select cost_micros from public.generation_jobs where id = (select job_id from j)), 1500::bigint, 'cost is logged on the job');
select is((select status from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00001', 'f1', 'luteal', 'tofu', 'farro', array['kale','carrot'])), 'succeeded', 'a retry of a finished request reports success');
select is((select recipe_id from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00001', 'f1', 'luteal', 'tofu', 'farro', array['kale','carrot'])), (select id from r), 'and returns the saved recipe');

-- ---------------------------------------------------------------- failure
create temp table j2 as
  select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00002', 'f2', 'luteal', 'eggs', 'farro', array['kale','carrot']);
select public.fail_generation((select job_id from j2), 'timeout', 50);
select is((select status from public.generation_jobs where id = (select job_id from j2)), 'failed', 'a failed job is marked failed');
select is((select generations_used from public.usage_counters where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'a failure never charges the quota');

-- ------------------------------------------------------------ rate limits
update public.app_config set value = '2' where key = 'rate_per_minute';
select throws_ok(
  $$select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00003', 'f3', 'luteal', 'beef', 'farro', array['kale','carrot'])$$,
  'P0001', 'rate_limited', 'more jobs than the per-minute limit are refused');
update public.app_config set value = '3' where key = 'rate_per_minute';

-- ------------------------------------------------------------------ quota
update public.app_config set value = '1' where key = 'monthly_quota';
select throws_ok(
  $$select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00004', 'f4', 'luteal', 'beef', 'farro', array['kale','carrot'])$$,
  'P0001', 'quota_exceeded', 'a used-up month refuses new jobs');
update public.app_config set value = '20' where key = 'monthly_quota';

-- ---------------------------------------------------------- budget / kill
update public.app_config set value = '1000' where key = 'daily_budget_micros';
select throws_ok(
  $$select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00005', 'f5', 'luteal', 'beef', 'farro', array['kale','carrot'])$$,
  'P0001', 'budget_exhausted', 'the daily budget stops new jobs');
update public.app_config set value = '5000000' where key = 'daily_budget_micros';
update public.app_config set value = 'false' where key = 'generation_enabled';
select throws_ok(
  $$select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00006', 'f6', 'luteal', 'beef', 'farro', array['kale','carrot'])$$,
  'P0001', 'generation_disabled', 'the kill switch stops new jobs');
update public.app_config set value = 'true' where key = 'generation_enabled';

-- ------------------------------------------------------- stuck-job sweeper
create temp table j3 as
  select * from public.begin_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00007', 'f7', 'luteal', 'lamb', 'farro', array['kale','carrot']);
update public.generation_jobs set created_at = now() - interval '1 hour' where id = (select job_id from j3);
select is(public.sweep_stuck_jobs(), 1, 'the sweeper fails a stuck job');
select is((select failure_kind from public.generation_jobs where id = (select job_id from j3)), 'timeout', 'with a timeout reason');

-- ------------------------------------------------------- Try Something New
update public.app_config set value = '10' where key = 'rate_per_minute';
create temp table t as
  select * from public.begin_try_new_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00008', 'tn1', 'luteal', array['kale','carrot','tofu'], 1);
select is((select kind from public.generation_jobs where id = (select job_id from t)), 'try_new', 'a try-new job has its own kind');
select is((select cardinality(food_ids) from public.generation_jobs where id = (select job_id from t)), 3, 'with its three foods');
select is(
  (select job_id from public.begin_try_new_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00008', 'tn1', 'luteal', array['kale','carrot','tofu'], 1)),
  (select job_id from t), 'and is idempotent');
select throws_ok(
  $$select * from public.begin_try_new_generation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'key-a-00009', 'tn2', 'luteal', array['kale','carrot'], 0)$$,
  '23514', null, 'two foods are not a try-new request');

-- ------------------------------------------------------ RLS as user A / B
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
select is((select count(*)::int from public.generated_recipes), 1, 'A sees their recipe');
select is((select count(*)::int from public.generation_jobs), 4, 'A sees their jobs');

set local "request.jwt.claims" to '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';
select is((select count(*)::int from public.generated_recipes), 0, 'B sees none of A''s recipes');
select is((select count(*)::int from public.generation_jobs), 0, 'B sees none of A''s jobs');
select is((select count(*)::int from public.usage_counters), 0, 'B sees none of A''s usage');
select is((select count(*)::int from public.entitlements), 0, 'B sees none of A''s entitlements');

-- B cannot change A's recipe (the update matches no visible row).
update public.generated_recipes set title = 'Hijacked' where true;
select is((select count(*)::int from public.generated_recipes where title = 'Hijacked'), 0, 'B cannot rename A''s recipe');

-- Clients cannot write jobs, entitlements, usage, or recipe content.
select throws_ok($$insert into public.entitlements (user_id, tier, source) values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','premium','purchase')$$, '42501', null, 'a client cannot grant themselves Premium');
select throws_ok($$insert into public.generation_jobs (user_id, idempotency_key, fingerprint, phase, protein_id, base_id, plant_ids) values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','key-b-99999','f','luteal','a','b',array['c','d'])$$, '42501', null, 'a client cannot insert jobs');
select throws_ok($$update public.usage_counters set generations_used = 0$$, '42501', null, 'a client cannot reset usage');
-- Checked through the privilege catalogue (calling a function the role may not
-- execute crashes this local Postgres image on Apple silicon, an image bug).
select is(has_function_privilege('authenticated', 'public.begin_generation(uuid,text,text,text,text,text,text[])', 'execute'), false, 'a client cannot start jobs');
select is(has_function_privilege('authenticated', 'public.complete_generation(uuid,jsonb,text,text,text,integer,integer,bigint,jsonb)', 'execute'), false, 'a client cannot complete jobs');
select is(has_function_privilege('authenticated', 'public.is_entitled(uuid)', 'execute'), false, 'a client cannot probe entitlements');
select is(has_function_privilege('anon', 'public.begin_generation(uuid,text,text,text,text,text,text[])', 'execute'), false, 'nor can an anonymous caller');
select is(has_function_privilege('service_role', 'public.begin_generation(uuid,text,text,text,text,text,text[])', 'execute'), true, 'the service role can');
select throws_ok($$select * from public.app_config$$, '42501', null, 'a client cannot read quotas or config');

select * from finish();
rollback;
