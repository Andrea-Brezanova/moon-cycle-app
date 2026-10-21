# Development report: Stages 3–8 (autonomous session)

Branch `feature/home-choices-food-detail`. Everything below is **local**: nothing
was pushed, merged, deployed or purchased; no paid API was called; no migration
was applied to a hosted database; no credentials exist in the repository.

## Product decision applied

Build a Meal is **hybrid**: existing recipes first, an approved external recipe
API second (none approved; interface only), AI generation only as the last
resort and only when no source has a recipe using **every** chosen food.
`docs/stage3-plan.md` ("Hybrid recipe discovery") and
`docs/stage3-5-architecture-proposal.md` were updated.

## Completed

| Stage | What | Commit |
|---|---|---|
| Pre | "On your shopping list" label on Foods (chip, food page, semantics) | `5814108` |
| 3.1 | Structured recipe schema, deterministic validator, shared fixtures | `e057ae6` |
| 3.2–3.3 | Service interfaces, dev mock, creator (idempotency, repair retry, failure recovery), personal recipe storage (drift v3), export | `c543b32` |
| Hybrid | Matcher with testable `MatchConfig`, rights model, internal and external sources, discovery orchestrator | `55df63d` |
| UI | Build a Meal results page, create-a-recipe flow, My recipes, personal recipe detail | `7854ffd` |
| 3.4 | Local Supabase backend: schema, RLS, quota, rate limits, budget, kill switch, Edge Function, cloud client | `b06ec7a` |
| 5 | Shared-library review workflow (lifecycle, reviewer actions, sanitised publication, audit) | `21a2ebe` |
| 6 | Try Something New: three foods → three distinct recipes (library first, generation fallback) | `e59ace0` |
| 7 | Log Diary (drift v4), Food Detail / recipe entry points, history | `d394d30` |
| 8 | QA: accessibility tests for all new screens, a real overflow fixed (see below), goldens, real-app verification | this commit |

## What is ready for visual review

All in the dev build (debug, dev flavour), light and dark, and at 320 pt / 1.5×
text (goldens in `test/goldens/screens/goldens/`):

- Home (Log diary now a real card), Build a Meal → **Create my meal** → results
  (complete match; close matches + fallback), **Create a new recipe** progress
  and failure states, a saved recipe with the "Development sample" note,
  **My recipes**.
- Try Something New sheet and the three-recipe results.
- Diary (entries, history), the add-to-diary picker and the entry sheet.

Verified in the **running dev build on the iPhone 16e simulator** (after the
on-device database upgraded from schema v2 to v4): Home cards all unlocked, Log
diary has no lock; Diary → add Apple → saved under Breakfast; Build a meal →
choose foods → Create my meal → "No recipe uses all of these foods" → Create a
new recipe → progress → recipe detail labelled as a development sample.

## Test results (final run)

- `dart format`, `flutter analyze`, `tool/check_layers.dart`: clean.
- Flutter tests excluding goldens: all pass. Goldens: all pass.
- pgTAP: **90** assertions pass (RLS, idempotency, quota, rate limit, budget,
  kill switch, sweeper, Try Something New jobs, review workflow).
- Deno: **42** tests pass (handler, validator parity fixtures, submit).
- `supabase/tests/integration.sh`: end-to-end against the local stack passes
  (sign-up, entitlement refusal, create, idempotent repeat, RLS read, client
  cannot grant Premium, Try Something New).

Real problems found and fixed during QA: the on-device migration lacked the
unique index for personal recipes (caught by the schema-migration test); the
back-button label overflowed at 320 pt / 1.5× text (caught by the new
accessibility tests; fixed in `SubScreenHeader` for every screen).

## Files and components (by area)

- `lib/features/generation/`: request, schema, validator, services, dev mock,
  cloud client, creator, providers, create and My recipes pages.
- `lib/features/discovery/`: matcher, config, sources, orchestrator, results page,
  Try Something New search.
