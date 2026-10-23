## Summary
Makes the four Food Detail actions consistent for every food and fixes return navigation. Audit: `docs/food-detail-audit.md`.

- **Root cause of the missing "Find recipes with amaranth":** the button was hidden when a food had no allowed recipes. 103 of 271 foods have no recipe at all (Amaranth among them), so they showed a text line instead of the action.
- All foods now show the same four actions in the same order: **Find recipes · Make your own meal · Add to/Remove from shopping list · Log meal**. With no recipes, Find recipes is a disabled button with the reason: no recipes yet, none in this phase, or hidden by your food preferences.
- **Find recipes** is pushed, not replaced: Back returns to the originating Food Detail (the ingredient is preselected by canonical id and can be changed or cleared).
- Meal builder opens with the food chosen and Back returns to the food; herbs (never offered as ingredients) show a disabled button with the reason. Premium checks unchanged.
- V2 header on Food Detail and Meal builder (chevron, centred title); Foods, Recipes and My recipes no longer hard-code "Back to Eat/Recipes" (spoken label is "Back").
- Fallbacks: Food Detail → Foods, Meal builder → Eat.

Not changed: food/recipe data, filter logic, shopping list and diary logic or schema, entitlements, database.

## Tests
- Local, targeted (foods, eat, recipes, discovery, a11y, app/shell, cycle: 483 tests passing); `flutter analyze` clean.
- New `food_detail_navigation_test.dart`: four actions for Artichoke, Apricot, Amaranth; preferences-hidden reason; Find recipes preselection and Back through food → Foods; Meal builder preselection and Back; Premium and herb states; Log meal preselection and Back; shopping add/remove with no duplicates; direct-link fallback; 320 pt and 2× text in light and dark.
- Goldens: re-recorded only the 12 affected Foods-detail/Meal-builder goldens (header change) on macOS 15 and reviewed them.
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

Screenshots: `docs/food-detail-shots/`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
