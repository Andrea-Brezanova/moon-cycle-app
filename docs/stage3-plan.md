# Stage 3 plan: AI recipe generation (for approval)

> **Status: recommendation only.** Nothing here is built, purchased, migrated
> or deployed. It refines `docs/stage3-5-architecture-proposal.md`; where the
> two differ, this document is the newer recommendation. Prices, model names
> and vendor limits must be re-verified on the day of decision.

## Hybrid recipe discovery (final product decision; supersedes AI-first)

Build a Meal looks for an existing recipe first and generates only when none
fits. Sources are tried in priority order and the search stops at the first
source with a **complete** match:

1. **Internal library**: the 112 reviewed Moon Cycle recipes.
2. **Approved external recipe API**: none is approved or configured yet; the
   production default is `NoExternalRecipeClient`.
3. **AI generation fallback**: the pipeline described in the rest of this
   document, offered only when 1 and 2 have no complete match.

```
Create my meal
  → selected food ids (protein, base, 2–3 plants)
  → diet and avoidance filter (same FoodFilter as the rest of the app)
  → RecipeDiscovery: internal → external
       complete match?  yes → show those recipes (existing recipe detail)
                        no  → close matches as suggestions + "Create a new recipe"
  → generation fallback (validated, saved privately, optional image)
```

**Matching rules** (`lib/features/discovery`, all thresholds in `MatchConfig`):

- *Complete*: every selected food id is in the recipe (ingredient line or key
  food). Extra supporting ingredients are fine; excluded ones never are, because
  recipes the diet or avoidances exclude are dropped before ranking. Equivalent
  foods do not count (red lentils are not green lentils).
- *Good partial*: not complete, but covers at least `goodPartialMinCoverage`
  (0.6) of the weighted selection (protein 3, base 3, each plant 2), uses at
  least 2 selected foods, and includes the protein or the base. Partial matches
  are listed separately as "close matches", with what is missing, and are never
  presented as the requested meal.
- *Insufficient*: not offered.
- Ranking: complete before partial, then score = coverage × 100 + phase bonus
  (orders only, never decides a match) + completeness bonus − a small penalty per
  extra food (so simpler recipes win ties), then recipe id for stability.
- With the current library about 44 of 112 recipes can fully satisfy some
  protein + base + 2-plant choice, so a complete internal match will often not
  exist for a free-form choice. That is expected: it is what the fallback is
  for, and close matches keep the screen useful.

**One normalised model.** Screens receive a `RecipeCandidate`: the app's own
`Recipe` plus `source` (`internal`, `externalApi`, `aiGenerated`), `RecipeRights`
and the `RecipeMatch`. UI never depends on a provider. External adapters
implement one interface (`ExternalRecipeClient`) and return recipes already
normalised to catalogue food ids, with ids namespaced `x-<provider>-<id>`.

**Rights metadata** (`RecipeRights`) travels with every recipe: licence,
attribution text, source URL, `mayDisplayFull`, `mayStore`, `requiresLinkBack`
and `mayPublish`. Internal recipes are displayable, storable and publishable.
Generated recipes are the user's and are never published automatically.
External recipes carry their provider's terms; any whose terms forbid showing
them in full are dropped, and ones that forbid storing are shown but never saved
to the personal library.

**External API evaluation is a prerequisite** (not done, no provider chosen):
before any adapter is written, the provider's terms must be checked for storing
and caching, commercial use, attribution and link-back, display of full
instructions, rate limits and price, and data processing (what we send is only
food ids and the diet filter). Candidates are compared on those criteria, not on
recipe count. Until one is approved, source 2 stays empty.

**Cost effect:** most meals will not need the model at all, which cuts the
generation cost estimates in §6 by the share of requests served from sources 1
and 2. Generation also no longer runs without an explicit tap on "Create a new
recipe", so quota is only used on a deliberate request.

## Summary of recommendations

