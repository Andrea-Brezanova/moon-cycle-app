# Add a Recipe: migration, security and licensing review

Done before implementation, as required. Decision (owner): **manual entry first, then paste-text, then URL import**, each as its own PR when the risk warrants it.

## What exists (inspected)
- `personal_recipes` table: a user's recipes stored as JSON in the app's own `Recipe` shape (title, category, minutes, serves, intro, ingredients with optional catalogue `food_id`, steps), with an owner id, an idempotency key, provenance and a lifecycle (`privateSaved` by default; only an explicit "Suggest to Moon Cycle" for server-backed recipes moves it on). Today only the generation flow writes it, and only for a development session, so in a normal build **no personal recipe can exist and the list is empty**.
- My recipes already has "Saved" (hearts) and "Added by me" (personal recipes); Log a meal already offers the user's own recipes; the shopping list already takes a recipe's ingredients; recipe detail already shows and deletes personal recipes; dietary filters (`allowsRecipe`) read each ingredient's catalogue food.
- Saved references (`saved_recipe_refs`) hold only an id, title and source link for outside recipes, because the provider terms (TheMealDB) do not let us keep their ingredients or method.

## 1. Manual recipes: no schema migration needed
The existing table already holds everything a typed recipe needs. A manual recipe is a row with a fixed local owner id (`local`, not tied to any account, so it works without sign-in) and provenance origin `manual` (a new enum value; stored as text, so additive). **No new table, no column, no migration, nothing existing changes.** Consequences handled in code:
- The owner-scoped queries become "the local owner plus the signed-in user (if any)", so generated recipes still show only for their own session.
- Typed recipes are never submitted anywhere: the "Suggest to Moon Cycle" action needs a server id and a non-sample origin, which a manual recipe never has. Lifecycle stays `privateSaved`.
- Export my data includes them (they are the user's writing); Delete my data wipes the database file.
- Recipe fields that a typed recipe may not have (time, servings) are stored as 0 and simply not shown; "why this phase" is left empty (no phase claim is made for a user's own recipe).

## Dietary restrictions and safety
Ingredients the user types are matched to catalogue foods by name where possible (so the aisle and the allergen/diet filters work for those lines); unmatched lines are kept as written and **cannot be checked**. The detail screen says so plainly. No allergen, nutrition or health claim is generated for a user's own recipe.

## 2. Paste-text import (next PR)
Purely local: the user pastes text, the app splits it into a title, ingredient lines and steps in an editable draft, and nothing is saved until the user reviews and saves. No network, no third party. The text is the user's own copy for private use; an optional "Source" field lets them note where it came from. Parsing is best-effort and always reviewable; nothing is invented.

## 3. URL import: needs the owner's approval before it is built
Risks and questions to settle first:
- **Privacy**: fetching a page from the phone tells that site (and any trackers it loads) the user's IP address and that they looked at that recipe. Fetch only the page, no scripts, no cookies, no referrer; user must tap Import.
- **Untrusted content**: parse structured `schema.org/Recipe` data only (JSON-LD), cap size and time, never render fetched HTML, never follow redirects off `https`, reject private/local addresses.
- **Licensing**: recipe prose, method text and photos are usually copyrighted and many sites' terms restrict copying or automated access. Storing a private copy of a publisher's method may not be allowed even for personal use. Our own rule for TheMealDB (keep only title and link) shows the conservative option: save the title, the user's own ingredient list and a link, and **not** copy the method text or images. Needs an allow-list of sites with permissive terms, or a decision to keep only title + ingredients + attribution link.
- **Attribution**: always keep and show the source URL and site name; no claim of authorship.
- This is not "enabling a third-party recipe service" (no API key, no provider), but it is the licensing question that the owner asked to approve first. **URL import will not be implemented until that decision is made.**
