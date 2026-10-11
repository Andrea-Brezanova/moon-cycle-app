# Recipe and food data: recovered, and what's still open

**Status:** 11 October 2026. Recipe data recovered from the Emergent repository.
**Source:** `github.com/Andrea-Brezanova/moon-cycle` (private), `frontend/src/data/phases.ts`, commit `374f27f`. That file labels this data **"SAMPLE CONTENT"**: Emergent generated it as sample recipes, so it needs an editorial review and a test-cook before release.

## Recovered for all 12 recipes
| Field | Status |
|---|---|
| Name, phase, stored category, display category | ✓ (matches the content audit) |
| Total time, servings | ✓ |
| Intro (one sentence) | ✓ verbatim; 2 contain health claims (see flags) |
| Full ingredient lines with quantities | ✓ 79 lines, verbatim plus parsed into amount, unit and label; 72 linked to a catalogue food |
| Method steps | ✓ 47 steps, verbatim |
| Photo | ✓ an Unsplash photo per recipe; all 12 links work (Unsplash License: free commercial use) |
| Key-ingredient tags | ✓ 74, all resolve to catalogue foods |

**Files:**
- `recovered/emergent-recipes.json`: everything above, with the source text kept next to every parsed value, plus the flags.
- `recipe-data-template/recipes.csv`, `recipe_ingredients.csv`, `recipe_steps.csv`: now filled in from the recovered data, using the Emergent recipe IDs (for example `zesty-lentil-broccoli-bowl`).

## Needs a decision (23 flags in `recovered/emergent-recipes.json`)
1. **Health claims in intros (2):** Warm Blueberry Buckwheat Porridge says "iron-supporting"; Baked Apple & Pear Millet Bowl says "to steady cravings". The content rules avoid these. Suggest describing the dish instead. Miso soup says "mineral-rich"; the audit already notes checking salt and iodine.
2. **Allergen risks (4):**
   - "buckwheat noodles" often contain wheat (gluten) but are linked to Buckwheat;
   - "plant milk" (depends on the milk);
   - "vegetable stock" (often celery);
   - "dark chocolate" (may contain milk).
3. **Ingredients used in the method but not listed (6 recipes):** salt, oil, or water/plant milk. Decide whether to add them as lines; nothing was added.
4. **Unclear amounts (4):** cans and jars without a size; no amount for chocolate.
5. **Mappings to confirm (5):**
   - cashew butter → Nut butter (the Cashew tag has no line of its own);
   - tahini → Sesame seeds;
   - coconut milk → Coconut (×2);
   - ground vs whole flaxseeds.
6. **Salt:** the "Pinch of salt" line is a seasoning, so it isn't linked to the not-ship-ready food "Salt".

## Still missing (no source anywhere)
These aren't in the Emergent app or the 2024 `mooncycle` repository, so they have to be authored and reviewed:
- **Aisle for each of the 157 foods** (Shop grouping). The 7 non-catalogue recipe lines already have an aisle hint.
- **Animal source and allergens** for every food and every non-catalogue recipe line. Needed for diet and allergy filtering; safety-relevant.
- **Synonyms** (optional), for typed shopping items.
- **Photographer credits** for the 12 Unsplash photos. Courtesy, not required; they can be collected when the photos are downloaded and bundled.

Template: `recipe-data-template/foods_shopping_and_safety.csv`. I can prepare a first pass of aisles and diet data for your review; allergens need especially careful checking.

## Other content found
The 2024 `mooncycle` repository's ingredient sheet matches the Emergent food lists, apart from spelling (for example "Pea: green" vs "Green pea"). It also has 8 "whole cycle" herbs (Agnus castus, Lady's mantle, Stinging nettle, Raspberry leaves, Shatavari, Ashwagandha, Shepherd's purse tea, Mugwort), some with medical effect notes. They were never in the app and are **not** used: the PRD lists a herbs section as a later expansion, and those claims would need careful review. Its recipe table is placeholder text.

## Rules for any change
- No new nutrition or health claims; intros describe the dish.
- Food placement per phase stays exactly as exported unless an open flag is approved.
- The 4 not-ship-ready foods stay out until approved.
