# App content

The app's bundled, read-only catalogue. These files are both the **source** (edit them here, through review) and what ships in the app. `test/content/content_validation_test.dart` checks them in CI.

| File | What it holds | Source |
|---|---|---|
| `phases.json` | The four phases: season, tagline, Home summary, focus copy, cooking line, and the foods per category **in the Emergent order** | `design/content/sample-content.json` and `ingredients.json` › `phases`, verbatim |
| `foods.json` | 157 foods: name, ingredient-sheet copy per phase (`why`), cautions, `shipReady`, plus aisle, animal source, allergens and synonyms | Copy, cautions, `shipReady`: `design/content/ingredients.json`, verbatim. Aisle, animal source, allergens, synonyms: **authored draft**, see below |
| `recipes.json` | 12 recipes in the Emergent order: time, servings, intro, ingredient lines with quantities, key foods, steps, photo link | `design/content/recovered/emergent-recipes.json`, verbatim (Emergent labelled it sample content) |
| `taxonomy.json` | Food categories, shopping aisles (Shop order) and the allergen chips | Spec §7 and the onboarding / Allergies screens |

## Review status (11 October 2026)

**Draft, not reviewed — must be checked before release:**
- **Allergens.** Taken from each food's audit caution ("Soy allergen", "Contains gluten", …), plus conservative additions: miso (gluten, as some miso uses barley), chocolate (dairy, soy), coconut (tree nuts). Three recipe lines carry extra allergens: buckwheat noodles (gluten), plant milk (soy, tree nuts, gluten) and vegetable stock (gluten). Over-marking only hides more; under-marking is the safety risk.
- **Animal source** (diet filter): meat, seafood, egg; chocolate is marked dairy (conservative).
- **Aisles** (Shop grouping): vegetables, fruit, mint → Produce; meat, seafood, eggs → Protein; grains → Grains; miso, sauerkraut, pickles → Fermented; legumes, nuts and seeds, sea vegetables, dried fruit, drinks, condiments, spices → Pantry; Lychee → Produce although its category is Nuts & seeds.
- **Synonyms** for typed shopping items (courgette, aubergine, prawn, …).

**Still open from the content audit** (unchanged here): the 26 data-quality flags in `design/content/ingredients.json` and the 23 recipe flags in `design/content/RECIPE-DATA-NEEDED.md` (health claims in two intros, unlisted salt and oil, can sizes, mappings such as coconut milk → Coconut). The four `shipReady: false` foods (Hijiki, Salt, Alcohol, Ketchup) stay in the file but the app never shows them.

## Rules
- Never rewrite copy here without review. No new health or nutrition claims.
- Ids are permanent: shopping items and avoidances store them.
- Phase placement must match the Emergent export exactly; the validation test compares it with `design/content/sample-content.json`.