| # | Topic | Recommendation |
|---|---|---|
| 1 | Backend | **Supabase** (Postgres + Auth + Edge Functions + RLS), EU region, one project per environment; a thin provider-agnostic `generate` function |
| 2 | Auth / ownership | Optional accounts: Sign in with Apple + email link. Every recipe row has `user_id` with owner-only RLS. Free app stays account-free |
| 3 | Text model | Anthropic **Claude Haiku 5.5** (`claude-haiku-5-5`) with strict JSON schema output; escalate the one repair retry to Sonnet 5.5 only if Haiku fails validation. Behind a `RecipeModel` interface |
| 4 | Images | **Do not generate an image per recipe at launch.** Ship text recipes with the existing food-illustration hero; add images as a separate, optional, rate-limited step after a small provider bake-off (3 candidates, 20 prompts) |
| 5 | Validation | Deterministic validator is the gate; allergens/diet are **derived from linked foods**, never from the model; food-safety and banned-claim rules; one repair retry |
| 6 | Cost | Text ≈ well under 1 cent per recipe on Haiku-class pricing (verify); images dominate cost. Per-user monthly cap (start 20) bounds worst case |
| 7 | Security | JWT identity only, server-side entitlement lookup, quotas + per-IP limits, idempotency, App Attest / Play Integrity, kill switch |
| 8 | Flutter integration | Generated recipes parse into the existing `Recipe` model; `RecipeDetailPage` gains a source-aware lookup and image widget. No new detail screen |
| 9 | Auto-save | Server persists the recipe in the same transaction that completes the job; the app caches it in drift and shows it in a "My recipes" section |
| 10 | Failure / duplicates | Client-generated idempotency key, job state machine, quota charged only on success, unique constraint `(user_id, idempotency_key)` plus a content fingerprint to catch near-duplicates |

## 1. Backend and database

**Choice: Supabase, EU region.** It gives relational storage (recipes ↔ foods
fit Postgres, not a document store), row-level security as the privacy
mechanism, auth, storage and serverless functions in one bill (about 25 USD a
month to start). Alternatives (Firebase, custom serverless + Neon) are worse
fits for the reasons in the proposal.

Design rules that keep it maintainable and portable:

- **All business logic in one `generate-recipe` function** plus small ones for
  `delete-account`, `entitlement-webhook` and `list-recipes`. No logic in
  database triggers beyond timestamps.
- **Plain SQL migrations in the repo** (`supabase/migrations/`), reviewed like
  code. This keeps us able to move to any Postgres host.
- **Catalogue copy:** the function needs the food library to validate IDs. Ship
  the same `foods.json` as a build artifact of the research repo, versioned,
  loaded by the function. A test asserts the app's and server's catalogue
  hashes match (otherwise a food the app offers could be rejected).
- Long work (images) goes through a job table polled by a worker/cron, not
  inside the request, because edge functions have short time limits.
- Three environments: local (Supabase CLI + Docker), staging, production.

Tables as in the proposal (§10); the Stage 3 subset is `profiles`,
`entitlements`, `usage_counters`, `generation_jobs`, `generated_recipes`.
`recipe_images`, review and shared tables wait for later stages.

## 2. Authentication and private ownership

- Sign in with Apple (mandatory when any social login is offered) and an email
  magic link. Google only if Android demands it.
- Account creation happens at the moment the user first taps Generate, with a
  plain explanation (what is sent, what is stored). Nothing changes for users
  who never do.
- App holds a short-lived JWT and a refresh token in `flutter_secure_storage`
  (already a dependency).
- **Ownership is enforced in the database**, not only in code:
  `generated_recipes` has RLS `user_id = auth.uid()` for select/update/delete,
  and **no client insert policy**; only the function (service role) inserts.
  A pgTAP/SQL test proves user B cannot read user A's rows.
- Account deletion removes the user's rows and files in one function call and
  is wired into the existing "Delete my data" flow.

