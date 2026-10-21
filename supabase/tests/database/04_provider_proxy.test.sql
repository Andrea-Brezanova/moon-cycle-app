begin;
select plan(17);

select is((select enabled from public.provider_limits where provider='recipeapi'), false, 'providers start disabled');
select throws_ok($$select public.take_provider_budget('recipeapi')$$, 'P0001', 'provider_disabled', 'a disabled provider takes no budget');
select throws_ok($$select public.take_provider_budget('unknown')$$, 'P0001', 'provider_disabled', 'an unlisted provider is refused');

update public.provider_limits set enabled = true, monthly_request_budget = 2 where provider = 'recipeapi';
select lives_ok($$select public.take_provider_budget('recipeapi')$$, 'first request');
select lives_ok($$select public.take_provider_budget('recipeapi')$$, 'second request');
select throws_ok($$select public.take_provider_budget('recipeapi')$$, 'P0001', 'provider_budget_exhausted', 'the monthly request budget stops further requests');
select is((select requests from public.provider_usage where provider='recipeapi'), 2, 'usage is counted');
select is((select cost_micros from public.provider_usage where provider='recipeapi'), 232000::bigint, 'and so is approximate cost');

update public.provider_limits set monthly_request_budget = 100, monthly_cost_budget_micros = 300000 where provider = 'recipeapi';
select throws_ok($$select public.take_provider_budget('recipeapi')$$, 'P0001', 'provider_cost_exhausted', 'the monthly cost ceiling stops requests too');

-- Caching follows the provider's terms.
select public.put_provider_cache('themealdb', 'k', '{"a":1}');
select is(public.get_provider_cache('themealdb', 'k'), null, 'no caching where the terms allow none');
select public.put_provider_cache('recipeapi', 'k', '{"a":1}');
select is(public.get_provider_cache('recipeapi', 'k'), '{"a":1}'::jsonb, 'cached where the terms allow it');
update public.provider_cache set expires_at = now() - interval '1 second';
select is(public.get_provider_cache('recipeapi', 'k'), null, 'an expired row is never returned');
select is(public.purge_provider_cache(), 1, 'and is purged');
select is((select count(*)::int from public.provider_cache), 0, 'nothing is kept past its time');

-- Clients cannot touch any of it.
select is(has_table_privilege('authenticated', 'public.provider_cache', 'select'), false, 'clients cannot read the cache');
select is(has_table_privilege('authenticated', 'public.provider_usage', 'update'), false, 'or change usage');
select is(has_function_privilege('authenticated', 'public.take_provider_budget(text)', 'execute'), false, 'or spend budget');

select * from finish();
rollback;
