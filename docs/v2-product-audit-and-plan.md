# V2 consolidated brief: audit, My Collections proposal and plan

Audited on `main` at 21415a2. Nothing in sections 2 to 7 is built yet; section 1 says
what Phase A changes.

## 1. The 13 items against the code

| # | Item | Finding | Action |
|---|---|---|---|
| 1 | Delete recipes | **Partly there.** The recipe detail page has "Delete this recipe" with a confirmation (user-created only). My recipes has no trash on the list cards. Built-in recipes cannot be deleted; a hearted one can be un-hearted. | Audit only in Phase A. Trash on the list is a small follow-up (Phase C, with Collections). |
| 2 | Recipes keeps an old search | **Reproducible.** `recipeFilterProvider` is app-wide session state; "Cook with" ingredient and meal type survive leaving and re-entering Recipes. | **Fixed in Phase A**: plain entries (Eat hub) start from normal browsing; Food detail's "Find recipes with X" keeps its context; returning from Recipe detail keeps it. Regression tests. |
| 3 | My recipes hard to find | **Reproducible.** It is only a button under the list. | **Held for your approval**: it would change the Recipes layout. Smallest option: keep the button and also place a "My recipes" link beside the filters. Nothing changed yet. |
| 4 | Meal Builder "See Premium" | **Intentional.** `Feature.buildMeal` is Premium-only (`entitlements.dart`); the launch promo grants Plus, not Premium. My iPhone installs are *release* builds, where the debug unlock is compiled out by design. | Report only. Safe test route below. |
| 5 | Food photographs | Only 3 of 271 foods have a photo (broccoli, avocado, blueberry); everything else shows an emoji or leaf tile, never a wrong photo. 40 of 112 recipes have photos. No mismatches found in code; the mapping is an explicit id table. | Inventory in `docs/food-photo-audit-v2.md` (Phase A); photos are Phase D. |
| 6 | Foods/Recipes dropdowns | **Already correct** (PR #15): one shared `EatFilterBar`, two equal-width 44 pt controls (phase, type), same type, spacing and sheet; counts update (tests added). | No code change. Please confirm on your phone. |
| 7 | Heart / Favorites | Works and persists (`saved_recipe_refs`, tap toggles, restart-safe), but the heart is only an outline whose colour changes. | **Phase A**: the saved heart is filled (same icon, same place). Integration with Collections in Phase C. |
| 8 | Shopping List phase tabs | **Reproducible.** `PhaseHeader` shows four phase tabs; they only change the colour. | **Fixed in Phase A**: plain title; items, quantities, done state, aisles untouched. |
| 9 | Space below Quick access | Bottom padding is 130 against 118 elsewhere. | **Phase A**: aligned to the tab-bar clearance used on other pages; nothing added. Please confirm on the phone. |
| 10 | Move and Relax | Placeholders (tabs are "coming soon" pages; Home cards open them). | Phase E. |
| 11 | Food-first | Foods and 3 a Day exist; the recipe matcher (`discovery`) already ranks real recipes by foods. | Phase D. |
| 12 | Daily plants repeat | **Not reproducible in the algorithm**: for the real catalogue each phase pool has 20 to 26 plants and the walk gives 3 new foods per day, no repeat until the pool is used. The only repeat risk is a pool of 3 or fewer, or a day index that does not move (late period). | **Phase A**: tests for day change, phase boundary, late period, short and long cycles, restart, small pool; and one fix if a test shows a repeat (see PR). If you still see repeats, tell me the dates and I will reproduce with your cycle. |
| 13 | External content | Not started. | Phase C. |

**Premium testing (item 4).** Run a debug build of the dev flavour on the phone
(`flutter run --flavor dev`, debug): it opens with everything unlocked and Settings
has a switch. Updating in place keeps your data, like the release install. Production
entitlements are untouched. Say if you would rather have a separate approved switch.

## 2. My Collections: what is reusable

| Existing | Reuse |
|---|---|
| `personal_recipes` (owner-scoped, origin manual/paste/generated, edit/delete) | **My Recipes stays here.** Not copied. |
| `saved_recipe_refs` (hearted recipes, by reference) | **Favorite recipes stay here.** |
| `shopping_items` | Unrelated; stays. |
| `diary_entries` / notes / activities | Stay separate (what you did). A later "log from a saved item" only *reads* a collection item. |
| `food_avoidances`, preferences | Used to filter what Collections suggests; not changed. |

So recipes do not get a second collection: the My Recipes view of Collections reads the
two existing tables.

## 3. Proposed data model (needs your approval; Phase B/C)

One **new** table, `collection_items`, for everything that is not a recipe:

`id, kind (food | workout | sound | link), ref_id (built-in id, or null), title,
url (links only, validated http/https), platform (YouTube, Instagram, TikTok,
Pinterest, website, other), category (food | movement | relaxation), note,
created_at, updated_at, deleted_at (tombstone)`, with the same `UserRow` columns and
encryption as the other tables. Additive migration (schema v9), no change to existing
rows. Links and notes are private, never logged, and included in Export my data and
Delete my data (with tests). Open the original with the system browser/app after a
scheme check (https/http only). No scraping, previews, downloads or AI.

## 4. Navigation proposal (smallest possible)

**Keep everything as it is:** bottom tabs, Home, Eat, Foods, Recipes, My Recipes and My
Diary are untouched. My Collections is **one new row in More** that opens one new page
with sections (My Foods, My Recipes, My Workouts, My Sounds, Saved links) and a simple
category filter. "My Recipes" there is a link to the existing My recipes page, not a
copy. Saving a food, workout or sound adds a small save control on those screens when
they exist. No change to primary navigation or screen hierarchy.

## 5. MVP content (small, original, reviewed)

- **Eat:** the existing 271 foods and 112 recipes; add "What can I make with these
  foods?" on 3 Plants a Day, using the existing matcher: real recipes that use the
  chosen foods, honest counts, no invented recipes, no claim that three foods make a
  complete meal.
- **Move (about 10):** 3 walks, 3 mobility/stretch sessions, 2 gentle yoga flows, 2
  beginner strength circuits; each with duration, level, equipment, plain steps and a
  safety note ("stop if it hurts; not medical advice"); text and timer, no video.
- **Relax (about 6):** 3 paced-breathing exercises with a visual pacing guide and
  timer, 2 body-scan/short-mindfulness scripts shown as text with a timer, 1 optional
  ambient sound only if a properly licensed asset exists. No audio narration until
  rights are confirmed.
- **Editorial process:** every item written by us (AI may draft), reviewed by you,
  checked for no health claims and for no copied scripts or music before it is added
  to the bundled content file; the review date is stored with the item.

## 6. Plan and PR boundaries

- **A. Urgent fixes** (this PR): items 2, 7, 8, 9, 12 tests, the audit, the photo
  audit. Item 3 waits for approval.
- **B. Architecture** (docs only): confirm sections 3 and 4. *Stops for your approval.*
- **C. My Collections:** migration v9, repository, hub, links, export/delete, plus the
  recipe-list trash (item 1). Own PR(s).
- **D. Food-first:** combinations, food saving, photos.
- **E. Move and Relax MVP:** content files, screens, saving.

## 7. Decisions needed from you

1. Approve the `collection_items` table and schema v9 (before Phase C).
2. Approve the proposal (one new row in More → My Collections; no other navigation change).
3. How to test Premium: debug dev build as proposed, or something else. No entitlement
   changes without approval.
4. Photos: AI-generated images are acceptable if reviewed; who supplies or approves them?
5. Move/Relax MVP inventory in section 5.
