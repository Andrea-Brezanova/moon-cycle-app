# My Diary: schema v6 specification (not yet implemented)

Status: **specification only.** No storage has been changed. Written for owner
approval before the migration is built (after Eat/navigation is verified).

## What exists (schema v5)
`diary_entries` (one row per thing eaten): `id`, `created_at`, `updated_at`,
`deleted_at` (tombstone), `date` (YYYY-MM-DD), `meal` (`breakfast|lunch|dinner|
snack`), `kind` (`food|recipe`), `item_id` (catalogue food id or recipe id),
`title` (name when logged), `amount` (real), `unit` (`serving|g|oz|cup|piece`).
The repository supports add (merging an identical item in the same meal and
unit), update, delete (tombstone), per-day and history watching.

## Changes (all additive; version 5 to 6)

### 1. `diary_entries`: two additive columns
| Column | Type | Rule |
|---|---|---|
| `note` | text, nullable | The user's note on a meal. Null for every existing row. |
| (none for "own meal") | | A manually entered meal is a new `kind` value, `custom`, in the existing `kind` text column. No new column. |

A `custom` entry: `title` is what the user typed, `item_id` is the empty string
(the column is `NOT NULL` in v5, and SQLite cannot relax that without
rebuilding the table, so it stays and is simply `''`), `amount` and `unit` keep
their existing values (default 1 serving, shown as nothing when it is the
default). **No nutritional values are stored or invented for any entry.**

### 2. New table `symptom_checkins` (one row per entry, several per day allowed)
The brief asks that symptoms can be "added or updated during the day" and not be
one immutable submission, so a day is a **set of rows, not one row**:

| Column | Type | Meaning |
|---|---|---|
| `id`, `created_at`, `updated_at`, `deleted_at` | as every user table | tombstone deletes |
| `date` | text `YYYY-MM-DD` | the diary day (history by date) |
| `category` | text | `energy`, `mood`, `body`, `sleep` |
| `symptom` | text | a fixed-vocabulary key: energy `very-low|low|okay|good|high`; mood `calm|happy|motivated|sensitive|irritable|anxious|low`; body `bleeding|cramps|bloating|headache|breast-tenderness`; sleep `poor|restless|okay|good|great` |
| `severity` | text, nullable | body only: `mild|moderate|strong` (bleeding: `spotting|light|medium|heavy`); null when not given |
| `note` | text, nullable | the optional day note lives on the row with `category = 'note'` and `symptom = 'note'` |

Rules kept in the repository (not the database):
* energy and sleep: at most one live row per date and category (choosing another
  replaces it; tapping the chosen one again tombstones it);
* mood and body: at most one live row per date and symptom;
* a row is added, changed or tombstoned independently, so the check-in can grow
  through the day and any single answer can be removed;
* no custom symptoms in this version (the vocabulary is closed), no scores, no
  interpretation text.

Index: `(date)` where `deleted_at IS NULL`.

## Why this shape
One flat table with a small closed vocabulary needs no JSON column, no second
table for strengths, and no migration when a symptom is added later. It fits the
existing tombstone and "live rows only" pattern used by `diary_entries`.

## How existing v5 data stays valid
* `onUpgrade` for `from < 6`: `m.addColumn(diaryEntries, diaryEntries.note)` and
  `m.createTable(symptomCheckins)` plus its index. Nothing else is touched.
* Existing rows keep all their values; `note` is null; `kind` is still `food`
  or `recipe`; unit and amount rules are unchanged.
* Code that reads `kind` handles `custom` as a third value; a v5 database never
  contains it.
* The backend catalogue and the Supabase schema are not involved (local only).

## Tests to add with the migration
1. A v5 database file with food and recipe entries (including a tombstone) opens
   at v6 with every row equal, `note` null.
2. Add / edit (title, note, meal, amount) / delete (tombstone) for `food`,
   `recipe` and `custom` entries.
3. The same-item merge rule still applies to food and recipe, never to `custom`.
4. Symptom rows: add, replace single-choice answers, toggle multi-choice,
   set and clear severity, tombstone, history by date, several updates in one
   day.
5. A 320 pt and large-text widget check for the new screens.

## Open points for approval
* `custom` as a `kind` value and `''` as its `item_id` (alternative: a nullable
  `item_id` via a table rebuild; riskier, not recommended).
* Whether the diary day note should be stored as the `note` pseudo-row above
  (proposed) or as its own small table.
