# Architecture

Moon Cycle is a local-first Flutter app (v1 has no backend). This page is the map: where code goes and which way dependencies point. The full reasoning is in `technical-plan.md`.

## Folder map
```
lib/
  main.dart            entry point: resolves AppConfig, starts ProviderScope
  app/
    app.dart           root widget (MaterialApp)
    config/            AppConfig: flavour and build-time settings
    router/            go_router setup and route names         ✓ Milestone 4
    shell/             five-tab shell and tab bar              ✓ Milestone 4
    placeholders/      stand-in pages until each screen is built (removed screen by screen)
  core/                shared by every feature
    domain/            Phase, LocalDate: pure Dart             ✓ Milestone 2
    design/            Editorial tokens, theme, shared widgets ✓ Milestone 3
    database/          Drift database and tables, encrypted    ✓ Milestone 5
    time/              "today" provider, midnight refresh      ✓ Milestone 7
    format/            English date wording                    ✓ Milestone 7
  features/<feature>/  cycle, onboarding, home, foods, recipes, shopping, settings, …
    domain/            entities and rules: pure Dart
    data/              repositories (Drift today, Supabase later)
    application/       Riverpod providers and notifiers
    presentation/      pages and widgets
```
A feature only gets the folders it needs; no empty folders.

## How a screen gets its data
```
page (presentation) → provider (application) → repository (data) → Drift
         ↑ rebuilds when the provider's value changes
```
- **Riverpod** connects the layers. Repositories are exposed as providers, so tests swap them for fakes with `ProviderScope(overrides: …)`.
- **Drift** is the only place data is stored. The UI never talks to Drift directly.
- **go_router** owns navigation: the onboarding redirect, five tabs that each keep their own stack, recipe detail inside Recipes, and Settings sub-pages. Bottom sheets aren't routes.

## Recipes (`lib/features/recipes/`) ✓ Milestone 11
- `application/`: `recipe_filter.dart` (meal type, ingredient), `recipe_list.dart` (what the list shows and what its empty states need).
- `presentation/`: `RecipesPage`, `RecipeDetailPage`, `cook_with_sheet.dart`, `recipe_copy.dart` (count line, empty states), `widgets/recipe_widgets.dart` (meal tabs, Cook with field, feature and grid cards).

## Foods (`lib/features/foods/`) ✓ Milestone 10
- `FoodsPage` (with `PhaseHeader` from `features/cycle/presentation`), `FoodRow`, and the ingredient sheet (`showIngredientSheet`), which Home's chips open too.
- `food_providers.dart`: `recipeCountsProvider(phase)`.
- `features/recipes/application/recipe_filter.dart`: the meal-type and "Cook with…" filter, shared by the sheet and Recipes.

