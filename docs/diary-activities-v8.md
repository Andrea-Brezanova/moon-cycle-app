# Activity logging: design and data model (schema v8)

Status: implemented on `feature/v2-activity-log`. **New personal-data feature: the PR is left open for the owner's approval.**

## What it is
A voluntary way to note movement, inside My Diary (Log activities card). It is a record, not a coach: nothing is estimated, scored, compared or recommended, and there are no goals, streaks or reminders. It is separate from the Move tab's suggestions, which are untouched.

- **What**: Walk, Run, Cycle, Swim, Hike, Yoga, Pilates, Strength, Dance, Stretching, Other (Other can have a name).
- **When**: a day (today by default; past days only).
- **Optional**: minutes (1 to 1440), how it felt (Light / Moderate / Vigorous; tap again to take it back) and a note.
- Save, reopen, edit, delete with confirmation; several per day; list newest day first and grouped by day. Leaving with unsaved changes asks first.
- Routes: `/more/diary/activities` (list), `/activities/new`, `/activities/:id` (editor on the root navigator, like the other diary forms).

## Data model (additive migration 7 to 8)
New table `diary_activities` (the same user-row shape as every user table):

| Column | Type | Meaning |
|---|---|---|
| `id`, `created_at`, `updated_at`, `deleted_at` | as other user tables | client id, timestamps, tombstone |
| `date` | text `YYYY-MM-DD` | the diary day |
| `type` | text | a key from the fixed list (`walk`, `run`, ..., `other`) |
| `custom_name` | text, nullable | the name for `other` only |
| `minutes` | integer, nullable | 1 to 1440, else stored as not given |
| `intensity` | text, nullable | `light`, `moderate`, `vigorous` |
| `note` | text, nullable | the user's note |

Index `diary_activities_live` on `(date)` where `deleted_at IS NULL`. Nothing existing changes. Verified from a populated v7 database (`diary_activities_v8_migration_test.dart`); snapshot `drift_schema_v8.json` and generated helpers included. A row whose `type` is unknown (written by a newer version) is left out of lists rather than crashing.

## Privacy and safety
- Encrypted local database only; a test confirms the name is not readable in the file and survives a close and reopen. Never logged or sent anywhere. No Apple Health or other integration.
- Delete tombstones the row and empties its name and note.
- Export my data includes an `activities` list; Delete my data wipes the whole database. The Delete, Privacy & Data and Export notice wording now names activities.
- No calories, exertion scores, targets, hormonal conclusions or medical claims. Copy is neutral ("There are no goals here, just a place to remember").
- The diary hub's Log activities card follows the same availability as the other diary cards (lock and Subscription page where the diary isn't available).

## Assumptions
- Only the type is required; everything else may be left empty.
- Free text (name, note) is not analysed.
- No separate Activities tab in the diary history (it already has three); the Activities list is the history.
- The old "Coming soon" page and its goldens were removed (nothing uses it now).
