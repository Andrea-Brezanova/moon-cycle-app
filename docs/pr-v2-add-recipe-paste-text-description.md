## Summary
**Add a Recipe, part 2: paste text.** Paste a recipe you already have; it is read **on the phone only** (no AI, no network, no third party) and fills the same editor as Part 1 as a draft for you to check.

- **Add a recipe** now has two tabs: **Write my own** and **Paste text** (only when adding; editing a saved recipe has no tabs).
- **Paste text**: a large box and **Review recipe**. The parser reads a title (first plain line), "Ingredients" / "Method" / "Directions" / "Notes" headings, servings ("Serves 4", "Servings: 2-3", "Yield: 8 servings", "4 servings"), and times (total, or prep plus cook; "1 hour 10 minutes"). Without headings, lines that start with an amount are taken as ingredients and the sentences after them as steps. Bullets and numbering are removed.
- **Nothing invented**: whatever is missing stays empty, and the review note says what was found ("Found: a name, 2 ingredients, 2 steps…") and what wasn't. Text that can't be placed goes to "About it" for the user to deal with. **Quantities stay inside the ingredient line exactly as written** (no structured amounts are guessed, so shopping and display never show a wrong quantity).
- **Review and explicit save**: the draft opens in the manual editor; nothing is saved until **Save recipe**. Pasting over writing asks before replacing it, and leaving with unsaved work asks first.
- **Dietary and allergen honesty**: ingredients are matched to Moon Cycle foods by name. A live list under the ingredients names every line that **can't be checked** against food preferences or allergens ("2 of 7 ingredients can’t be checked…"). This also applies to recipes typed by hand (Part 1).
- Saving, editing, deleting, My recipes › Added by me, the shopping list and Log a meal behave exactly as in Part 1. **No database migration; no schema change.**

**Not in this PR**: URL import. A concise technical and licensing plan is in `docs/add-recipe-url-import-plan.md` for your approval; nothing of it is built.

## Tests
- Local, targeted: generation suites (112 tests, including 7 new parser tests and 4 new flow tests) and `flutter analyze` clean.
- Covered: headed and unheaded recipes, bullets and numbering, serves and time variants, CRLF, nothing invented, same input gives the same draft; paste → draft → edit → explicit save; nothing stored before Save; replace prompt; unchecked-ingredient list; no tabs when editing; 320 pt and 2× text in light and dark with tap-target and label checks.
- Goldens: the 3 Add a recipe goldens re-recorded for the tabs; 2 new for the Paste text tab.
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

**Left open for the owner's review.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)
