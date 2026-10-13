# App content

The app's bundled, read-only catalogue. `test/content/content_validation_test.dart` checks it in CI.

| File | What it holds | Source |
|---|---|---|
| `phases.json` | The four phases: season, tagline, Home summary, focus copy, cooking line, the universal `note`, and **25 curated foods per phase** grouped by category | Foods v2 production candidate (Moon Cycle Research) |
| `foods.json` | Every food: name, aisle, animal source, allergens, `mayContainAllergens` (check-label), synonyms, cautions, `shipReady`, and phase-specific `why` copy for the phases where it is highlighted | Foods v2 production candidate; legacy ids are kept (permanent) |
| `recipes.json` | 12 recipes in the Emergent order (unchanged; recipe replacement is a later step) | `design/content/recovered/emergent-recipes.json`, verbatim |
| `taxonomy.json` | Food categories, shopping aisles (Shop order) and the allergen chips | Foods v2 production candidate (categories now include protein, dairy & alternatives, fermented) |

## Foods v2 (content contract)

- Each phase highlights exactly **25** foods, chosen by the owner from independently researched nutrition, meal-style fit, practicality, variety and recipe suitability. Foods appear in several phases. A highlight is a suggestion, not a claim that a food is uniquely beneficial in a phase.
- Every highlighted food has **phase-specific `why` copy**; the app shows `short` on the ingredient sheet.
- Each phase carries the universal `note`, shown directly below the phase intro on Foods.
- Internal rationale labels (`evidence_informed`, `framework_informed`, `supporting`, `editorial`) and USDA provenance live in the research project (`foods.provenance.json`), never in these files.
- `mayContainAllergens` marks foods that only *may* contain an allergen (oats and gluten, kimchi and fish/shellfish). They are not shown as a permanent allergen, but the avoidance filter still leaves them out for users who avoid that allergen.
- Food ids are permanent. Foods that left the highlighted lists or the searchable catalogue are kept with `shipReady: false` (the app never shows them) so stored shopping items and avoidances still resolve. `kombu` is still used by a recipe and remains visible.

## Review status (11 October 2026)

**Draft, not reviewed — must be checked before release (allergens, animal source, aisles and synonyms below are the authored draft carried forward):**
- **Allergens.** Taken from each food's audit caution ("Soy allergen", "Contains gluten", …), plus conservative additions: miso (gluten, as some miso uses barley), chocolate (dairy, soy), coconut (tree nuts). Three recipe lines carry extra allergens: buckwheat noodles (gluten), plant milk (soy, tree nuts, gluten) and vegetable stock (gluten). Over-marking only hides more; under-marking is the safety risk.
- **Animal source** (diet filter): meat, seafood, egg; chocolate is marked dairy (conservative).
- **Aisles** (Shop grouping): vegetables, fruit, mint → Produce; meat, seafood, eggs → Protein; grains → Grains; miso, sauerkraut, pickles → Fermented; legumes, nuts and seeds, sea vegetables, dried fruit, drinks, condiments, spices → Pantry; Lychee → Produce although its category is Nuts & seeds.
- **Synonyms** for typed shopping items (courgette, aubergine, prawn, …).

**Still open from the content audit** (unchanged here): the 26 data-quality flags in `design/content/ingredients.json` and the 23 recipe flags in `design/content/RECIPE-DATA-NEEDED.md` (health claims in two intros, unlisted salt and oil, can sizes, mappings such as coconut milk → Coconut). The four `shipReady: false` foods (Hijiki, Salt, Alcohol, Ketchup) stay in the file but the app never shows them.

## Rules
- Never rewrite copy here without review. No new health or nutrition claims.
- Ids are permanent: shopping items and avoidances store them.
- Phase placement comes from the reviewed Foods v2 lists; do not edit lists or `why` copy by hand.
