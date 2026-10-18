# Feature status and development access

Updated through Stage 7 on `feature/home-choices-food-detail`.

## What works today

| Area | Status |
|---|---|
| Onboarding, cycle calculation, phase estimates, reminders | Working |
| Settings: My Cycle, Food Preferences, Allergies, Notifications, Appearance, Privacy and data (export, delete), Help | Working |
| Home: phase hero, compact Your focus, Learn more, six-card Your choices | Working |
| Foods: featured library by phase, All foods search, Today's food, food page for every food | Working |
| Recipes: 112 recipes (40 with photos), filters, detail, add to shopping list, **My recipes** | Working |
| Shop: the free shopping list (basic) | Working, free |
| Build a meal: choose 1–8 foods (any category; current-phase foods first, "Show all foods" for the rest); **Create my meal** finds real recipes that use at least one, ranked by how many; no AI generation | Working (library; external API not activated) |
| Try something new: Today's food plus two foods, each with a recipe; with a generation service, three recipes that each use all three foods | Stage 1 experience working; three-recipe experience needs a generator (dev mock only) |
| Log diary: entries by day and meal, edit, delete, merged duplicates, daily history; Food Detail "Add to logged meals" and recipe "Add to my diary" | Working, local only, Premium (unlocked in development) |
| Suggest to Moon Cycle / review workflow | Backend and client code built and tested locally; no UI path in any build until accounts exist |
| Entitlement architecture: tiers, feature gates, Subscription page | Working; no purchases |

## What is a mock or local-only

- **Recipe generation.** `DevMockGenerationService` builds template recipes
  without an AI. It exists only in a debug build of the dev flavour, labels
  every recipe "Development sample", and cannot be created in release, profile
  or prod builds (those say "Creating a new recipe isn't available yet").
- **The backend** (`supabase/`) runs locally in Docker only. Nothing is hosted,
  no migration has been applied to a hosted database, and no provider key
  exists. The function's model is a local stub or "unavailable".
- **Images** for generated recipes use the tinted placeholder; no image provider
  is integrated.
- **External recipe API**: the interface exists; no provider is approved, so the
  source is empty.

## Not built yet (planned)

- Accounts (Sign in with Apple), purchases, the purchase webhook, server-side
  entitlements in production.
- A real AI provider (model, structured output, pricing and data-handling terms
  must be verified first) and an image provider.
- Editor review screens (the review workflow is SQL functions and an Edge
  Function; there is no reviewer app).
- Advanced shopping features (a future Premium idea; basic shopping stays free).
- Photos for the 72 newer recipes; real food illustrations.
- Track and More tabs (not part of the current five-tab navigation).

## Premium at launch (configuration, unchanged)

`defaultFeatureTiers` in `lib/features/entitlements/domain/entitlements.dart`:
Build a meal and Log diary are **Premium**; the shopping list, recipes and
foods are **free**. The launch promo grants Plus, which does not unlock
Premium. This table is the only thing that decides production access.

## Development access: everything unlocked

While the product is being built, all implemented features can be tested
without a subscription:

- A **debug build of the dev flavour** starts with every feature unlocked and
  no lock icons (`developmentUnlockEnabled`, set in `main()`). No build define
  or runtime setting is involved, so it cannot be missed by a stale build.
- Settings (debug builds only) has an "All features unlocked (dev)" link to
  switch it off and see the production restrictions, no rebuild needed.
- It adds a debug-only grant on top of the real entitlements. It is **not** a
  subscription and changes nothing stored.
- It cannot exist in a shipped app: it needs `kDebugMode` (false in
  profile and release builds) and the dev flavour (never prod), and production server checks are not affected.
- Tests start with the real restrictions (the start switch defaults to off).

To restore production behaviour for a build: build a release/profile build or the prod flavour; no code
changes are needed.
