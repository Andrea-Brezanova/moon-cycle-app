## Summary
The V2 **My Diary** landing hub, following the approved light and dark designs. It is an additional entry point: no diary screen, form or record is replaced.

- **Hub** (`/more/diary`): back chevron, large "My Diary" title, the subtitle, a **Today** card (lavender, vector botanical, round arrow; opens today's entries), then five cards in order: **Log symptoms** (existing form), **Log a meal** (existing form), **Log activities** and **Notes** (honest Coming soon pages), **View my entries** (existing history).
- **Routes:** the history (Meals and Symptoms by day, date navigation, editing, deletion) moves to `/more/diary/entries`; `Routes.diaryOn(...)` now points there, so every existing link into the history (e.g. "View" after saving a meal) still lands on it. `/more/diary/log-meal` and `/log-symptoms` are unchanged. Home's and More's My Diary links open the hub.
- **Coming soon pages** (`/more/diary/activities`, `/more/diary/notes`): no form, no field, nothing is saved. They replace the old "Log cycle details" idea; there is no cycle-logging card (cycle observations belong to Symptoms).
- Where the diary isn't available on the plan, the hub cards show a lock and open the Subscription page, like Log meal on a food page. Entitlement rules are unchanged.
- At large text the Today card drops its picture so words stay whole. The sprig painter moved to `core/design/widgets/botanical_sprig.dart` (shared with Home).

Not changed: diary and symptom logging, history, persistence, schema, entitlements, Home design.

## Tests
- Local, targeted: diary, home, a11y and app/shell suites; `flutter analyze` clean.
- New `diary_hub_test.dart`: title, subtitle, Today and the five cards in order (no "Log cycle details"); the two forms open and Back returns to the hub; Today and View my entries open the existing history and Back returns; Coming soon pages are honest (no fields); direct links to history and forms still work; 320 pt and 2× text in light and dark with 44 pt target and label checks.
- Existing diary tests that opened the history by route now use `Routes.diaryEntries`; Home's quick-access test expects the hub.
- Goldens: five new (hub light, dark, narrow large text; Coming soon light, dark). No existing golden changed.
- CI (full non-golden suite, goldens, Android build): see the checks on the final commit.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
