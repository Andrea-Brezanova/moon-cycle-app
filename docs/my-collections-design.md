# My Collections: structure and data model (revised)

Supersedes section 3 and 4 of `v2-product-audit-and-plan.md`. Keep what we have: Home,
Eat, Move, Relax, My Diary and Shopping are unchanged. The fifth tab is renamed **Me**
(route stays `/more`).

## Structure
- **My Collections** is the first section of Me, and opens a landing page with
  **three** categories: **My Recipes, My Workouts, My Sounds**, plus **Recently
  saved**, combining items from all three.
- **Links are a content type, not a category.** A YouTube recipe lives in My Recipes,
  an Instagram workout in My Workouts, a YouTube meditation in My Sounds.
- Each category will filter by **All · Saved · Added by me · Links** (a filter shows
  only where it applies).
- One **Add to My Collections** flow: choose Recipes, Workouts or Sounds, then the
  details. An item's category can be changed later.
- Foods are not part of Collections; there is no My Foods.

## Reuse (no duplicate recipe records)
| Content | Where it lives |
|---|---|
| Saved Moon Cycle recipes (the heart) | `saved_recipe_refs`, unchanged |
| Recipes the user wrote or pasted | `personal_recipes`, unchanged |
| Links in any category | **new** `collection_links` (below) |
| Saved Moon Cycle workouts and sounds | by reference, once those libraries exist |
| User-written workouts or sounds | later; needs its own review |

My Recipes (the existing screen) will gain the **Links** filter and show link items
beside the existing cards; it is not copied.

## Minimum new storage (next PR, not in this one)
One additive table, `collection_links` (schema v9), with the usual row columns (`id`,
`created_at`, `updated_at`, `deleted_at` tombstone):

`category` (`recipes` | `workouts` | `sounds`, changeable), `url` (http/https only,
validated), `title`, `creator` (optional), `platform` (derived from the host: YouTube,
Instagram, TikTok, Pinterest, website, other), `note` (optional).

- **Encrypted database:** the table lives in the same SQLCipher file; the migration is
  additive (`stepByStep`, a new `createTable` step), so existing rows and the key are
  untouched. A migration test from v8 with existing data will assert this.
- **Export:** the links are added to "Export my data" (JSON) with a test.
- **Delete my data:** the wiper deletes the whole database file and key, so links go
  with everything else; a test asserts the table is empty after a wipe.
- **Privacy:** URLs and notes are private; never logged; never sent anywhere; no
  scraping, previews, downloads or AI. Opening uses the system browser/app after a
  scheme check.
- **Link-only recipes are not recipes.** They are never in the recipe catalogue,
  never in "Cook with", the ingredient matcher, Meal Builder or 3 Plants results
  (those read only the catalogue and `personal_recipes`). A test asserts a recipe link
  does not change any search result. A link-only recipe can only join ingredient search
  if the user later writes structured ingredients (which makes it a normal personal
  recipe).

## Delivery
1. **Foundation (this PR, no migration):** Me rename, My Collections card, landing
   page, category pages (Workouts and Sounds honestly empty), Recently saved from the
   existing recipe stores.
2. **Saved links (separate PR, migration v9):** table, repository, Add to My
   Collections, filters, edit/delete/change category, safe open, export/delete tests.
3. **Workouts and Sounds:** each in its own PR, as reviewed content exists.

## Placeholder honesty
The canvas mockups' names and counts are fictional. Nothing here shows fake items or
a player that does nothing.
