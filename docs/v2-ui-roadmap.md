# V2 UI roadmap

One coherent V2 design direction, implemented and merged in small pieces. Update
this file in every V2 PR: change the status, link the approved design, and move
finished items out of "Remaining".

**Status values:** `Not started` · `Design pending` (no approved reference yet) ·
`In review` (PR open) · `Done` (merged to `main`).

## Shared V2 direction (set by the approved Home)

- Deep-plum dark palette (not an inversion of light); ivory/sage/lavender/gold
  accents from the existing phase palettes.
- Fraunces for headings and numbers, DM Sans for body; italic last word in
  headings; botanical-green italic season labels.
- Soft rounded cards with a thin border, near-square image left, circular
  chevron right.
- Calm tone: no streaks, scores, completion requirements or guilt messages.
- Screen-only changes: no cycle maths, persistence, entitlement, schema or
  navigation changes inside a visual-only PR.
- Light and dark, 320 pt, large text, safe areas, 44 pt targets, decorative
  images hidden from screen readers.
- Real data only in production screens (no hardcoded sample content).

## Screens

| Screen | Route | Approved design | Status | Remaining changes |
| --- | --- | --- | --- | --- |
| **Home** | `/home` | Approved on device by the owner, Stage 1 (hero ring, Today's Focus, 3 a Day, Quick Access). Rendered references: `docs/v2-home-shots/`. The original reference images were supplied in chat and are not in the repo — add them under `docs/v2-designs/` if they should live here. | In review (`v2-ui-update`) | See "Home" below |
| Bottom tab bar | shell | Already matches the V2 reference (Home · Eat · Move · Relax · More, gold dot). | Done | None known |
| **Eat hub** | `/eat` | Approved reference (light + dark): Eat heading + search, photo, "Nourish your cycle" card, Foods / Recipes / Meal builder cards. Renders: `docs/v2-eat-shots/`. | In progress (`feature/v2-eat-ui`, awaiting device approval) | Approved hero photograph (a recipe photo stands in); golden re-record after approval |
| Foods page | `/eat/foods` | — (unchanged content, now under a back link to Eat) | Design pending | Restyle; decide whether to drop the duplicated 3 Plants a Day preview |
| Recipes page | `/eat/recipes` | — (unchanged content, now under a back link to Eat) | Design pending | Restyle |
| Food detail | `/eat/...` | — | Design pending | |
| 3 Plants a Day | `/eat/three-plants` | — | Design pending | Plant photography (see Assets) |
| Learn more (phase) | `/eat/learn` | — | Design pending | Home's Focus card links here |
| Meal Builder | `/eat/...` | — | Design pending | Home no longer has a "Create my meal" entry; decide whether Home or Eat owns it |
| My Recipes / recipe detail | `/eat/my-recipes` | — | Design pending | |
| Move | `/move` | — | Design pending | Currently a placeholder; target of Home's MOVE card |
| Relax | `/relax` | — | Design pending | Currently a placeholder; target of Home's RELAX card |
| More | `/more` | — | Design pending | |
| My Diary | `/more/diary` | — | Design pending | |
| Shopping List | `/more/shopping-list` | — | Design pending | |
| My Cycle / Food preferences / Allergies / Notifications / Subscription | `/more/...` | — | Design pending | |
| Credits | `/more/credits` | — | Design pending | |
| Onboarding (5 steps) | `/onboarding/...` | — | Design pending | Shares `MoonOrbit` with the old Home ring; decide whether it adopts `HomeRing` |

## Home

Implemented in Stage 1 (visual only).

Remaining before / after merge:

- **Assets:** photos for MOVE and RELAX (tiles say "photo to come"); a plant
  photo for EAT for most plants (only broccoli, avocado, blueberry have curated
  photos, otherwise an emoji tile); a final botanical illustration to replace
  the vector sprig; confirm credits/licences for any new image.
- **Polish:** ring proportions are slightly thicker/smaller than the reference;
  at 320 pt the Focus link's underline sits under the first line only when it wraps.
- **Behaviour (Stage 2, not started):** MOVE and RELAX currently open their
  existing tabs; real destinations/content to follow once designed.
- **Cleanup:** old Home widgets (`home_editorial.dart`, parts of
  `home_sections.dart`) are unused except `LatePeriodCard`; remove in a
  follow-up when safe.
- **Goldens:** the `premium` and `avoidances` Home goldens now look the same as
  `follicular` because the food sections they exercised left Home; keep or drop
  them in a later test cleanup.

## Assets still needed

| Asset | Used by | Status |
| --- | --- | --- |
| Eat hub hero photograph (colourful salad bowl) | Eat hub | Missing (uses `red-cabbage-apricot-chickpea-salad.jpg`, an existing recipe photo) |
| Movement photo(s) | Home MOVE card | Missing (placeholder tile) |
| Relaxation photo(s) | Home RELAX card | Missing (placeholder tile) |
| More curated plant photos | Home EAT card, 3 Plants a Day | Partial (3 of many) |
| Botanical illustration | Home Today's Focus | Placeholder (vector sprig) |

## Working agreement

- One branch/PR per screen (or tight group of screens), from latest `main`.
- Goldens are reviewed before they are regenerated, and regenerated on macOS 15
  to match CI.
- Nothing merges without the owner's approval.
