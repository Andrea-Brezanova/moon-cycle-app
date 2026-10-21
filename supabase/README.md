# Moon Cycle backend (local development only)

Postgres + Auth + Edge Functions on Supabase, run locally in Docker. **Nothing
here is deployed, and no migration has been applied to a hosted database.**
Hosting needs the owner's approval (see `docs/stage3-plan.md`).

## What is here

| Path | What |
|---|---|
| `migrations/` | SQL migrations, applied in order. Additive only. |
| `seed.sql` | Local-only seed. Turns on the development generation bypass. A push to a hosted project never runs it. |
| `tests/database/` | pgTAP: RLS, entitlement, idempotency, quota, rate limit, budget, kill switch, sweeper. |
| `tests/integration.sh` | End to end against the local stack (sign up, call the function, check rows and RLS). Refuses to run unless the API is `127.0.0.1`. |
| `functions/generate-recipe/` | The Edge Function. |
| `functions/_shared/` | Handler, validator (a port of the Dart one), model interface, stub model, slim catalogue. Deno tests live beside them. |

## Run it

```bash
supabase start -x studio,imgproxy,logflare,vector,mailpit,supavisor,postgres-meta
supabase test db                      # pgTAP
cp supabase/functions/.env.local.example supabase/functions/.env.local
supabase functions serve --env-file supabase/functions/.env.local
supabase/tests/integration.sh         # in another terminal
docker run --rm -v "$PWD":/app -w /app denoland/deno deno test --allow-read supabase/functions/_shared/
dart run tool/sync_backend_catalogue.dart   # after foods.json changes
```

## Security model

- **Row-level security** on every table. Clients read their own rows; they can
  rename or soft-delete their own recipes (column grants) and nothing else.
  Jobs, entitlements, usage and recipe content are written only by the service
  role inside functions.
- **Entitlement is server truth**: `entitlements` (written by the purchase
  webhook, not built yet). The app's Premium gate and the development unlock
  never authorise generation.
- **Development bypass**: `dev_bypass_active()` is true only when *both*
  `environment = "local"` and `dev_generation_bypass = true` exist in
  `app_config`. Only `seed.sql` creates them, so a hosted project (migrations
  only) cannot have it; pgTAP proves it is off without the seed rows.
- **No provider key anywhere in the app.** The function reads none yet: its
  model is the local stub (only when `APP_ENV=local`) or "unavailable".
- **Quota** is charged only when a recipe is saved, in the same transaction.
  Configurable in `app_config` (`monthly_quota` 20 is a proposal, rate limits,
  `daily_budget_micros`, `generation_enabled` kill switch). Every job records
  provider, model, tokens and `cost_micros`.
- **Idempotency**: unique `(user_id, idempotency_key)`; a repeat returns the
  existing job or recipe and never calls the model.

## Known local issue

On the local Postgres image for Apple silicon, *calling* a function the role may
not execute crashes the server (signal 11). Tests therefore check privileges
with `has_function_privilege` instead of calling.

## Before anything is hosted

Owner approval; a Supabase EU project; the purchase webhook (writes
`entitlements`); real sign-in (Sign in with Apple, email link); the verified
model adapter (see `docs/stage3-plan.md` "Decisions for real AI integration");
privacy policy and consent screen; `verify_jwt` on, JWT secret and keys only in
the project's secret store.
