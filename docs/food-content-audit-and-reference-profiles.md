# Food content: mapping audit and five reference profiles

**Status: for your editorial review. Nothing here is in the app. No interface or production content was changed.**

## 1. Mapping audit (Phase 1)

Source: `moon_cycle_142_food_profiles_editorial_draft.md`. The companion `moon_cycle_142_food_profiles_draft.json` was not among the files provided (only the markdown, and a different 30-food `moon_cycle_food_library_v0_1.json`). Catalogue: `assets/content/foods.json` (271 foods) and the phase lists in `assets/content/phases.json`. Nothing was changed.

**142 entries**: menstrual 35, follicular 32, ovulatory 31, luteal 44 (matches the stated 35 / 32 / 31 / 44).

## Result
- Exact name or synonym match: **142**
- Matched by base name or plural form: **0**
- Ambiguous or partial (needs your decision): **0**
- No catalogue match: **0**
- Matched foods that the draft puts in a different phase than the catalogue: **0** (not changed)
- Foods repeated across phases in the draft: **0**

All 142 draft entries match an existing catalogue food by name or synonym (for example 'Lentils' is `green-lentil`, 'Mushrooms (button, shiitake)' is `mushrooms`), with **no unmatched names, no ambiguous matches, no repeats across phases, and no phase differences**: every draft phase assignment already equals the catalogue's. So no food IDs or phase assignments need to change. The per-entry list is in `docs/food-profiles/mapping-142.json`, produced by `docs/food-profiles/mapping_audit.py`.

**What already exists and is retained:** every food's `id`, `name`, `category`, `aisle`, `allergens`, `synonyms`, `cautions` (for example spinach's oxalate and warfarin notes), the per-phase `why.short/detail` reason, recipes, shopping and filters. **How Food Detail renders today:** a title and category, an optional phase pill, one 'Why this food?' paragraph (`why.short`) or 'About this food', a 'Good to know' box from `cautions`, then Find recipes, Add to shopping list and Log actions.

## 2. Smallest compatible schema extension (proposal)

Add one **new** file, `assets/content/food_profiles.json`, keyed by existing food id, and leave `foods.json` untouched. Each record: `reviewStatus` (`draft` | `verified` | `approved`), `sections` (`whatItOffers`, `practicalServing`, `howToEatIt`, `cycleRelevance`), `servingGrams`, `nutrients[]` (`name`, `amount`, `unit`, `percentOfReference`, `referenceLabel`), `source` (`usdaFdcId`, description, data type, published date, access date), `cautions[]` (each with its source) and `evidence`. A `FoodProfile` model is loaded next to the catalogue; **Food Detail shows the five-section block only for foods whose profile is `approved`**, and otherwise looks exactly as now. This keeps unverified records out of production by construction, preserves the layout (the sections sit under 'Why this food?' in the existing text style), and needs no database change. 'Key nutrients' is rendered from `nutrients[]`; 'Daily intake' is shown only as a percent of a verified reference for adults, labelled as a reference for the nutrient, never as a food requirement.

## 3. Revision after your review (all nine points)

1. **Five sections and the per-serving amounts are kept.** Amounts are recomputed from the exact records below.
2. **Exact USDA records, preparation state and household portions** are stated for each food and are never mixed (cooked values for spinach, lentils and broccoli; raw for the orange; the edible dried kernel for pumpkin seeds). Following your decisions: spinach, lentils and broccoli are the **cooked** SR Legacy records (USDA has no cooked Foundation record for them); pumpkin seeds are the edible dried seed-kernel record; the orange is the current **Foundation** raw navel record. Each entry says why.
3. **Age-appropriate references.** Percentages use NIH ODS values for adult women, with the age group stated. Magnesium shows **both** groups (RDA 310 mg for 19–30 y and 320 mg for 31–50 y); the other nutrients have one value for 19–50 y. Each profile carries one line saying the percentage compares a serving with the daily reference for the **nutrient**; it is **not a recommended portion** of the food.
4. **Vitamin K** is shown as an amount only, with the blood-thinner note, never as a percentage.
5. **Cycle relevance** is now two sentences at most and differs by food only where the evidence does: spinach (iron needs and menstrual loss), lentils (points to spinach, adds folate), pumpkin seeds, broccoli and orange (an explicit "no evidence tying it to a phase" plus the vitamin C and iron-absorption pairing).
6. **Cautions verified:** spinach oxalate against NIDDK's kidney-stone guidance (it lists spinach among foods to limit after calcium oxalate stones; the same page calls beans and lentils low in oxalate); vitamin K and warfarin against NIH ODS. Lentils, pumpkin seeds and orange have no caution I could source, so none is shown.
7. **Nothing is integrated.** Food IDs, phase mappings and the Food Detail design are untouched; this PR is documentation only.
8. **Traceability:** each record has its FDC id, data type, publication date, preparation state and portion; reference sources and read dates are in the JSON. `docs/food-profiles/build_reference_profiles.py` regenerates it.
9. **Review labels:** every profile says *nutrition data verified against USDA and NIH sources; editorial review pending; not clinically reviewed.* None is described as clinically reviewed.

