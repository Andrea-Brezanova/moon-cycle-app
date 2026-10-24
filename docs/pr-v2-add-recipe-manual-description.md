## Summary
**Add a Recipe, part 1: write your own.** Under Eat › Recipes › My recipes (not My Diary). Review and decisions: `docs/add-recipe-review.md`.

- **My recipes** gets a **+** in the header and an **Add a recipe** button. **Add a recipe** is a form (name, Breakfast/Meals/Snacks, optional time and servings, an optional line about it, ingredients one per line, steps one per line). Nothing is saved until Save; leaving with unsaved writing asks first.
- Recipes you write appear in **My recipes › Added by me**, open in the normal recipe screen (with **Edit this recipe** and **Delete this recipe**), can be put on the **shopping list**, and can be chosen in **Log a meal**.
- **Dietary restrictions**: ingredient lines are matched to Moon Cycle foods by name where possible (so aisles and food preferences apply to those lines); anything else is kept as written and **can't be checked**, and the form and the recipe screen say so. No allergen, nutrition or phase claim is made for your own recipes.
- **Storage — no database migration.** It reuses the existing `personal_recipes` table under a fixed local owner (so it works without an account) with a new provenance origin `manual` (stored as text, additive). Nothing existing changes. Typed recipes are never sent anywhere or suggested to anyone (no server id; lifecycle stays private). They are included in Export my data and removed by Delete my data.
- The owner-scoped queries now read "the local owner plus the signed-in user", so generated recipes still show only for their own session.

**Not in this PR** (own PRs, as decided): paste-text import, and URL import (which needs your decision on licensing first; see the review doc). Pasted text and links are not offered yet, and nothing here claims to import.

## Tests
- Local, targeted: recipes, eat, diary, privacy, discovery, generation, a11y, app and home suites (412 + 101 tests) and `flutter analyze` clean.
- New: `manual_recipe_test` (line splitting, food matching, building and re-editing a recipe, validation, owner scoping, update keeps owner/origin/lifecycle) and `add_recipe_flow_test` (write and save, appears under Added by me, open/edit/delete, unsaved-writing prompt, selectable in Log a meal, 320 pt and 2× text in light and dark with tap-target and label checks).
- Goldens: 3 new (Add a recipe, light/dark/narrow large text); the two My recipes empty-state goldens re-recorded for the new button and +.
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

**Left open for the owner's approval**: this stores new user-written data (no migration). Not merged.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
