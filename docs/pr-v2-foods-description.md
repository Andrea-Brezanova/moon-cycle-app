## Summary
V2 redesign of the **Foods** screen (`/eat/foods`), approved on a physical iPhone.

- Header: back chevron, centred "Foods" title, search icon (opens the existing "Search foods" field; "All phases" still shows it by default).
- Phase selector pill (unchanged behaviour), then wrapping category chips: **All** plus each category the phase has and the user's preferences allow. Choosing a category shows only its foods with its heading and count, and hides Today's Food.
- **Today's Food** card: photographic when the food has a curated photo (ivory text on a plum fade), otherwise a tinted card; unchanged headline copy and unchanged "today's food" selection.
- **All foods** list: A–Z, thumbnail (photo or emoji tile), serif name, category, and a round **+** that adds the food to the shopping list (becomes a check that removes it). Tapping the row opens the existing Food Detail.
- Light and dark, 320 pt and large text (no mid-word breaks), 44 pt targets, decorative images hidden from screen readers.
- The phase pill moved to `phase_pill.dart` so Foods and Recipes share it.

Not changed: food data, nutrients, allergens, recommendation logic, Food Detail, the dedicated 3 Plants a Day screen and Home's shortcut, Recipes, Meal builder, shopping list logic, entitlements, database.

## Notes
- There was no 3 Plants a Day preview on Foods in `main`, so nothing needed removing.
- Removed from Foods (not in the design): the floating "Build a meal" button and the "Your foods for this phase" hint line. The Meal builder is still on the Eat hub and in Food Detail.
- Search now also works in the single-phase view (via the header icon).
- Foods list thumbnails are emoji tiles except broccoli, avocado and blueberry (only curated photos in the repo).

## Tests
- Local (targeted): Foods page tests (19), Eat hub, cycle/app/a11y/recipes/plants/shopping suites; `flutter analyze` clean.
- New tests: category filtering and hiding Today's Food, search icon, + / check adding and removing a food (persisted).
- Goldens: re-recorded only the 7 affected Foods goldens on macOS 15 (`dark|light-foods`, `-all`, `-browsing`, `light-foods-narrow-large-text`) and reviewed them.
- CI (full non-golden suite, golden screenshots, Android build): see the checks on the final commit.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