## 3. Text-generation provider and model

**Recommendation: Claude Haiku 5.5, via the Anthropic API, with structured
(JSON-schema) output and low temperature.** Reasons: the task is constrained
(IDs in, schema out), so a small fast model is enough; it is the cheapest
current tier; and strict schemas plus our validator carry the quality, not
model size. Keep the call behind a `RecipeModel` interface (prompt, schema,
parse) so a different provider is a one-file change.

- Escalation: if validation fails, the single repair retry includes the
  validator's error list and may use Sonnet 5.5. Track how often this happens;
  if it is more than a few percent, make Sonnet the default and recheck cost.
- Prompt is assembled **server-side from IDs and catalogue names**. No
  free-text user input in Stage 3 (removes prompt-injection and moderation
  work).
- Zero-retention / no-training terms and a DPA with the provider are a
  precondition for production (see §7 and credentials list).
- Acceptance test set: 30 fixed selections (including vegan, gluten-free,
  allergen-heavy and awkward combinations) whose outputs are checked by the
  validator and read by a person before launch.

## 4. Image generation

**Recommendation: decouple images from Stage 3.** The app already has a
no-photo fallback and a food illustration hero, and the recipe is useful
without a picture. Generating an image per recipe is the largest cost and the
largest quality, rights and moderation risk.

Proposed path:

1. **Stage 3:** text only; the detail page shows the phase-tinted hero with the
   main food's illustration.
2. **Stage 3b (optional):** a bake-off of three image providers on 20 recipes
   from our own prompts, judged on visual consistency with the existing 40
   photos, cost per image and licence terms. Pick one, then add an async image
   job, 4:3, resized to 1200 px / quality 84, with a content-safety check and a
   one-retry limit. Store provider and model per image.
3. Offer images as a tap ("Add a picture") rather than automatically, so the
   cost is only spent when wanted. Decide after seeing real usage.

I am deliberately not naming a specific image model: the field changes quickly
and the right pick comes from the bake-off.

## 5. Structured validation and dietary safety

The validator is deterministic code, shared in spirit with the content tests,
and **blocks** on:

- JSON schema, field lengths, 3–5 steps, minutes and serves in range.
- Every ingredient maps to a catalogue food or an allowed pantry line; the
  chosen protein, base and 2–3 plants all appear; no extra animal products
  beyond the selection and declared pantry.
- Quantity/unit sanity bounds.
- **Diet and allergens are computed from the linked foods** with the same
  `FoodFilter` logic the app uses, then compared to the user's filters. If a
  recipe conflicts with an allergen the user avoids, it is rejected, never
  "labelled". The model's own claims are ignored.
- Banned-claim scan (the existing content-test list).
- Food-safety rules: cooked-through wording and temperatures for poultry, pork,
  minced meat, eggs, shellfish, kidney beans; no raw instructions where
  cooking is required.

Advisory (stored in `validation_report`, not blocking): near-duplicate score,
coherence flags.

Dietary safety stance: the app already presents recipes as inspiration, not
medical advice. Generated recipes carry the same disclaimer, show "Good to
know" cautions from linked foods, and **never state a recipe is "safe" for an
allergy**, only that it avoids the foods the user listed.

## 6. Cost per user and at scale

Order-of-magnitude, to be re-checked against live pricing:

- **Text:** about 2–3k tokens in and out per recipe on a Haiku-class model:
  a fraction of a cent to roughly one cent, plus about the same again for the
  occasional repair retry.
- **Image (if added):** roughly 3–8 cents per image depending on provider and
  resolution; storage/bandwidth negligible.
- **Fixed:** Supabase about 25 USD/month, RevenueCat free at low volume then a
  small revenue share.

| Scenario | Text only | With image per recipe |
|---|---|---|
| Per recipe | < 1–2 ¢ | ≈ 5–10 ¢ |
| Per Premium user at a 20/month cap | < 0.40 USD | ≈ 1–2 USD |
| 1,000 active Premium users, average 8/month | ≈ 80–160 USD | ≈ 400–800 USD |

