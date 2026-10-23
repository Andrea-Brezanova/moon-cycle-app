## Summary
V2 redesign of the **Recipes** and **My recipes** screens, following the approved designs.

- **Recipes** (`/eat/recipes`): centred title with back and an ingredient search icon (opens the existing Cook with sheet; hidden under "All phases", as Cook with already was), phase pill, All / Breakfast / Meals / Snacks pills, the Cook with bar (or the selected-ingredient chip with × and Change), the count line, and every matching recipe as a rounded card (thumbnail, title, meta, key ingredients) with a **heart** that saves it to My recipes. A prominent "My recipes (n)" button ends the list. At large text the card puts its picture on top so words stay whole.
- **My recipes** (`/eat/my-recipes`): centred title, intro line, **All / Saved / Added by me** filters with live counts, hearted recipes (saved bundled recipes as cards; outside recipes as title + provider rows) and recipes made for the user. Clear empty state for each filter.
- Shared `CenteredHeader` (back, centred title, optional icon); Foods now uses it too (no visual change).

Unchanged: recipe data and categories ("Meals" is still the UI grouping), filter logic and Cook with matching, phase-aware browsing, recipe detail, shopping list actions, saved-recipe and personal-recipe storage, external-provider rules, entitlements, database.

## Not built: Add a Recipe
The code audit found no paste-a-link, paste-text or write-my-own recipe flow, no URL extraction/parsing, and no import review step (the Create-a-recipe page is the generation flow and is not linked). I did not add a plus button, an Add a Recipe CTA, or an Add a Recipe screen, and nothing claims to import. Details and the decision needed are in `docs/v2-ui-roadmap.md` ("Add a Recipe audit").

## Tests
- Local, targeted: recipes, eat, discovery, foods, app/shell, cycle, generation and a11y suites; `flutter analyze` clean.
- New tests: heart saves/removes (persisted), My recipes filters/counts/empty states/hearts, search icon, 320 pt and 2× large text in light and dark with tap-target and label guidelines.
- Goldens: re-recorded only the 16 affected (14 Recipes states, 2 My recipes empty states) on macOS 15 and reviewed.
- CI (full non-golden suite, golden screenshots, Android build): see the checks on the final commit.

Screenshots: `docs/v2-recipes-shots/`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
