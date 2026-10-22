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
| **Home** | `/home` | Approved on device by the owner, Stage 1 (hero ring, Today's Focus, 3 a Day, Quick Access). Rendered references: `docs/v2-home-shots/`. The original reference images were supplied in chat and are not in the repo — add them under `docs/v2-designs/` if they should live here. | Done (PR #2 merged) | See "Home" below |
| Bottom tab bar | shell | Already matches the V2 reference (Home · Eat · Move · Relax · More, gold dot). | Done | None known |
| **Eat hub** | `/eat` | Approved reference (light + dark): Eat heading + search, photo, "Nourish your cycle" card, Foods / Recipes / Meal builder cards. Renders: `docs/v2-eat-shots/`. | In review (`feature/v2-eat-ui`; approved on device) | Approved hero photograph (a recipe photo stands in); hero photo still a stand-in |
| Foods page | `/eat/foods` | Approved (light, dark, category-filtered), supplied in chat | Planned — Feature 1 (`feature/v2-foods-ui`) | See Feature 1 |
| Recipes page, Cook with | `/eat/recipes` | Approved (light, dark, Cook with ingredient), supplied in chat | Planned — Feature 2 (`feature/v2-recipes-ui`) | See Feature 2 |
| Food detail | `/eat/...` | — | Design pending | |
| 3 Plants a Day | `/eat/three-plants` | — | Design pending | Plant photography (see Assets) |
| Learn more (phase) | `/eat/learn` | — | Design pending | Home's Focus card links here |
| Meal Builder | `/eat/...` | — | Design pending | Home no longer has a "Create my meal" entry; decide whether Home or Eat owns it |
| My Recipes, Add a Recipe | `/eat/my-recipes` | Approved (My Recipes, Add a Recipe: paste a link / paste text / write my own), supplied in chat | Planned — Feature 2 | Audit which import flows really exist first |
| Recipe detail | `/eat/recipe/:id` | — | Design pending | |
| Move | `/move` | — | Design pending | Currently a placeholder; target of Home's MOVE card |
| Relax | `/relax` | — | Design pending | Currently a placeholder; target of Home's RELAX card |
| More | `/more` | — | Design pending | |
| My Diary hub | `/more/diary` | Approved (light, dark): Today hero + five cards, supplied in chat | Planned — Feature 3 (`feature/v2-diary-hub`) | See Feature 3 |
| Shopping List | `/more/shopping-list` | — | Design pending | |
| My Cycle / Food preferences / Allergies / Notifications / Subscription | `/more/...` | — | Design pending | |
| Credits | `/more/credits` | — | Design pending | |
| Onboarding (5 steps) | `/onboarding/...` | — | Design pending | Shares `MoonOrbit` with the old Home ring; decide whether it adopts `HomeRing` |

## Delivery sequence (permanent workflow)

One branch and one feature at a time. The next branch starts only after the
previous PR is merged and the owner says to continue. For each feature: fetch
`origin/main`, branch from it, implement only that feature, run targeted tests
and analysis, give light/dark screenshots, stop for approval on device, then
re-record only the affected goldens (reviewing the diffs), run full CI including
Android, and open the PR. The owner reviews and merges. No force-push, reset,
rebase or deploy.

| # | Feature | Branch | Status |
| --- | --- | --- | --- |
| 0 | Eat hub | `feature/v2-eat-ui` | Approved on device; goldens re-recorded; PR open for review |
| 1 | Foods UI | `feature/v2-foods-ui` | Not started (waits for Eat merge) |
| 2 | Recipes UI (listing, Cook with, My Recipes, Add a Recipe) | `feature/v2-recipes-ui` | Not started |
| 3 | My Diary hub | `feature/v2-diary-hub` | Not started |
| 4 | Free-writing diary Notes (new functionality; needs a design + data-model proposal first) | `feature/v2-diary-notes` | Not started |
| 5 | Activity logging (new functionality; needs a model/storage proposal first) | `feature/v2-activity-log` | Not started |

Key requirements per feature (full text was given in chat):

- **Foods:** centred title, back, search; phase selector with dot; wrapping
  canonical category chips; Today's Food card; All Foods list with thumbnails and
  Shopping List add/remove. Remove the duplicated 3 Plants a Day preview from
  Foods only (not its own screen, not Home's shortcut). When a category is
  selected: highlight chip, category heading and count, hide the featured card.
  No food, nutrient or allergen data changes.
- **Recipes:** All / Breakfast / Meals / Snacks (Meals is a UI grouping of
  Lunch/Dinner, no data change); Cook with chip with × and Change; results and
  counts; favourites; My recipes button. My Recipes: All / Saved / Added by me
  with counts, Add a Recipe. Add a Recipe: paste link / paste text / write my own
  — do not claim URL extraction or parsing unless it exists; no fabricated
  ingredients; no unsupported buttons; no provider/licensing/API changes.
- **Diary hub:** extra entry point, not a replacement. Today hero (opens
  current-day entries), then Log symptoms, Log a meal, Log activities (accurate
  Coming Soon), Notes (accurate Coming Soon; replaces "Log cycle details"), View
  my entries (existing history). Existing forms, routes and persistence
  untouched; no migration; premium rules unchanged.
- **Notes:** new functionality; multiple entries per day, edit, delete with
  confirmation, additive migration in the encrypted DB; content never logged or
  sent anywhere; no AI, sentiment, streaks. Proposal before code.
- **Activity log:** type, date, optional duration/intensity/notes; no calorie
  estimates or Apple Health. Proposal before code.
- **Eat follow-up:** the Meal Builder back label ("Back to Foods") is a separate,
  approved navigation change if needed.

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
