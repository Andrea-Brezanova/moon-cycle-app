-- LOCAL DEVELOPMENT ONLY. `supabase db reset` runs this file; a push to a
-- hosted project never does. These two rows are the only thing that turns on
-- the generation entitlement bypass (see public.dev_bypass_active()).
insert into public.app_config (key, value) values
  ('environment', '"local"'),
  ('dev_generation_bypass', 'true')
on conflict (key) do update set value = excluded.value;
