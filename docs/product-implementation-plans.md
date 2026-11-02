# Product implementation plans (1 Nov 2026)

Three practical plans, each cut into small PRs that keep `main` shippable. Only plan B has a code foundation (pure, unwired). Nothing here changes what the user sees until the owner approves the activation PR of a plan. Every plan keeps the evidence boundary: cycle context is a label, never a reason to recommend food.

Status key: **built** (merged or in a PR, unwired), **plan** (not built).

## A. A more useful "What next?" Home

**Today.** Home (`home_page.dart`) shows: hero, Today's focus (phase headline and a short body), Today's picks (3 plants, 3 ways to move, 3 minutes of calm), Your space (Collections, Diary, Shopping). Nothing says what to do *now*, and nothing reflects what the user did today.

**Principle.** One primary suggestion, driven by things the user has done or left undone, not by the cycle. Candidates, in a fixed priority order, first applicable wins:
1. Period late or due: the existing late card (unchanged).
2. Nothing logged today: "Log today" (diary).
3. A meal in progress or a saved meal idea not yet used: "Finish your meal".
4. Shopping list has open items: "N things on your list".
5. Default: the existing 3 plants.

**PRs (plan)**
1. `NextStep` pure domain: input = counts and flags (late, loggedToday, hasDraftMeal, openShoppingItems), output = one `NextStep` with a stable id, title, route, no wording about phase. Table-driven tests for the priority order and ties. No UI.
2. `nextStepProvider` reading existing repositories (diary today, shopping, meal draft). Provider tests with fakes. No UI.
3. A single quiet "Next" card above Today's picks, behind a debug flag; widget and golden tests; accessibility tests (label, 44 pt target, 320 pt/1.5×).
4. Owner review on the phone; then enable. Telemetry: none (no analytics); judge by use.

**Risks.** Crowding Home (mitigation: the card replaces nothing, and shows nothing when no rule applies beyond default); implying obligation (mitigation: wording is an offer: "Log today?", never "You haven't…"); data from the draft meal needs plan C's kept-alive draft (built in #88).

## B. One search across foods and recipes

**Today.** Search exists per list (Foods, the Build a Meal picker, avoidance sheets). Recipes have a separate entry; there is no search that spans both.

**Built (this PR, pure and unwired).** `lib/features/search/domain/unified_search.dart`:
- Whole-word and word-start matching on food names, food synonyms, recipe titles and a recipe's key foods; all words must match.
- The user's diet and allergies are applied first and strictly (foods *and* recipes), tested across many queries.
- Deterministic order: score, foods before recipes, title, id. No phase, popularity, time or randomness.
- 10 tests with the real catalogue.

**PRs (plan)**
1. (done) The domain function and tests.
2. `searchResultsProvider(query)` in an application layer with a debounce-free pure read of catalogue + filter; provider tests.
3. A search field on Eat (below the hero) opening a results page with two small groups (Foods, Recipes); empty and no-result states; accessibility tests. Behind a debug flag.
4. Recents (last five queries) stored in the existing UI prefs file, cleared by Delete my data; test.
5. Owner review, then enable; later optionally include "My recipes" and saved meal ideas (they are local rows).

**Risks.** Unfiltered results leaking an allergen (mitigated: filter first, tested); matching quality for non-English names (out of scope); two search entry points confusing users (plan: the new field replaces the Eat > Foods search only after review).

## C. A central place for saved meals, recipes, routines and discoveries

**Today.** My Collections already merges saved library recipes, saved external recipe references, the user's own recipes and saved links into one newest-first list (`collectionItemsProvider`), with a "recently saved" strip (5). Routines live in their own screens; meal ideas and "discoveries" (saved foods) do not exist yet.

**PRs (plan)**
1. Saved meal ideas storage (`saved_meal_ideas`, schema 12→13 or 13→14; additive; spec in `docs/build-a-meal-2-data-model.md`), repository, export and wipe tests. No UI.
2. Extend `collectionItemsProvider` to include routines and meal ideas as new `RecentItem` kinds (route + badge only); provider tests proving existing items are unchanged and order is newest-first.
3. Category chips on the Collections landing page (All, Recipes, Meals, Routines, Links) and a text filter that reuses the unified search matcher over titles; accessibility and golden tests.
4. "Save this meal" action on the Build a Meal 2.0 results (part of the Build a Meal activation), writing a meal idea that is **re-checked against the user's current diet and allergies each time it is shown**.
5. Owner review; enable.

**Risks.** A saved item that later conflicts with a new allergy (mitigated: re-check on show, mark rather than delete); schema growth (additive only); duplicate-looking entries across recipe and meal idea (mitigated: distinct badges).

## Sequencing recommendation

B (search) and A-1/A-2 can proceed in parallel and are the cheapest to review. C-1 should follow the Build a Meal 2.0 owner approval because its main writer is that flow. Highest user value per unit effort: **B**, then **A**, then **C**.