Controls: monthly cap per user, global daily budget with automatic shut-off,
cost recorded on every job (`tokens`, `cost`), alert at 70% and 100% of the
budget, and a feature-flag kill switch. Whether the cap and Premium price leave
margin is a business decision for you; text-only leaves a lot more room.

## 7. API security, rate limits, entitlements

- **Entitlement is read on the server** from the `entitlements` table (written
  by the purchase webhook), never from the JWT or the client `FeatureGate`. The
  development unlock and the launch promo stay client-side and **do not**
  authorise generation.
- **Quotas:** monthly per user (transactional counter), plus 5 requests/minute
  and 30/hour per user and per-IP limits; 10 KB request limit.
- **Abuse deterrents:** App Attest (iOS) / Play Integrity on generation
  requests, anonymous callers rejected.
- **Secrets:** provider keys only in function secrets; the app ships none.
  Separate keys per environment; keys restricted and spend-capped at the
  provider.
- **Observability:** structured logs without recipe text; Sentry for errors;
  a dashboard for jobs, failures, p95 latency and spend.
- **Kill switch:** a remote flag in `profiles`/config that disables generation
  without an app release.
- Privacy: only account id, food IDs, phase and (with explicit consent) diet
  and allergens leave the device; cycle dates never do. Consent screen before
  the first generation; policy and store labels updated before shipping.

## 8. Integration with the Flutter recipe detail page

Findings in the current code: `RecipeDetailPage(recipeId)` reads
`catalogue.recipe(recipeId)` and renders `AssetImage(recipe.imageAsset)`;
`Recipe` and `RecipeIngredient` already carry everything a generated recipe
needs (title, intro, minutes, serves, phase, ingredients with `foodId`, steps).

Plan:

- Add a `personalRecipesProvider` (from drift) and a single
  `recipeByIdProvider(id)` that looks in the bundled catalogue first, then in
  personal recipes. `RecipeDetailPage` switches to it; nothing else changes.
- Generated ids are namespaced (`u-<uuid>`) so they can never collide with
  bundled ids.
- Replace the hard-coded `AssetImage` with a small `RecipeImage` widget: bundled
  asset, then network image (later, Stage 3b), then the food-illustration
  fallback.
- Reuse existing ingredient→shopping-list and "Cook with…" logic unchanged,
  because ingredients link to catalogue food IDs.
- Meal builder: the disabled "Create my meal · Coming soon" button becomes the
  entry point: confirm consent, call the function, show a progress state, then
  open the detail page with a "Made by you" label and a short "Why this
  recipe?" derived from the selected foods, not model claims.

## 9. Automatic saving to the personal library

- The function writes the recipe and marks the job `succeeded` in **one
  transaction**; if the response is lost, the app finds it by idempotency key
  (or by listing recent recipes) instead of generating again.
- The app upserts the recipe into a drift table `personal_recipes`
  (schema v3, a migration needed only at implementation time and not before
  approval) so it opens offline, and shows a "My recipes" entry in Recipes.
- Stage 3 ships auto-save as **private to the owner**; delete and rename are
  included, publication is Stage 5.

## 10. Failure recovery and duplicate prevention

Job states: `queued → generating → validating → (repairing) → succeeded |
failed`.

- **Idempotency:** the app creates a UUID per tap of "Create"; `(user_id,
  idempotency_key)` is unique. A repeated request returns the existing job or
  recipe.
- **Content fingerprint:** hash of normalised `(phase, protein, base, sorted
  plants)`; if the user already has a recipe for the same selection, the app
  offers "Open your saved version" or "Make another version" (the latter counts
  against quota).
- **Quota is charged only on success**, in the same transaction as the recipe.
- **Timeouts and provider errors:** bounded retries with backoff inside the
  function; after that the job is `failed` with a readable reason and a Retry
  button reusing the same key.