## Shopping (`lib/features/shopping/`) ✓ Milestones 9 and 12
- `domain/`: `ShoppingItem` and `ShoppingSource`, `item_key.dart` (keys, typed text), `shopping_merger.dart` (`addToList`), `quantity.dart` (`displayQuantity`), `shopping_list.dart` (aisle grouping, Done).
- `data/shopping_repository.dart`: live items with sources (one watched join), add/addAll in transactions, done, remove, clear and restore.
- `application/`: `shoppingItemsProvider`, `shoppingSummaryProvider` (Home's block, "on your list" marks), `ShoppingController` (every change; its state is the Undo offer).
- `presentation/`: `ShopPage`, `ShopRow`.

## Home (`lib/features/home/`) ✓ Milestone 8
- `HomePage` reads `cycleStateProvider`, the catalogue and the food filter; `HomeHero` draws the hero, the drag preview and the late meta line; `home_sections.dart` holds focus, foods, recipes, the shopping block and the late card.
- `home_providers.dart`: `homePreviewProvider`, `foodsForTodayProvider(phase)`, `recipesForTodayProvider(phase)`.
- Shared cycle pieces live in `features/cycle`: `viewingPhaseProvider`, `checkPeriodStart`, the Log a period sheet.

## Onboarding (`lib/features/onboarding/`) ✓ Milestone 7
- Five routes under `/onboarding`; `OnboardingController` holds `OnboardingAnswers` in memory; `OnboardingRepository.save` writes everything in one transaction after step 4; `OnboardingStatus` opens the gate on "See my foods".
- The reveal reads `cycleStateProvider` (`features/cycle/application`) and draws the moon with `orbitSpecFor` (`features/cycle/presentation`), which Home reuses.

## Content catalogue (`lib/features/content/`) ✓ Milestone 6
- `assets/content/*.json` → `parseCatalogue` (data) → `Catalogue` (domain, read-only): phases with their foods per category in the stored order, foods, recipes, aisles, allergens. Not-ship-ready foods are dropped on load.
- `FoodFilter` (domain) applies the diet and avoidances; `foodFilterProvider` builds it from the stored preferences. Screens ask the filter, never the diet directly.
- `catalogueProvider` is set in `main()`; tests use `testCatalogue` (the real files, read from disk).

## Local database (`lib/core/database/`) ✓ Milestone 5
- **One encrypted SQLite file**, `moon_cycle.db` in Application Support. `package:sqlite3` bundles SQLite3MultipleCiphers (set under `hooks:` in `pubspec.yaml`); the opener refuses to run on a SQLite build without encryption.
- **The key** is 32 random bytes in the iOS Keychain / Android Keystore (`EncryptionKeyStore`). No file yet means a new key, which also replaces a key a previous install left in the Keychain. A file the stored key can't open is moved aside (`.unreadable-…`) and a fresh database starts.
- **Opened before the first frame** in `main()`; the onboarding gate's first value comes from the database.
- **Tables** (`tables.dart`) follow plan §8.3. User tables have a client id, `created_at`, `updated_at` and a `deleted_at` tombstone, ready for sync. Dates are `YYYY-MM-DD` text; timestamps ISO-8601 text.
- **Repositories** are plain classes over `AppDatabase` in each feature's `data/` folder (`CycleRepository`, `PreferencesRepository`, `AppStateRepository`), each with a provider. Tests run them on an in-memory database; `RowStamp` lets tests fix ids and the clock.
- **Migrations:** `schemaVersion` plus `drift_schemas/` snapshots (see README).
- **No backups:** Android backup and device transfer are off (the Keystore key can't move, so a copy would be unreadable).

## Navigation (`lib/app/router/`, `lib/app/shell/`) ✓ Milestone 4
- **Routes:** `/onboarding`; the tabs `/home`, `/foods`, `/recipes`, `/shop`, `/settings`; `/recipes/:recipeId`; `/settings/<page>` (`SettingsPage` in `routes.dart`). Unknown paths go to Home.
- **Tabs:** a `StatefulShellRoute.indexedStack`. Each tab keeps its own stack and scroll position; switching tabs is instant. Tapping the active tab returns to its first screen, or scrolls to the top if it's already there.
- **Pushed pages** use the platform transition (iOS slide with swipe-back). Every route builds a `MaterialPage` explicitly: go_router 18 looks for the `material_ui` package's `MaterialApp`, which this app doesn't use, and would otherwise use pages without platform transitions.
- **Tab bar or not:** pages inside a tab keep the tab bar. "Delete my data" covers it (spec), so it opens on the root navigator. Onboarding and the debug gallery are outside the shell.
- **Android back:** inside a tab, one screen back; on the first screen of Foods, Recipes, Shop or Settings, to Home; on Home, the app closes. (`PopScope` in `MainShell`.)
- **Onboarding gate:** the router's redirect reads `onboardingCompletedProvider`, which starts from the stored state (`app_states.onboarding_completed_at`).
- **Debug gallery** (`/debug/gallery`) is added only when `kDebugMode`, a compile-time constant, so release and profile builds contain neither the route nor the gallery code.

## Dependency rules
1. `domain/` is pure Dart: no Flutter, Riverpod, Drift or Supabase imports. `tool/check_layers.dart` enforces this in CI.
2. `presentation → application → domain ← data`. A feature may use another feature's `domain` and `application`, never its `presentation`.
3. Shared visual components live in `core/design/` and know nothing about features.
4. Domain code never reads the clock: "today" is always passed in as a `LocalDate`, so cycle calculations are testable. `tool/check_layers.dart` rejects `DateTime.now(` in `domain/`.

## Cycle domain (`lib/features/cycle/domain/`)
- `calculateCycleState(lastPeriodStart, lengths, today)` returns a `CycleState`: cycle day, phase, phase day, next phase, the estimated next period, and late and long-gap flags.
- `phaseRangesFor(lengths)` is an exact port of `design/code/cycle.ts`, proven against it for all 1,575 valid inputs (`test/fixtures/`).
- `CycleLengths` is the only input the calculator needs about lengths. Today it comes from `CycleLengths.fromProfile`; period-history averages will add a second source later without changing the calculator.
- Phases and dates are **estimates**. UI copy must not present them, estimated ovulation in particular, as confirmed biological events.

## Where things live
| What | Where |
|---|---|
| Visual source of truth (spec, screen PNGs, reference values) | `design/`: read-only, never edited |
| Design tokens in Dart (colours, type, spacing, hero and orbit values) | `lib/core/design/tokens/` ✓ Milestone 3 |
| Fonts, wordmark, lockups, phase-ring mark | `assets/fonts/`, `assets/logo/`, `assets/mark/` ✓ Milestone 3, copied from `design/assets/` |
| Line icons | `lib/core/design/icons/moon_icon_paths.dart`: the paths of `design/assets/icons/*.svg`, embedded so each use can set its stroke width |
| Places where the app differs from the design | `docs/design-deviations.md` |
| Cycle calculation | `lib/features/cycle/domain/` ✓ Milestone 2, ported from `design/code/cycle.ts` |
| App content (foods, recipes, phase copy) | `assets/content/` ✓ Milestone 6 (source and asset in one; see its README) |

## Design system (`lib/core/design/`)
- `moon_theme.dart` builds the light and dark `ThemeData`; widgets read the Editorial colours with `context.moon` and never use raw hex values.
- `tokens/` holds colours (with a palette per phase), type (`fraunces()` picks the 72 pt or 24 pt cut by size), spacing, radii, sizes, and the hero and orbit values.
- `Pressable` is the one tap target: dims while pressed, and is its own screen-reader node. `semanticLabel` replaces what the content would read (for example "Back to Settings") while keeping the button role and tap action.
- `widgets/` holds the shared components: buttons, text link, phase selector, chips and pills, checkbox, toggle, list rows, sub-screen header, stepper, month calendar, bottom sheet, Undo toast, empty state, info note, text field, recipe photo, brand marks, the hero background and the moon orbit. They know nothing about features: the moon takes a `MoonOrbitSpec`, which Home builds from the cycle state.
- `debug/component_gallery.dart` shows every component in both themes. It is reachable only in debug builds (see Navigation).

## Flavours
`dev` and `prod` only in v1 (see `decisions.md`). The flavour is set by `--flavor`; per-environment values come from `env/<flavour>.json`. `AppConfig` refuses to start if they don't match.
