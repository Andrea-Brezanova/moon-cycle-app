# Build a Meal 2.0: proposal and foundations

**Status: proposal. Not active.** The only code added is a pure, unwired module (`lib/features/meal_balance/`) with tests. No screen, provider or production behaviour changed. Activating any new flow needs the owner's approval.

## 1. How Build a Meal works today (read from the code)

1. **Pick foods.** `MealSelection` (`foods/application/meal_selection.dart`): 1 to 8 foods, any category, each once. `mealOptionsProvider` offers three sections (protein, base, plant); diet and avoidances apply via `FoodFilter.allowsFood`; foods featured in the user's *current* phase are listed first, then the rest A to Z.
2. **Find recipes.** `RecipeDiscovery` asks every `RecipeSourceProvider` (the Moon Cycle library, and external providers in development builds) for recipes using at least one chosen food, then merges, ranks and de-duplicates. Nothing is generated.
3. **Rank.** `RecipeMatcher` (`discovery/domain/recipe_matcher.dart`, numbers in `MatchConfig`): more chosen foods first; complete (all chosen foods), good (at least 60%), partial; score = 100 per matched food + 8 if the recipe is written for the current phase + 4 for a complete method − 0.5 per extra food.
4. **Show.** `MealResultsPage`: results, "see more", provider failures, empty state.

Already true: any food can start a meal; ingredient freedom (1 to 8) is implemented; diet and allergens are filters, not scores. The pieces missing for "2.0" are nutritional balance, explanation, and suggesting what to add.

## 2. Goals mapped to design

| Goal | Design |
|---|---|
| A. Nutritional balance | `MealBalance`: share of a basic plate covered (vegetables and fruit, grain or starch, protein including beans and lentils), per USDA MyPlate and the Harvard Healthy Eating Plate. Plate-level only: no calorie, nutrient or health claim. Nutrient-aware balance waits for published profiles (see section 5). |
| B. Preference | Hard filters first (diet, allergens, "may contain", avoidances, disliked foods), then scoring. A filtered food is never scored or shown. |
| C. Flexible start | Any food, or nothing. Suggestions are computed from whatever is chosen. |
| D. Explainability | Every suggestion carries `Reason`s (code, plain text, source). Reasons come only from a fixed, reviewed list. |
| E. Cycle awareness | Not a score input. Optional `featuredIds` may break exact ties; it adds no reason and no claim. See the review of existing phase ordering in section 7. |
| F. Ingredient freedom | No required structure. The plate idea is a suggestion, never a gate. |

## 3. Architecture

```
lib/features/meal_balance/domain/        pure Dart, no Flutter/Riverpod (check_layers enforces)
  plate_group.dart        Food -> PlateGroup (from the food's own category)
  meal_balance.dart       MealBalance.evaluate(chosen) -> present / missing / score
  pairing_rules.dart      Reason + documented pairings (vitamin C with plant iron)
  complement_ranker.dart  suggestComplements(...) -> ranked Suggestions with reasons
```
Later (not built): `application/` providers that feed the ranker from `catalogueProvider`, `foodFilterProvider` and the dislikes list; a presentation widget on the meal page. Recipe matching stays as is; suggestions are an additional section, not a replacement.

## 4. Scoring and ranking specification (`RankerConfig`)

Inputs: chosen foods, candidate foods, `allows(food)` predicate (safety), `dislikedIds`, optional `featuredIds`.
1. Exclude: already chosen; disliked; `!allows`; plate groups that do not count toward balance (seasoning, fermented, other).
2. Score: **+3.0** if the food fills the first missing core part (vegetables and fruit, then grain or starch, then protein), minus **0.5** per later missing part; **+2.0** for a documented pairing; **+0.5** for a category not yet in the meal; **−1.0** if its part is already covered while another is missing.
3. Order: score descending; then (only on an exact tie) featured; then name A to Z; then id. Deterministic, no randomness or clock.
4. Limit: 6 by default.
5. Reasons: `completes-plate`, `plant-iron-vitamin-c`, `adds-variety`, `goes-with` (fallback). Text never mentions a phase, hormone or health outcome (tested over all catalogue foods).

Recipe ranking is unchanged. A later PR may add balance as a *secondary* sort key after "more chosen foods first".

## 5. Data-model compatibility

