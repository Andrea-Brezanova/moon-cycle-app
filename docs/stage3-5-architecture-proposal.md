# Stages 3–5 architecture proposal (draft for owner approval)

> **Status: proposal only.** Nothing here is implemented. It covers AI recipe
> generation (Stage 3), the personal recipe library (Stage 4) and the shared
> library with publication (Stage 5). Prices and vendor limits below are
> assumptions to verify at decision time.

## 1. Starting point and constraints

- Moon Cycle v1 is **local-first**: cycle data, preferences and the shopping
  list live in an encrypted on-device database. There is no account, no server
  and no network code, and the app tells users everything stays on their phone.
- Entitlements are already modelled (`Tier`, `Feature`, `FeatureGate`,
  `EntitlementOrigin.serverGrant` / `purchase`) but only a launch-promo grant
  exists. Server grants and purchases were designed to plug in later.
- Content (foods, phases, 112 recipes, 40 photos) is bundled and read-only.
- Anything in Stages 3–5 therefore adds, for the first time: **accounts, a
  backend, a vendor that processes user input, and stored user-generated
  content.** That changes the privacy promise and needs a policy update.

## 2. Recommended architecture

```
Flutter app ──HTTPS (JWT)──► API edge (serverless functions)
                               ├─ Auth (accounts, sessions)
                               ├─ Entitlement check (server truth)
                               ├─ Rate limit + idempotency
                               ├─ Recipe generator (LLM, JSON-schema output)
                               ├─ Validator (deterministic + rule checks)
                               ├─ Image job (async worker) ─► image model
                               └─ Postgres (+ row-level security) + object storage
Admin/review tool (internal) ─► shared_recipes / publication pipeline
```

**Backend choice (pick one; recommendation first)**

| Option | Pros | Cons |
|---|---|---|
| **Supabase** (Postgres, Auth, Edge Functions, Storage, RLS), EU region | One vendor, RLS fits private-by-default, EU hosting, cheap start | Edge-function limits for long jobs (use a queue/worker for images) |
| Firebase | Mature mobile SDKs | NoSQL fits the relational recipe model poorly; US-centric defaults |
| Custom (e.g. serverless + Neon Postgres + S3) | Full control | Most to build and operate |

## 3. Authentication

- Sign in with **Apple** (required by App Store rules if any other social login
  is offered), plus email magic link. Add Google only if Android needs it.
- Accounts are **optional and only needed for Premium/generation**; the free
  app keeps working with no account (preserves the local-first promise).
- The server issues short-lived JWTs; the app stores the refresh token in
  `flutter_secure_storage` (already a dependency).
- "Delete my data" must also delete the account and server rows (see §8).

## 4. Premium verification

- Purchases via StoreKit 2 / Play Billing, brokered by **RevenueCat** (or
  direct App Store Server Notifications V2 + Play RTDN).
- A webhook writes `entitlements(user_id, tier, source, valid_until)`.
- Every generation request checks the entitlement **on the server**; the JWT
  carries identity only, never the tier. The client `FeatureGate` is just for
  presentation and is fed by a new `purchase` / `serverGrant` source in
  `entitlementGrantsProvider` (the seam already exists).
- The launch-promo grant stays client-side and does **not** authorise server
  generation (otherwise free users could call the API). Decision needed: does
  the promo include generation? If yes, the server needs its own promo grant.

## 5. Recipe generation (Stage 3)

Request: `{ idempotency_key, phase, protein_id, base_id, plant_ids[2–3] }`.
Only **food IDs** are sent. No free text, no cycle dates.

1. Verify JWT, entitlement, per-user quota and idempotency key (same key →
   same job, no duplicate generation or rows).
2. Re-resolve every ID against the server copy of the catalogue (same food
   library as the app) and reject unknown or `shipReady: false` IDs.
3. Re-apply the user's diet and allergen filters server-side if the user opted
   to send them (see §8); otherwise the app filters the options before sending.
4. LLM call with a strict JSON schema: title, intro, ingredients (each linked
   to a food ID or an allowed pantry aisle, with amount and unit), 3–5 steps,
   minutes, serves. Temperature low; the prompt is built server-side from IDs.
5. **Validate** (see §6). One automatic repair retry, then fail cleanly.
6. Persist the recipe as `private`, then enqueue the image job.
7. Return the recipe immediately with a fallback image; the real image arrives
   asynchronously (the app already renders a no-photo fallback).

Failure handling: provider timeout → job `failed` with retry button; the
idempotency key makes retries safe; the user is never charged a quota unit for
a failed job.

## 6. Recipe validation

Deterministic (blocking):

- Schema, field lengths, 3–5 steps, minutes and serves in range.
- Every ingredient resolves to a catalogue food or an allowed pantry line.
- The selected protein, base and plants all appear.
- Quantities within per-unit sane bounds; no unit mixing errors.
- **Allergens and diet are derived from the linked foods** (as the app does
  today), never taken from the model's claims.
- Banned-claim scan (hormone, fertility, detox, treatment, cure, symptom,
  "boost"), the same list the content tests use.
- Food-safety rules: required cooking verbs and minimum-temperature wording for
  poultry, pork, minced meat, eggs, shellfish and kidney beans; no raw-only
  instructions for foods that must be cooked.