## 4. The five final profiles

### Spinach (`spinach`)

**Record:** USDA FDC 168463, "Spinach, cooked, boiled, drained, without salt" (SR Legacy, 4/1/2019), cooked, boiled, drained, no salt. _USDA has no cooked-spinach Foundation record (only raw baby and mature); the SR Legacy cooked record is the current cooked one and matches the way spinach is usually eaten and the existing catalogue wording._

**What this food offers.** Spinach is a leafy green that cooks down to a small, soft portion with folate, magnesium and vitamin A, and some plant iron.

**Key nutrients** per serving (½ cup cooked (USDA: 1 cup = 180 g)): 21 kcal, protein 2.7 g, fat 0.2 g, carbohydrate 3.4 g, fibre 2.2 g.

- Iron: 3.2 mg, 18% of 18 mg (19–50 y, RDA)
- Folate: 131 µg DFE, 33% of 400 µg DFE (19–50 y, RDA)
- Magnesium: 78 mg, 25% of 310 mg (19–30 y, RDA) / 24% of 320 mg (31–50 y, RDA)
- Vitamin A: 472 µg RAE, 67% of 700 µg RAE (19–50 y, RDA)
- Vitamin K: 445 µg (amount only; Adequate intake for women 19 and over is 90 µg; shown as an amount only. See the note on blood thinners.)

_Percentages describe the nutrient's daily reference, not a recommended portion of this food._

**A practical serving.** ½ cup cooked (USDA: 1 cup = 180 g)

**How to eat it.** Wilt it into soups, stews, omelettes or pasta, or stir it through warm lentils. Squeeze lemon over it or add a piece of orange to the meal: vitamin C helps your body absorb the iron.

**Cycle relevance.** Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because menstrual blood loss increases iron losses (NIH ODS). Spinach adds plant iron, which is absorbed less readily than iron from meat; vitamin C eaten with it helps. If your periods are heavy, it is worth talking to a health professional.

**Good to know:** Spinach is high in oxalate. If you have had calcium oxalate kidney stones, ask a health professional how much to eat. _(source: NIDDK, Eating, Diet & Nutrition for Kidney Stones (lists spinach among foods to avoid after calcium oxalate stones))_; Spinach is high in vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician. _(source: NIH ODS Vitamin K (interaction with warfarin and other anticoagulants))_

_Evidence:_ Iron requirement, menstrual loss and absorption: NIH ODS Iron. No spinach-specific cycle trial was used.  
_Status:_ Nutrition data verified against USDA and NIH sources; editorial review pending; not clinically reviewed.

### Lentils (`green-lentil`)

**Record:** USDA FDC 172421, "Lentils, mature seeds, cooked, boiled, without salt" (SR Legacy, 4/1/2019), cooked, boiled, no salt. _USDA has only a dry lentil Foundation record; the SR Legacy cooked record is the cooked one, and it has household measures._

**What this food offers.** Lentils are a filling, budget-friendly pulse with protein, fibre, folate and iron in one bowl.

**Key nutrients** per serving (½ cup cooked (USDA: 1 cup = 198 g)): 115 kcal, protein 8.9 g, fat 0.4 g, carbohydrate 19.9 g, fibre 7.8 g.

- Iron: 3.3 mg, 18% of 18 mg (19–50 y, RDA)
- Folate: 179 µg DFE, 45% of 400 µg DFE (19–50 y, RDA)
- Zinc: 1.3 mg, 16% of 8 mg (19–50 y, RDA)
- Potassium: 365 mg, 14% of 2600 mg (19–50 y, AI)

_Percentages describe the nutrient's daily reference, not a recommended portion of this food._

**A practical serving.** ½ cup cooked (USDA: 1 cup = 198 g)

**How to eat it.** Simmer into soups and dals, cool for salads, or fold into grain bowls. Serve with something rich in vitamin C, such as peppers, tomatoes or citrus: beans contain phytate, which makes minerals harder to absorb, and vitamin C works the other way.

**Cycle relevance.** Like spinach, lentils add plant iron (see Spinach for why iron matters to people who menstruate), and they are also a source of folate, a nutrient some women of childbearing age do not get enough of (NIH ODS).

_Evidence:_ Iron absorption and folate intake statements: NIH ODS Iron and Folate. No lentil-specific cycle trial was used.  
_Status:_ Nutrition data verified against USDA and NIH sources; editorial review pending; not clinically reviewed.

### Pumpkin seeds (`pumpkin-seeds`)

**Record:** USDA FDC 170556, "Seeds, pumpkin and squash seed kernels, dried" (SR Legacy, 4/1/2019), dried edible kernels (hulled), unsalted. _The USDA record for the edible seed kernel (the hulled pepita), with an ounce household measure. The Foundation raw-pepitas record gives only a 30 g reference amount, so this record is the clearer match for the serving shown._

**What this food offers.** Pumpkin seeds (pepitas) are a crunchy, energy-dense source of magnesium, zinc, iron and plant protein.

