# Diary Notes: design and data model (schema v7)

Status: implemented on `feature/v2-diary-notes`. **New personal-data feature: the PR is left open for the owner's approval.**

## What it is
A private, free-writing journal inside My Diary. Distinct from the small optional note inside Log symptoms (untouched).

- Several notes per day; an optional title; free multi-line text; a day (defaults to today, can be changed).
- Write, save, reopen, edit, delete (with confirmation). Nothing is saved until **Save note**; leaving with unsaved writing asks "Discard your writing?".
- The Notes list (`/more/diary/notes`) shows notes newest day first, grouped by day, and within a day the latest written first; the diary history gets a **Notes** tab for the viewed day.
- The writing editor (`/more/diary/notes/new`, `/more/diary/notes/:id`) covers the tab bar like the other diary forms.
- No AI, no sentiment or mood analysis, no streaks, reminders, counts or completion pressure.

## Data model (additive migration 6 to 7)
New table `diary_notes` (same user-row shape as every user table):

| Column | Type | Meaning |
|---|---|---|
| `id`, `created_at`, `updated_at`, `deleted_at` | as other user tables | client id, timestamps, tombstone |
| `date` | text `YYYY-MM-DD` | the diary day |
| `title` | text, nullable | optional title |
| `body` | text | the writing |

Index `diary_notes_live` on `(date)` where `deleted_at IS NULL`. Nothing existing changes: no column, table or row is altered. Migration verified from a populated v6 database (`test/core/database/diary_notes_v7_migration_test.dart`); the schema snapshot `drift_schemas/app_database/drift_schema_v7.json` and generated migration helpers are included.

## Privacy and safety
- Lives only in the existing **encrypted** local database (SQLCipher); a test confirms the writing is not readable as plain text in the file and survives closing and reopening it.
- **Delete** tombstones the row like every user row **and empties its title and text**, so deleted writing is not kept on the phone.
- The text is never logged, printed, put in analytics or crash reports, or sent to any service (the app has none for it).
- **Delete my data** wipes the whole database file (notes included). **Export my data** now includes a `notes` list (date, title, text, timestamps); the export format version is unchanged because the field is additive.
- Premium rules unchanged: Notes follows the same diary availability as the other diary cards.

## Assumptions
- A note with neither a title nor any text is not stored (Save is disabled).
- No limit on length; no rich text or attachments in this version.
- Future days are not offered (like the rest of the diary).
- Wording updated with the Notes feature: Delete my data and Privacy & Data now name the diary and personal Notes, and **Export my data** shows a notice first ("Before you export": the file may contain sensitive writing and is not encrypted once it leaves the app) with Continue and Cancel; nothing is shared until Continue.