Advisory (flags for review, not blocking): a second model pass for coherence,
duplicate and near-duplicate detection (normalised ingredient set + title
similarity), nutritional-claim accuracy.

## 7. Image generation

- Async worker calls an image model with a style prompt consistent with the
  existing recipe photos (the research repo already holds image prompts and a
  manifest). Output is checked for size, aspect ratio (4:3) and a content
  safety filter, resized to the app's 1200 px / quality 84 convention, and
  stored in object storage behind a signed URL or CDN path.
- Failure or rejection → keep the fallback; allow one retry.
- **Rights:** generated images are owned/licensed per the provider's terms;
  record the provider and model per image. Images of user-generated recipes
  are not reused publicly until the publication review (§9).

## 8. Privacy and compliance

- **What leaves the device:** account identity, selected food IDs, phase name,
  and optionally diet/allergens. Cycle dates and logs never leave the device.
- Allergens and diet are health-adjacent: treat as special-category data under
  GDPR → explicit consent screen before first generation, with the option to
  generate without sending them (the app filters the choices instead).
- Vendor DPAs with the LLM and image providers; no-training and minimal
  retention settings; EU processing where available.
- Privacy policy, App Store privacy labels and in-app "Privacy & Data" copy
  must be updated **before** shipping; the "everything stays on your phone"
  wording is no longer true for accounts that use generation.
- Deletion: "Delete my data" removes local data and calls a server delete
  (account, recipes, images, jobs, usage). Export includes personal recipes.
- Logs redact IDs where possible; no recipe text in error reports.

## 9. Personal vs shared library (Stages 4–5)

Lifecycle: `generated → private → candidate → validated → approved → published`.

- **Private (Stage 4):** every successful generation is saved automatically to
  the owner's library, owner-only via row-level security, with the original
  selected food IDs and provenance. A local drift copy (read cache) keeps
  recipes available offline.
- **Shared (Stage 5):** a user cannot publish. A recipe becomes a *candidate*
  only through an opt-in "Suggest to Moon Cycle" action or an editorial pick.
  Candidates are reviewed in an **internal review tool**: automated validation
  report, duplicate check, image review, claim review, then an explicit
  approval by an editor. Approval creates a **sanitised copy** in
  `shared_recipes` (no user id, notes or provenance beyond a source flag); the
  private original is untouched.
- Distribution of approved shared recipes: either fold them into the bundled
  catalogue through the existing research pipeline (ships with app releases;
  no new runtime infra) or serve them from a read-only remote catalogue. The
  first is recommended initially.

## 10. Data model (proposed, not created)

Server (Postgres):

| Table | Key fields |
|---|---|
| `profiles` | `user_id`, created_at, consent flags, region |
| `entitlements` | `user_id`, tier, source, valid_until, updated_at |
| `usage_counters` | `user_id`, period, generations_used |
| `generation_jobs` | `id`, `user_id`, idempotency_key (unique per user), phase, selected food ids, status, error, model, tokens, cost, timestamps |
| `generated_recipes` | `id`, `user_id`, job_id, title, intro, ingredients (jsonb), steps, minutes, serves, phase, status (`private/candidate/...`), validation_report, derived diet/allergens, created_at |
| `recipe_images` | `recipe_id`, storage path, provider, model, status |
| `publication_reviews` | `recipe_id`, reviewer, checklist, decision, notes, decided_at |
| `shared_recipes` | sanitised content, source_recipe_id (internal only), published_at |

Device (drift, a later migration): `personal_recipes` (cache of the owner's
server rows, with an `updated_at` for sync). No migration is created until you
approve this model.

## 11. Security

- Secrets only in server environment; the app holds none.
- RLS on every user table; the service role is used only inside functions.
- Per-user and per-IP rate limits; daily and monthly generation caps; request
  size limits; idempotency keys.
- Prompt-injection surface is minimal because input is IDs only; any future
  free-text field must be moderated.
- App Attest / Play Integrity on generation calls to deter scripted abuse.
- Dependency and secret scanning in CI; backups with tested restore; audit log
  for reviewer decisions; least-privilege roles for the review tool.

## 12. Costs (order of magnitude; verify prices)

Per generated recipe ≈ one text call (~2–3k tokens in and out) + one image.
Illustrative range: text a few cents or less, image roughly 3–8 cents depending
on model, storage and bandwidth negligible. So **~5–12 cents per recipe**.
Fixed: backend ~25 USD/month at start, RevenueCat free at low volume, then a
small revenue share; Sentry already in use. A monthly cap (e.g. 20–30 recipes
per Premium user) bounds worst-case cost per user to a few dollars. A cost
dashboard per job (`tokens`, `cost`) is part of the design.

## 13. Phased rollout and decisions needed

1. Accounts + entitlements + backend skeleton (no AI): sign-in, purchase,
   server-side tier, delete-account, policy update.
2. Generation behind a feature flag for internal testers; validation suite and
   golden recipes as acceptance tests.
3. Image pipeline.
4. Private library + sync.
5. Review tool + publication.

Owner decisions: backend vendor; whether the launch promo includes generation;
quota and pricing; AI/image providers and EU processing; consent wording;
whether suggestions to the shared library are user-initiated or editorial only;
how shared recipes reach the app (bundled vs remote).
