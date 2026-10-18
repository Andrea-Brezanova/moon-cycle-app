# Feature status and development access

Updated for the Stage 1 branch (`feature/home-choices-food-detail`).

## What works today

| Area | Status |
|---|---|
| Onboarding, cycle calculation, phase estimates, reminders | Working |
| Settings: My Cycle, Food Preferences, Allergies, Notifications, Appearance, Privacy and data (export, delete), Help | Working |
| Home: phase hero, compact Your focus, Learn more, six-card Your choices | Working |
| Foods: featured library by phase, All foods search, Today's food (real phase, stable per day), food page for every food | Working |
| Recipes: 112 recipes (40 with photos), filters, detail, add to shopping list | Working |
| Shop: the free shopping list (basic) | Working, free |
| Try something new: Today's food plus two foods, each with an existing recipe | Working (option 2) |
| Build a meal page: guidance, protein and base ideas, a chosen starting food | Partly working (see below) |
| Entitlement architecture: tiers, feature gates, Subscription page | Working; no purchases |

## Partly built

- **Build a meal.** The page shows the three-step guidance and idea chips, and a
  food opened from a food page arrives already chosen in its slot (protein,
  base or plant) and can be removed. There is **no interactive selection** (one
  protein, one base, two or three plants, search, phase highlighting) and **no
  "Create my meal"**. Next stage.

## Not built yet (planned)

- **Log diary and "Add to logged meals".** Nothing exists: no logging tables,
  screens or tracking. Both show **Coming soon** and are disabled for every
  tier, so nothing pretends to work. The actual diary is designed and built
  separately. Intended as Premium.
- AI recipe generation, image generation, validation (Stage 3).
- Personal recipe library and shared-library publication (Stages 4 and 5).
- Accounts, purchases and server-side entitlement checks.
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

- `env/dev.json` sets `UNLOCK_ALL_FEATURES: true`, so
  `flutter run --flavor dev --dart-define-from-file=env/dev.json` starts with
  every feature unlocked and no lock icons.
- Settings (debug builds only) has an "All features unlocked (dev)" link to
  switch it off and see the production restrictions, no rebuild needed.
- It adds a debug-only grant on top of the real entitlements. It is **not** a
  subscription and changes nothing stored.
- It cannot exist in a shipped app: it needs `kDebugMode`, which is false in
  profile and release builds; `env/prod.json` and `prod.example.json` do not
  set it (a test checks this); and production server checks are not affected.
- Tests start with the real restrictions (they do not use `env/dev.json`).

To restore production behaviour for a build: do not pass `env/dev.json`; no code
changes are needed.