- `lib/features/diary/`: entries, repository, providers, pages and sheets.
- `lib/features/home/`: Try Something New trio controller and results page.
- `lib/core/database/`: `personal_recipes` (v3), `diary_entries` (v4), snapshots.
- `supabase/`: migrations, seed, pgTAP tests, Edge Functions, integration script.
- `tool/sync_backend_catalogue.dart`: keeps the server's food list identical to the
  app's (a test fails if stale).
- Edited existing files: router, routes, Home page, Food detail, Recipe detail,
  Recipes page, Shop (titles of personal recipes), privacy export, `SubScreenHeader`.

Untouched, as required: the food library, phase mappings, the 112 recipes, cycle
calculations, shopping behaviour.

## Migrations awaiting approval (all local only)

- `supabase/migrations/20261017000000_stage3_generation.sql`: accounts' profile,
  entitlements, config, usage, jobs, generated recipes, images, RLS, functions.
- `supabase/migrations/20261017010000_stage5_shared_library.sql`: reviewers,
  reviews, shared recipes, audit, review functions.
- Device (already applied on the simulator build): drift schema v3 and v4, both
  additive.

## Development-only mechanisms (cannot exist in production)

- Dev unlock: a debug build of the dev flavour only (unchanged).
- Dev generation mock and development session: the same two conditions;
  otherwise generation is "unavailable" and no session exists.
- Backend bypass: only when the local seed created both
  `environment = "local"` and `dev_generation_bypass = true`; a hosted project
  (migrations only) cannot have it. pgTAP proves it is off without the seed.
- The Edge Function's stub model runs only when `APP_ENV=local`.

## External services and credentials required for real use

1. Supabase EU project(s), Apple Developer account (Sign in with Apple, App
   Attest), RevenueCat and store products (purchase webhook → `entitlements`).
2. An AI provider key, **after** verifying the exact model (Claude Haiku 5.5 is
   provisionally acceptable), structured-output support, API behaviour, pricing
   and data-handling terms (zero retention, DPA, EU processing).
3. An image provider, after a small comparison (not decided).
4. Privacy policy, consent screen and store labels updated.
5. An approved external recipe API, if wanted: terms on storing, caching,
   attribution and full-instruction display must be checked first.

## Estimated AI usage costs

No provider pricing has been verified, so no figure is claimed here. The
structure that bounds cost is built and tested: a monthly quota per user
(20 as a **proposal**), per-minute and per-hour limits, a daily budget with
shut-off, a remote kill switch, quota charged only on success, and tokens and
cost recorded on every job. Because most meals can be served from the library,
generation is only used for choices no existing recipe covers.

## Privacy and security notes

- Only food ids (and, with consent, diet and allergens) are sent for generation;
  cycle dates never are. The diary stays on the phone and is included in export
  and in "Delete my data" (it lives in the same encrypted database).
- RLS on every user table; clients cannot write jobs, entitlements, usage or
  recipe content; reviewer actions are server-checked, audited and refuse the
  recipe's own owner; publication copies a sanitised version and keeps the
  private original.
- The app holds no provider or service key. Supabase local default keys are not
  committed.
- Risks that remain: the validator is deterministic but a model could still
  write something unsafe that passes it (mitigated by the food-safety and claims
  rules, a human review for sharing, and the "not medical advice" stance);
  server-side re-checking of custom (typed) avoidances is not implemented (the
  app re-validates with the full filter); a local Postgres image bug crashes on
  calling a non-executable function, so tests check privileges instead; the
  hosted setup (secrets, `verify_jwt`, backups) is untested until it exists.

## Not production-ready (still depends on mocks or missing services)

Recipe generation, images, accounts, purchases, "Suggest to Moon Cycle" (no UI
path without accounts), the reviewer tool, external recipes. The diary and
library matching are complete and local.

## Recommended next steps

1. Decide the backend go-ahead (hosted EU project), then build sign-in and the
   purchase webhook.
2. Verify the model and run the 30-selection acceptance set against it with a
   spend cap; measure real cost per recipe.
3. Compare image providers on 20 recipes; decide whether every generated recipe
   gets an image.
4. Decide on an external recipe API (or drop it) on terms, not volume.
5. Build a minimal reviewer screen on top of the existing review functions.
6. Add photos for the 72 recipes that lack them.
