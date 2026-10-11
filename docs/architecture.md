# Architecture

Moon Cycle is a local-first Flutter app (v1 has no backend). This page is the map: where code goes and which way dependencies point. The full reasoning is in `technical-plan.md`.

## Folder map
```
lib/
  main.dart            entry point: resolves AppConfig, starts ProviderScope
  app/
    app.dart           root widget (MaterialApp)
    config/            AppConfig: flavour and build-time settings
    router/            go_router setup                         (Milestone 4)
    shell/             five-tab shell and tab bar              (Milestone 4)
  core/                shared by every feature
    domain/            Phase, LocalDate: pure Dart             ✓ Milestone 2
    design/            Editorial tokens, theme, shared widgets ✓ Milestone 3
    database/          Drift database and tables, encrypted    (Milestone 5)
    time/              "today" provider, midnight refresh      (Milestone 7)
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
| App content (foods, recipes, phase copy) | `content/` → bundled into `assets/content/` (Milestone 6) |

## Design system (`lib/core/design/`)
- `moon_theme.dart` builds the light and dark `ThemeData`; widgets read the Editorial colours with `context.moon` and never use raw hex values.
- `tokens/` holds colours (with a palette per phase), type (`fraunces()` picks the 72 pt or 24 pt cut by size), spacing, radii, sizes, and the hero and orbit values.
- `widgets/` holds the shared components: buttons, text link, phase selector, chips and pills, checkbox, toggle, list rows, sub-screen header, stepper, month calendar, bottom sheet, Undo toast, empty state, info note, text field, recipe photo, brand marks, the hero background and the moon orbit. They know nothing about features: the moon takes a `MoonOrbitSpec`, which Home builds from the cycle state.
- `debug/component_gallery.dart` shows every component in both themes. It is reachable only in debug builds.

## Flavours
`dev` and `prod` only in v1 (see `decisions.md`). The flavour is set by `--flavor`; per-environment values come from `env/<flavour>.json`. `AppConfig` refuses to start if they don't match.
