-- Moon Cycle: server-side proxy support for external recipe providers
-- (budget, usage and a cache that respects each provider's caching terms).
-- LOCAL ONLY until the owner approves applying it. Additive.
--
-- Provider API keys are NOT stored here. They live only in the Edge Function's
-- secret store (RECIPE_API_KEY etc.), never in a table and never in the app.

create table public.provider_limits (
  provider text primary key,
  enabled boolean not null default false,
  -- Requests that cost money or count against the plan, per UTC month.
  monthly_request_budget integer not null check (monthly_request_budget >= 0),
  -- Spend ceiling per UTC month, millionths of a US dollar (0 = unlimited).
  monthly_cost_budget_micros bigint not null default 0,
  -- Approximate cost of one counted request.
  cost_micros_per_request bigint not null default 0,
  -- How long a response may be kept, from the provider's terms. 0 = not at all.
  cache_ttl_seconds integer not null default 0 check (cache_ttl_seconds >= 0),
  updated_at timestamptz not null default now()
);

-- Every provider starts OFF. Enabling one is a deliberate, separate step.
insert into public.provider_limits
  (provider, enabled, monthly_request_budget, monthly_cost_budget_micros,
   cost_micros_per_request, cache_ttl_seconds)
values
  -- Free test key: development only; no caching terms are stated, so none.
  ('themealdb', false, 2000, 0, 0, 0),
  -- Developer plan: $29/month, 250 unique recipes, 24-hour caching.
  ('recipeapi', false, 250, 29000000, 116000, 86400);

create table public.provider_usage (
  provider text not null,
  month date not null,
  requests integer not null default 0,
  cost_micros bigint not null default 0,
  primary key (provider, month)
);

create table public.provider_cache (
  provider text not null,
  cache_key text not null,
  body jsonb not null,
  fetched_at timestamptz not null default now(),
  expires_at timestamptz not null,
  primary key (provider, cache_key)
);
create index provider_cache_expiry on public.provider_cache (expires_at);

alter table public.provider_limits enable row level security;
alter table public.provider_usage enable row level security;
alter table public.provider_cache enable row level security;
revoke all on public.provider_limits, public.provider_usage, public.provider_cache
  from anon, authenticated;
grant select, insert, update, delete on public.provider_limits,
  public.provider_usage, public.provider_cache to service_role;

-- Takes one counted request from the provider's monthly budget, atomically.
-- Raises provider_disabled, provider_budget_exhausted or provider_cost_exhausted.
create function public.take_provider_budget(p_provider text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  l public.provider_limits;
  u public.provider_usage;
  m date := date_trunc('month', now() at time zone 'utc')::date;
begin
  select * into l from public.provider_limits where provider = p_provider;
  if not found or not l.enabled then
    raise exception 'provider_disabled' using errcode = 'P0001';
  end if;
  insert into public.provider_usage (provider, month) values (p_provider, m)
    on conflict do nothing;
  select * into u from public.provider_usage
    where provider = p_provider and month = m for update;
  if u.requests >= l.monthly_request_budget then
    raise exception 'provider_budget_exhausted' using errcode = 'P0001';
  end if;
  if l.monthly_cost_budget_micros > 0
     and u.cost_micros + l.cost_micros_per_request > l.monthly_cost_budget_micros then
    raise exception 'provider_cost_exhausted' using errcode = 'P0001';
  end if;
  update public.provider_usage
    set requests = requests + 1, cost_micros = cost_micros + l.cost_micros_per_request
    where provider = p_provider and month = m;
end $$;

-- A cached response, or null. Never returns an expired row, and never anything
-- for a provider whose terms allow no caching.
create function public.get_provider_cache(p_provider text, p_key text)
returns jsonb
language sql security definer set search_path = public as $$
  select c.body from public.provider_cache c
  join public.provider_limits l on l.provider = c.provider
  where c.provider = p_provider and c.cache_key = p_key
    and l.cache_ttl_seconds > 0 and c.expires_at > now()
$$;

-- Stores a response for as long as the provider's terms allow (and not at all
-- if they allow none).
create function public.put_provider_cache(p_provider text, p_key text, p_body jsonb)
returns void
language plpgsql security definer set search_path = public as $$
declare ttl integer;
begin
  select cache_ttl_seconds into ttl from public.provider_limits where provider = p_provider;
  if ttl is null or ttl <= 0 then return; end if;
  insert into public.provider_cache (provider, cache_key, body, fetched_at, expires_at)
    values (p_provider, p_key, p_body, now(), now() + make_interval(secs => ttl))
    on conflict (provider, cache_key) do update
      set body = excluded.body, fetched_at = now(), expires_at = excluded.expires_at;
end $$;

-- Deletes expired rows (run on a schedule). Terms that require deletion after the
-- TTL are met by this, not by hoping rows are never read.
create function public.purge_provider_cache() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  delete from public.provider_cache where expires_at <= now();
  get diagnostics n = row_count;
  return n;
end $$;

revoke all on function public.take_provider_budget(text),
  public.get_provider_cache(text, text), public.put_provider_cache(text, text, jsonb),
  public.purge_provider_cache() from public, anon, authenticated;
grant execute on function public.take_provider_budget(text),
  public.get_provider_cache(text, text), public.put_provider_cache(text, text, jsonb),
  public.purge_provider_cache() to service_role;
