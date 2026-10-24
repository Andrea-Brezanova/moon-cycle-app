## Summary
Quieter **Quick access** on Home: the two photo cards become softly tinted cards with a large line icon, the feature name, one live line and a small chevron. Whole-card tap and the existing routes are unchanged.

- **My Diary** (lavender): a calendar-check icon with four small dots (meals, symptoms, activities, notes), so it doesn't suggest free writing only. The line counts **every diary entry recorded for today's local date**: each meal entry, the day's symptom check-in (one, however many answers it holds), each activity and each note. "Start your daily check-in" / "1 entry today" / "3 entries today".
- **Shopping List** (sage): the basket icon at the same size and stroke. "Your list is empty" / "1 item to buy" / "8 items to buy" from the existing to-buy count.
- **Live, read-only, no new storage**: a derived provider over the existing diary, symptom, activity and note streams (`todayDiaryEntryCountProvider`), keyed to `todayProvider`. It changes when an entry is saved, deleted or moved to another date, when you come back to Home, and at local midnight. Deleted rows and unsaved drafts are never counted. (One small read-only addition: `watchDay` for activities.)
- Both cards are the same height; narrow screens and large text stack them.

Unchanged: diary data and forms, Notes, Activity logging, the shopping list, cycle logic, routes, entitlements, the rest of Home.

## Decision to flag
A symptom **check-in counts as one entry per day**, not one per answer (energy, each mood, each body symptom), because the form saves a day's check-in as a set. Counting answers would make a single check-in read as "5 entries". Easy to change if you'd rather count answers.

## Tests
- Local, targeted: Home (38 tests) and the new count suite (8) pass; `flutter analyze` clean.
- Counts: zero, one, mixed kinds, several meals, only today (past and future dates excluded), deletions, unsaved/blank drafts, moving an entry to another date, a changed or cleared check-in, midnight rollover, the wording; Home updates when a meal is logged; 320 pt and large text in light and dark with tap-target and label checks.
- Goldens: the 16 Home goldens re-recorded for the new cards (reviewed).
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