**Key nutrients** per serving (1 ounce (28 g) of kernels (USDA: 1 cup = 129 g)): 158 kcal, protein 8.6 g, fat 13.9 g, carbohydrate 3.0 g, fibre 1.7 g.

- Magnesium: 168 mg, 54% of 310 mg (19–30 y, RDA) / 52% of 320 mg (31–50 y, RDA)
- Zinc: 2.2 mg, 28% of 8 mg (19–50 y, RDA)
- Iron: 2.5 mg, 14% of 18 mg (19–50 y, RDA)

_Percentages describe the nutrient's daily reference, not a recommended portion of this food._

**A practical serving.** 1 ounce (28 g) of kernels (USDA: 1 cup = 129 g)

**How to eat it.** Scatter over porridge, yoghurt, soups or salads, or blend into a dressing or pesto. A little goes a long way: they are rich in fat and energy.

**Cycle relevance.** We found no reliable evidence linking pumpkin seeds to a cycle phase or to period symptoms. They are here as one source of magnesium and zinc, as part of a varied diet.

_Evidence:_ Nutrient amounts and reference intakes only. No cycle-specific claim is made.  
_Status:_ Nutrition data verified against USDA and NIH sources; editorial review pending; not clinically reviewed.

### Broccoli (`broccoli`)

**Record:** USDA FDC 169967, "Broccoli, cooked, boiled, drained, without salt" (SR Legacy, 4/1/2019), cooked, boiled, drained, no salt. _The cooked record, as broccoli is usually eaten and as NIH ODS lists it (cooked, ½ cup). USDA has no cooked-broccoli Foundation record. The raw Foundation record (747447) is not mixed in: all amounts here are cooked._

**What this food offers.** Broccoli is a green vegetable with plenty of vitamin C and vitamin K, plus folate and fibre.

**Key nutrients** per serving (½ cup chopped, cooked (78 g)): 27 kcal, protein 1.9 g, fat 0.3 g, carbohydrate 5.6 g, fibre 2.6 g.

- Vitamin C: 51 mg, 67% of 75 mg (19–50 y, RDA)
- Vitamin K: 110 µg (amount only; Adequate intake for women 19 and over is 90 µg; shown as an amount only. See the note on blood thinners.)
- Folate: 84 µg DFE, 21% of 400 µg DFE (19–50 y, RDA)
- Potassium: 229 mg, 9% of 2600 mg (19–50 y, AI)

_Percentages describe the nutrient's daily reference, not a recommended portion of this food._

**A practical serving.** ½ cup chopped, cooked (78 g)

**How to eat it.** Steam, roast or stir-fry it until just tender. Serve it with beans, lentils or other plant iron foods: its vitamin C helps your body absorb the iron from them.

**Cycle relevance.** We found no evidence tying broccoli to a particular phase. Its vitamin C helps your body absorb plant iron from the same meal (NIH ODS), a useful pairing for anyone who menstruates.

**Good to know:** Broccoli contains vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician. _(source: NIH ODS Vitamin K (interaction with warfarin and other anticoagulants))_

_Evidence:_ Absorption statement: NIH ODS Vitamin C and Iron. No broccoli-specific cycle trial was used.  
_Status:_ Nutrition data verified against USDA and NIH sources; editorial review pending; not clinically reviewed.

### Orange (`orange`)

**Record:** USDA FDC 746771, "Oranges, raw, navels" (Foundation, 12/16/2019), raw, flesh only. _The current Foundation record for an orange (navel, raw) with a household measure; it replaces the generic SR Legacy "all commercial varieties" record._

**What this food offers.** An orange is a juicy, portable fruit that is an excellent source of vitamin C, with some folate and fibre.

**Key nutrients** per serving (1 orange (about 2⅞ in across, 140 g)): 66 kcal, protein 1.3 g, fat 0.2 g, carbohydrate 16.5 g, fibre 2.8 g.

- Vitamin C: 83 mg, 110% of 75 mg (19–50 y, RDA)
- Folate: 35 µg DFE, 9% of 400 µg DFE (19–50 y, RDA)
- Potassium: 232 mg, 9% of 2600 mg (19–50 y, AI)

_Percentages describe the nutrient's daily reference, not a recommended portion of this food._

**A practical serving.** 1 orange (about 2⅞ in across, 140 g)

**How to eat it.** Eat it whole or in segments, add to salads, or squeeze over cooked greens and lentils. Having one with an iron-rich plant meal helps your body absorb the iron.

**Cycle relevance.** We found no evidence tying oranges to a particular phase. Vitamin C improves the absorption of plant iron (NIH ODS), so an orange pairs well with lentils or spinach.

_Evidence:_ Absorption statement: NIH ODS Vitamin C and Iron. No orange-specific cycle trial was used.  
_Status:_ Nutrition data verified against USDA and NIH sources; editorial review pending; not clinically reviewed.

## 5. Status

Preparations are approved as above. Awaiting final editorial review of the wording. The Food Detail preview is in draft PR #33 (not for merge). Machine-readable: `docs/food-profiles/reference-profiles.json`.
