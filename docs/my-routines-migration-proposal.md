# My Routines: smallest migration proposal (not applied)

Status: **proposal only.** The My Routines tile and page exist on My Collections but say
routines are not available yet, because saving a routine needs a schema change and this
repo's rule is that no migration touching personal data is merged without approval.

## What a routine is

A user-created, reusable, ordered list of steps, for example "Morning stretch and
meditation" or "Evening wind-down". Each step is one of: a saved workout or spa link, a
saved link, or a plain text step ("5 minutes of slow breathing"). No scheduler, calendar,
reminders or recommendations in this version.

## Smallest schema (drift schema v9 → v10, additive)

Two new tables, both with the usual `UserRow` columns (id, createdAt, updatedAt,
deletedAt tombstone) and encrypted in the existing SQLCipher database:

- `routines`: `id`, `title` (text, required), `note` (text, nullable).
- `routine_steps`: `id`, `routine_id` (references `routines.id`), `position` (int),
  `kind` (`link` | `text`), `link_id` (nullable, references `collection_links.id`),
  `text` (nullable).

No existing table or row changes. Steps reference saved links by id, so a link is never
copied; if the link is removed the step shows "Removed link" and can be deleted. Recipes
are not routine steps in this version (so link-only recipes cannot leak into ingredient
matching).

## Tests that must accompany it

1. Migration test (drift `make-migrations` verification): v9 database with data upgrades
   to v10 with every existing row intact; the new tables are empty.
2. Repository tests: create, rename, add/reorder/remove steps, tombstone delete, a step
   whose link was removed.
3. Export includes routines; Delete my data removes them (existing export/delete tests
   extended).
4. Widget tests: create, edit, remove, open a step's link; goldens for the list and editor.

## Rollback

The change is additive: the new tables are not read by any existing feature. Rolling back
the app version leaves two unused empty or small tables; no downgrade script is needed.
Before release the schema dump and migration test are reviewed; the encrypted database
file is backed up by the existing pre-migration copy.

## Decision needed

Approve schema v10 with `routines` and `routine_steps` as above. The implementation is
prepared on the draft branch `draft/my-routines` and is not for merge until approved.

## Draft implementation (this branch, unmerged)

Schema v10 (`routines`, `routine_steps`), the `from9To10` step, the generated schema
snapshot and migration test, and `RoutineRepository` with tests (create, rename, ordered
steps, move, remove, tombstone delete). **Not included yet:** the My Routines screens
(list, editor, add a saved link as a step), export of routines in Export my data, and
the Move hub's "Build Your Routine" flow; they follow once the schema is approved.
