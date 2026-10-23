## Summary
**Diary Notes**: a private, free-writing journal inside My Diary. **New personal-data storage and a database migration: please review before merging.** Design and data model: `docs/diary-notes-v7.md`.

- **Write**: several notes per day, optional title, free multi-line text, changeable day. Nothing is saved until Save; leaving with unsaved writing asks first.
- **Read and manage**: Notes list (newest day first, grouped by day), reopen and edit, delete with confirmation. The diary history gets a **Notes** tab for the viewed day. The My Diary hub's Notes card now opens the list (it was a Coming soon page).
- **Storage**: new additive table `diary_notes` (schema 6 to 7) in the existing encrypted database. A populated v6 database keeps all diary entries and symptom check-ins (migration test). Delete tombstones the row **and empties its title and text**.
- **Privacy**: the text is never logged or sent anywhere; included in Export my data (`notes`) and removed by Delete my data (whole database). No AI, analysis, streaks or pressure.

Not changed: the Notes field inside Log symptoms, existing diary and symptom data, other schema, Premium rules, Move.

## Tests
- Local, targeted: diary (new `diary_notes_test`, `diary_note_repository_test`), database (new v7 migration test, snapshot test, encrypted-file test), privacy export, a11y, home and app suites; `flutter analyze` clean.
- Covered: add/read/edit/delete, blank notes, several per day, ordering, deleted writing emptied, restart persistence in the encrypted file (and not readable as plain text), migration from populated v6, Notes list/editor flows, discard and delete confirmations, history Notes tab, export, 320 pt and 2× text in light and dark with tap-target and label checks.
- Goldens: 4 new (notes empty, editor; light and dark) and the 11 diary history goldens re-recorded (the new Notes tab) on macOS 15 and reviewed.
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

**Left open for the owner's review (new personal-data feature). Not merged.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)