| Need | Source | Status |
|---|---|---|
| Food group | `Food.categoryId` (10 categories, 271 foods) | Ready; every food maps (tested). |
| Allergens and diet | `Food.allergenIds`, `mayContainAllergenIds`, `animalSource`, `FoodFilter` | Ready; used as hard filters. |
| Dislikes | `FoodFilter` avoidances today cover allergies and diet; a "dislikes" list does not exist | New small preference (UiPrefs-style file or database column). Needs a schema decision. |
| Recipe lines | `Recipe.ingredients[].foodId` (nullable), `keyFoodIds` | Ready; unmatched free-text lines are ignored by matching (known limit). |
| Nutrient values | `FoodProfile` (5 published; 98 staged, unpublished) | Not enough for catalogue-wide nutrient scoring. When profiles are published, derive tags (for example vitamin C at or above 20% of the daily reference) from them instead of the curated id lists in `pairing_rules.dart`. |
| Saved meals and collections | `SavedRecipeRef`, collections | No change needed; suggestions are not saved. |
| Shopping list | Food ids | A suggested food can be added with the existing action. |

No database migration is needed for the foundation.

## 6. UI flow proposal (fits the existing design; not built)

On the Build a Meal page, below the chosen-food chips: a section **"Goes well with"** with up to six food chips (the same chip component), each tappable to add. A one-line reason sits under the section for the first chip and in a small sheet for the others ("Adds vegetables or fruit, which fill half of a balanced plate."). When the plate is covered the heading becomes "Adds variety". Empty selection shows the existing prompt, plus a quiet "Start with anything" line. No new screens, no colour or typography changes. A "Plate" mini-indicator (three dots: veg/fruit, grain, protein) is optional and needs design approval.

## 7. Edge cases and acceptance criteria

| Case | Expected |
|---|---|
| Nothing chosen | Suggestions start with vegetables and fruit; nothing breaks. |
| One fruit or one dessert-like food | Still suggests a protein or grain; no error. |
| Only seasoning chosen | Treated as an empty plate. |
| All candidates filtered (strict diet + several allergens) | Empty list and the existing empty-state copy; never an unsafe food. |
| Food with "may contain" for an avoided allergen | Excluded (existing conservative filter). |
| Eight foods chosen (limit) | Suggestions still shown; adding is disabled with the existing limit message. |
| Same food as a synonym or twin (green and red lentil) | Not suggested together as separate ideas (the existing twin rule moves into the application layer later). |
| Recipe with unmatched lines | Matching unchanged; known limitation documented. |
| Cycle data missing or unknown | No effect: the cycle is not an input. |
| Offline | Works: pure, local. |
Acceptance: deterministic output; zero disallowed foods; every suggestion has at least one reason with a source; no reason text mentions a phase, hormone, detox or health outcome; unit tests above pass; production goldens unchanged.

**Review item (existing code, not changed):** `proteinIdeasProvider` demotes "heavy meats" in the follicular and ovulatory phases and lists phase-featured foods first, and `RecipeMatcher` adds a phase bonus. Neither states a claim, but both order food by phase with no supporting research. The owner may want the "light" meat demotion removed or the phase bonus kept strictly as a tie-break.

## 8. Testing strategy

Pure unit tests with the real catalogue (done: `test/features/meal_balance/`); property-style checks across all foods (no unsafe food, no claim wording); golden and widget tests for the future section; integration test that chosen foods plus filters never surface an avoided allergen; regression test that recipe ranking is unchanged.

## 9. Implementation plan: small, reviewable PRs

1. **(done in this PR)** Pure foundations and tests; this document.
2. Dislikes preference (data and Settings row), with persistence and deletion tests. Needs schema approval.
3. Application layer: `mealSuggestionsProvider` wired to filters, dislikes and twins; provider tests; still not shown.
4. UI section behind a debug-only flag; widget and golden tests.
5. Owner review of the flag build on the iPhone; then enable.
6. Nutrient-aware rules from published profiles (after Wave 1 is approved).
7. Optional: balance as a secondary recipe sort key.

## 10. Owner decisions needed

Whether to add a dislikes list; whether to show the "Goes well with" section at all; whether the phase-ordered protein ideas and recipe phase bonus stay; approval for the optional plate indicator.
