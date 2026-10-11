# Moon Cycle: Editorial design handoff (v3)

The design package for building Moon Cycle in Flutter (repository `moon-cycle-app`). The Editorial direction (cream, plum and ochre) is the only UI source of truth; nothing from the earlier Sorbet direction is used.

**Version:** 3, 11 October 2026. **Scope:** v1.0, local-only (spec section 12). **App ID:** `app.mooncycle.mobile`.

## Read in this order
1. `Moon-Cycle-Editorial-Spec.md` (or `.pdf`): tokens, components, every screen and state, and the v1 scope.
2. `Moon-Cycle-Editorial-Screens.pdf`: every screen in light and dark, with notes.
3. `screens/`: the same screens as @2x PNGs at 390 pt wide. These are the visual reference for golden tests and the design overlay.
4. `code/theme.ts`: every token value (colours, hero wash per phase, orbit geometry, type scale, sizes). It is ported to Dart in milestone 3.
5. `code/cycle.ts`: the reference phase calculation. It is ported to Dart, with tests, in milestone 2.

## Folders
| Folder | Contents |
|---|---|
| `assets/fonts/` | Fraunces (7 static cuts), DM Sans (4), Gwendolyn Bold, with their OFL licences |
| `assets/logo/` | Outlined script wordmark and lockups (SVG and PNG), plus the Home header wordmark |
| `assets/mark/`, `assets/app-icon/` | Phase-ring mark and app icons (iOS light/dark, Android adaptive and monochrome, splash) |
| `assets/icons/` | 23 line icons, 24 × 24, `currentColor` |
| `assets/ui/` | Moon-hero reference SVGs for each phase, light and dark |
| `assets/shapes/` | Organic shapes, used on the onboarding welcome screen only |
| `assets/sample-images/` | Mock-up photos (not licensed for release) |
| `content/` | Ingredient-sheet copy and audit, recipe classification, sample content, **`recovered/emergent-recipes.json`** (all 12 recipes, recovered), the filled-in recipe CSVs and **`RECIPE-DATA-NEEDED.md`** (open flags and what's still missing) |

## Screen index (`screens/light-NN-*.png`, `screens/dark-NN-*.png`)
- **01–05:** onboarding.
- **06–10:** Home, Foods, Recipes, Shop, Settings. `10-settings` is the v1.1 target with the Account row; v1 uses `25`.
- **11–14:** ingredient sheet and Cook with… sheet, with their states.
- **15–18:** Recipes filter and empty states.
- **19–20:** recipe detail, before and after adding to the list.
- **21–24:** Home states (period late, log a period, preview, no recipes).
- **25–33:** Settings v1 and its sub-screens.
- **34–36:** Foods browsing another phase; Shop empty and Undo.
- **37:** the onboarding reveal in all four phases.
- **00-…:** design system, direction summary, and the Home hero in every phase.