- **Stuck jobs:** a scheduled sweeper marks jobs stuck for more than N minutes
  as `failed`.
- **App killed mid-request:** on next open, the app checks pending keys and
  reconciles.
- **Validation failure:** after the one repair attempt, the user sees a
  friendly message, no charge, and the failure is logged (without recipe text)
  to improve the prompt.

## What can be built and tested locally now (no credentials, no cost)

1. **Domain and validation core (Dart, shared logic mirrored in the function
   later):** generated-recipe schema, parser into `Recipe`, the validator
   (schema, ingredient resolution, allergens/diet derivation, banned claims,
   food-safety rules), fingerprinting and duplicate detection. Unit-tested with
   hand-written good and bad recipes.
2. **Client architecture with a fake backend:** `RecipeGenerationService`
   interface, an in-memory fake (deterministic recipes, simulated delay,
   failure, timeout and duplicate cases), the job state machine, idempotency
   keys, the consent and progress UI, the Create button, and
   `recipeByIdProvider`.
3. **Personal recipes drift table and "My recipes" UI** against the fake. (The
   schema v3 migration is created only after your approval of the model.)
4. **`RecipeImage` widget and detail-page integration** with the existing
   fallback, goldens and accessibility tests.
5. **Local backend skeleton** with the Supabase CLI and Docker: migrations,
   RLS, quota and idempotency functions, tested with SQL tests, using a
   **stubbed model** that returns canned JSON. This needs no account, but
   needs Docker installed.
6. Cost model spreadsheet and the 30-selection acceptance set (inputs only).

## What needs accounts, credentials or paid access

| Need | Why | Cost |
|---|---|---|
| Supabase project(s) staging/prod | Real hosting, auth, storage | Free tier for staging, ~25 USD/month prod |
| Apple Developer Program, Sign in with Apple key, App Attest | Auth and abuse protection on device | 99 USD/year (may already exist) |
| Anthropic API key (separate dev/staging/prod, spend caps) and DPA/zero-retention | Real generation and the acceptance run | Pay per use; a 30-recipe acceptance run is a few cents to dollars |
| RevenueCat + App Store Connect products (and Play) | Real purchases and server entitlements | Free at low volume, then revenue share |
| Image provider key (Stage 3b) | Bake-off and generation | Pay per image |
| Privacy policy, store labels, DPAs | Required before real users | Legal time |
| Sentry (exists), CI secrets | Observability and deploys | Existing |

## Proposed sequence (each step ends with tests and a review point)

1. **3.0 Decisions** (you): backend vendor, whether the launch promo includes
   generation, monthly cap and price, consent wording, text-only vs image at
   launch.
2. **3.1 Validator and schema** (local): generated-recipe model, parser,
   validation rules, fixtures; no network.
3. **3.2 Client flow on a fake service** (local): service interface, job state
   machine, consent and progress UI, Create button, detail-page integration,
   error and duplicate states; goldens and a11y tests.
4. **3.3 Personal library** (local, after approving the data model): drift v3,
   "My recipes", offline open, delete.
5. **3.4 Local backend skeleton** (local, Docker): SQL migrations in the repo
   (not applied to any hosted database), RLS, quota, idempotency, SQL tests.
   *Checkpoint: you approve the schema before anything is hosted.*
6. **3.5 Real accounts and entitlements** (needs Supabase, Apple, RevenueCat):
   sign-in, purchase, webhook, delete account, policy update.
7. **3.6 Real generation behind a flag** (needs Anthropic key): the
   30-selection acceptance run, cost per recipe measured, then internal
   testers.
8. **3.7 Images (optional)**: bake-off, then async job.
9. Stages 4 (sync polish) and 5 (publication) follow unchanged from the
   proposal.

Steps 3.1–3.4 can proceed now without credentials, spend or deployment.
Nothing starts without your approval of this document.
