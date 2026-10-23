# Food Detail actions and navigation audit

Branch `fix/food-detail-navigation`. Data from `assets/content/` (271 foods, 112 recipes).

## Why Amaranth had no "Find recipes with amaranth"
Food Detail showed the button only when the food had at least one allowed recipe
(`count > 0`), otherwise a plain "No recipes with … yet." line in its place. No bundled
recipe lists Amaranth as a key food, so it got the line and the four actions looked
different from food to food. The rule was intentional, but it hid an action.

## Foods affected
- **103 of 271 foods** have no recipe in any phase (e.g. Amaranth, burdock, kelp, duck).
  They now show the same four actions, with "Find recipes" disabled and the reason.
- Every one of the 142 (food, phase) pairs where a food is featured has at least one
  recipe in that phase, so a phase-featured food never lost the button.
- 129 foods are featured in no phase (opened through "All phases"). No food is
  featured in more than one phase.
- Food preferences can also remove the recipes of an otherwise recipe-rich food; that
  case is now explained too.

## Action audit (one implementation for every food)
| # | Action | Shown | Condition now |
|---|--------|-------|---------------|
| 1 | Find recipes with [food] | always | enabled when allowed recipes exist; otherwise disabled with the reason: none exist / none in this phase / hidden by your food preferences (counted before the preferences are applied) |
| 2 | Make your own meal with [food] | always | Premium check unchanged (free users go to Subscription); disabled for herbs, which the meal builder never offers as ingredients (previously it opened the builder without the herb) |
| 3 | Add to / Remove from shopping list | always | persisted membership; stays on the page; no duplicates |
| 4 | Log meal | always | diary check unchanged |

Canonical food ids are used throughout (`Routes.food(id)`, `showRecipesWith(food.id)`,
`mealBuilder(foodId:)`, `logMeal(itemId: food.id)`).

## Navigation issues found and fixed
1. **Find recipes replaced the stack** (`context.go`), so Back from Recipes skipped the
   food and went to the Eat hub. Now pushed: Back returns to the originating Food Detail.
2. **Hard-coded back labels**: Food Detail said "Foods", Meal builder "Foods", and the
   V2 Foods, Recipes and My recipes pages "Back to Eat"/"Back to Recipes", whichever
   screen the user came from. All now use the V2 header: left chevron (44 pt), centred
   title, and the spoken label "Back" (Back goes to the screen that opened the page).
3. **Fallbacks**: with nothing behind it, Food Detail falls back to Foods and the Meal
   builder to Eat (it went to Home before).
4. **Meal builder** opens with the originating food chosen (only that food: its
   selection is discarded on leaving) and Back returns to the food.
5. **Log meal** opens with the food preselected; closing returns to the food. Diary
   schema and logging logic untouched.

## Paths that do not exist (so were not changed)
Recipe detail and 3 Plants a Day do not link to Food Detail today. Entry points to Food
Detail are the Foods list and Today's food.
