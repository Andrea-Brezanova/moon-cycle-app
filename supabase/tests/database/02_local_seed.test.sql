-- The local seed (supabase/seed.sql) is what turns the development bypass on.
-- This file runs on a database that was seeded; it documents and checks that
-- the bypass is a property of the seed, not of the migration.
begin;
select plan(3);
select is(public.dev_bypass_active(), true, 'a seeded local database has the dev bypass');
delete from public.app_config where key = 'dev_generation_bypass';
select is(public.dev_bypass_active(), false, 'removing one row turns it off');
select is(
  (select count(*)::int from pg_proc where proname = 'dev_bypass_active' and prosecdef),
  1, 'the check is a security-definer function the client cannot alter');
select * from finish();
rollback;
