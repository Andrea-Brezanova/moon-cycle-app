# Build a Meal 2.0: data model and migrations

Written 2026-11-01, **before** any schema code, as the owner asked. Status of each part is marked. Companion to `docs/build-a-meal-2.md`.

## 1. Principles

- **Additive only.** New tables or columns with defaults. Nothing existing is altered, renamed, dropped or rewritten, so a user can upgrade without losing anything.
- **Safety stays separate from taste.** Allergies, diet and avoided foods remain in `food_avoidances` and the diet preference and are enforced everywhere. A *dislike* is a taste preference used only to rank suggestions. Mixing them would let a taste setting leak into safety logic, or a safety setting be weakened by a "soft" flag.
- **Same row conventions as every user table** (`UserRow`): client-made id, `created_at`, `updated_at`, tombstone `deleted_at` (so it can sync later).
- **Local only, encrypted** with the rest of the database. Covered by Export my data and removed by Delete my data.

## 2. Dislikes (proposed, implemented in the next PR)

Why a new table and not a column on `food_avoidances`: `FoodFilter` treats every avoidance as a hard exclusion in Foods, Recipes, Shopping and Build a Meal. A dislike must only affect Build a Meal suggestions, and the user must still be able to pick a disliked food on purpose.

```
food_dislikes (UserRow)
  food_id  TEXT NOT NULL      -- catalogue food id, e.g. 'cilantro'
  UNIQUE INDEX food_dislikes_live ON food_dislikes (food_id) WHERE deleted_at IS NULL
```

- Domain: `Set<String>` of food ids (already the input of `suggestComplements(dislikedIds:)`).
- A food id that later leaves the catalogue is ignored (never an error, never shown), and the row is kept.
- Re-disliking a tombstoned food inserts a new live row (the partial unique index allows it).
- Removing a dislike sets `deleted_at` (tombstone), as avoidances do.

### Migration behaviour (schema 11 → 12)

```
from11To12: (m, schema) async {
  await m.createTable(schema.foodDislikes);
  await m.createIndex(schema.foodDislikesLive);
}
```

| Scenario | Result |
|---|---|
| Upgrade from v11 with data | Two new empty objects are created; every existing row is untouched. |
| Upgrade from any older version | The existing step-by-step chain runs, then this step. |
| Fresh install | Created with the rest of the schema. |
| Downgrade (older build opens a newer file) | Not supported for any schema version today (the app only moves forward); the new table deletes nothing. Same as every previous step. |
| Failure mid-step | Drift runs each step in a transaction; the file stays at v11. |
| Backup / restore | The table is in the database file, so it travels with it. |

Tests required (written with the PR): a v11 database with sample rows upgrades with every row intact and the new table empty; the schema snapshot and generated steps are updated (`drift_dev schema dump` and `steps`); the repository adds, de-duplicates, removes and re-adds; Export my data includes dislikes; Delete my data removes them; the unique index rejects a live duplicate; deleted catalogue ids are ignored.

## 3. Saved meal ideas ("My Meals") (proposed, later PR, needs the UI)

A *meal idea* is a set of foods with a name, not a recipe: it has no method and no quantities, so it does not belong in `personal_recipes` (which holds generated recipes with provenance) or `saved_recipe_refs` (which points at recipes).

```
saved_meal_ideas (UserRow)
  title     TEXT NOT NULL            -- user-editable; default built from the first foods
  food_ids  TEXT NOT NULL            -- JSON array of catalogue food ids, in chosen order
  note      TEXT NULL
```

- Schema 12 → 13 when built, additive and independent of dislikes, so either can ship alone.
- Ids that leave the catalogue are skipped when the idea is shown; the stored list is not rewritten.
- It is the user's own list: appears in My Collections (shown as "My meals"), export and wipe like other collection items.
- An idea is **re-checked against the user's current diet and allergies every time it is shown or used**, never trusted from when it was saved.

## 4. Selection and navigation state (no schema)

The draft meal in progress is **session state**, not stored: `mealDraftProvider` is kept alive for the app session so leaving the screen and returning keeps the chosen foods (implemented, unwired). Persisting an unfinished draft across app restarts is deliberately not proposed: it would write the user's food choices to disk without an explicit save.

## 5. Export and wipe

- `data_export.dart` gains `foodDislikes` (food ids only) when the table exists; the export schema version is bumped in the same PR.
- Delete my data already deletes the whole database file and the key; no per-table step is needed. A test confirms dislikes do not survive.

## 6. Out of scope

Weights per food, "likes", per-meal-type preferences, nutrient targets, cloud sync.
