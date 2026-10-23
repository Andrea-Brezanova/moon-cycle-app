## Summary
**Activity logging**: a voluntary way to note movement inside My Diary. **New personal-data storage and a database migration: please review before merging.** Design and data model: `docs/diary-activities-v8.md`.

- **Log**: type (Walk, Run, Cycle, Swim, Hike, Yoga, Pilates, Strength, Dance, Stretching, Other), a day, and optionally minutes, how it felt (Light, Moderate, Vigorous) and a note. Only the type is required.
- **Manage**: Activities list (newest day first, grouped by day), reopen, edit, delete with confirmation; leaving with unsaved changes asks first. The hub's Log activities card opens the list (it was a Coming soon page, now removed).
- **Storage**: new additive table `diary_activities` (schema 7 to 8) in the existing encrypted database; migration tested from a populated v7 database. Delete empties the name and note.
- **Privacy and scope**: no estimates, scores, targets, reminders, streaks or medical claims; no health integrations; never logged or sent anywhere. Included in Export my data (`activities`); removed by Delete my data. The Delete, Privacy & Data and Export-notice wording now names activities. The Move recommendation engine is untouched.

## Tests
- Local, targeted: diary (new `diary_activities_test`, `diary_activity_repository_test`), database (new v8 migration test), privacy export and wording, settings, a11y suites; `flutter analyze` clean.
- Covered: type-only and full saves, Other with a name, invalid durations blocked, edit and clearing a feeling, delete with confirmation, unsaved-changes prompt, ordering, unknown-type rows ignored, encrypted-file restart persistence, migration from populated v7, export, 320 pt and 2× text in light and dark with tap-target and label checks.
- Goldens: 4 new (activities empty, editor; light and dark); Privacy & Data and Delete my data goldens re-recorded for the wording; 2 Coming soon goldens removed with the page.
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

**Left open for the owner's review (new personal-data feature). Not merged.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)
