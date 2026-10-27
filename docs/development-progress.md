# Development progress

One report, kept current. **Stage** means exactly one of: 1 Mockup, 2 Documentation,
3 Unmerged Flutter code, 4 Merged into `main`, 5 Installed on the iPhone. Bugs carry a
second, separate status: **Implemented, awaiting device verification** (passes automated
tests, not yet checked by a person on the phone) or **Verified on device**. Nothing below is
"Verified on device" yet.

Last updated: 27 Oct 2026. `main` at the time of writing: d0d6f74 (PR #51), plus docs-only
PR #52 and this report. **Installed on the iPhone: d0d6f74**, built 2026-10-27 02:48 UTC with
`tool/build_ios.sh` and installed in place (data kept); Me › My App › About shows it. The
phone screen was not inspected by me.

## Bugs and corrections (second brief, 26–27 Oct)

| Bug | Failing test before the fix | Fix | Regression tests | PR / merge commit | Installed | Device verification |
|---|---|---|---|---|---|---|
| **Cook with disappears when the ingredient is cleared (All phases)** | Yes, run on unfixed code: "Found 0 widgets with a semantics label named 'Cook with, choose an ingredient'" | Field always shown; in All phases the sheet lists every food that has a recipe; Change works there | choose / clear / choose repeatedly, Change, meal type kept, empty result recovers, sheet content, phase browse unchanged | #46 `e3d9d3d` | Yes (in d0d6f74) | **Awaiting** |
| **3 Plants a Day ignores the day the cycle wheel is on** | Yes, run on unfixed code: same trio `bok-choy, oat-bran, napa-cabbage` after moving the wheel | Plants follow the wheel's day (preview only; reads the wheel, writes nothing) | same day = same plants, phase boundary swaps pool, return to a day, restart, irregular/late cycles, exclusions, no stored-data change, picks reset | #48 `4afe667` | Yes | **Awaiting** |
| **Collection tiles uneven; counts and status text on them** | Not run on old code (layout change); the new tests assert equal size, equal title position and no count text, which the previous layout could not satisfy | One shared tile: fixed-proportion picture, fixed-height title area, titles only | equal size and title offset, no "N saved / Nothing yet / Not available yet", 320 pt and large text | #45 `90655f0` | Yes | **Awaiting** |
| **Home shortcuts show counts / "Nothing logged yet"; "Why these foods" in phase info** | Old tests asserted the text was present; they now assert it is absent | Headlines only; section and its copy removed | shortcuts show titles only; Learn more has no WHY THESE FOODS | #47 `f1a88ac` | Yes | **Awaiting** |

Not bugs but changes asked for: Me restructure (#44 `274bc85`), hub consistency (#49
`2912a0d`), My Routines storage (#42 `5b133f4`) and screens (#51 `d0d6f74`). All are
"merged and installed; device verification awaiting".

## What changed (all merged and installed in d0d6f74)

| Feature | PR | Stage | Notes |
|---|---|---|---|
| Me: four destinations (My Collections, My Diary, My Shopping List, My App) as hub cards; person icon on the tab | #44 | 5 | My App holds Personalization (My Cycle, Food Preferences, Allergies / dietary exclusions), App preferences, Account, Support (Help, Credits & Sources, About). **Delete my data** is the discreet last row of My App and only opens the existing confirmation page. |
| My Collections: four equal tiles, titles only | #45 | 5 | |
| My Routines (schema v10 + screens) | #42, #51 | 5 | Create, rename, add your own steps or saved links, reorder, remove, delete with confirmation. Included in Export; removed by Delete my data. Migration tested (v9→v10, v8→v10, foreign keys). Real drag-to-reorder is a hand check. |
| Eat, Move, Relax look alike: shared hero card and hub cards; icon colours follow the viewed phase | #49 | 5 | Move and Relax heroes use images already in the app as stand-ins; request in `docs/hero-image-requests.md`. |
| Build Your Workout (Move) | #49 | 5 | Choose exercises (reviewed library, empty for now, or add your own), reorder, remove. **Save to My Workouts is NOT available** (see approvals). Separate from My Routines. |
| Move and Relax hubs, libraries, item pages (infrastructure) | #41 | 5 | No approved content yet: libraries are empty by design. |
| Cook with, 3 Plants wheel, Home headlines, Why these foods removal | #46, #48, #47 | 5 | see bugs table |
| Meal Builder free, five approved Food Detail profiles, About build info | #35, #36, #34 | 5 | unchanged |

## Content and research (not published)

| Item | Status |
|---|---|
| Food Detail profiles | The 5 approved profiles are unchanged. **24 more are drafted** (batch 1 #50 `f6bb78e` merged; batch 2 #52 open): composition from USDA FoodData Central recomputed by script and test, none publishable, none in the app. 113 of the 137 remain queued (`docs/food-profiles/work-queue.json`). Review notes: `batch-1-review.md`, `batch-2-review.md`. **Researched/drafted is not implemented.** |
| Move and Relax content | 13 original draft items in `docs/content-drafts/` (not bundled) with a review package; need professional/editorial review. The app shows nothing until an item is approved. |
| Sounds | Concepts only. **Blocked**: no audio with confirmed rights, and no audio plugin yet. |
| Food photography | **Blocked, not started**: no authorised image generation or licensed source in this environment. The manifest (`docs/food-photo-manifest.json`, 161 foods in batches of 12) and integration steps exist; no image was produced or added. |

## Needs your approval or input

1. **Build Your Workout: saving to My Workouts.** A built workout needs storage. Smallest
   option: add a `kind` column (`routine` | `workout`) to the approved `routines` table (one
   additive migration, schema v11). Alternative: separate workout tables. Not done; not
   covered by the v10 approval.
2. Review/approval of the Move and Relax drafts and of food-profile drafts (batches 1 and 2).
3. Hero photographs for Move, Relax and Eat; food photographs (all 271 foods have 3).
4. Audio with confirmed rights if you want Sounds.

## PRs

Open: #52 (docs, batch 2 profile drafts; merging), #16 (stale; its unique TestFlight
checklist is kept in `docs/release-readiness.md` by this report's PR, so it can be closed
after this merges). Closed as superseded or redundant, branches kept: #25, #33, #38.

## Not implemented (do not expect on the phone)

Any food photograph beyond the original 3; any Move or Relax library content; Sounds; saving a
built workout; profiles for foods other than the five approved.
