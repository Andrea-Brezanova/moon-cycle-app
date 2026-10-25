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

All 142 draft entries match an existing catalogue food by name or synonym (for example 'Lentils' is `green-lentil`, 'Mushrooms (button, shiitake)' is `mushrooms`), with **no unmatched names, no ambiguous matches, no repeats across phases, and no phase differences**: every draft phase assignment already equals the catalogue's. So no food IDs or phase assignments need to change. The full per-entry list can be regenerated from the draft with the script in this PR's description.

**What already exists and is retained:** every food's `id`, `name`, `category`, `aisle`, `allergens`, `synonyms`, `cautions` (for example spinach's oxalate and warfarin notes), the per-phase `why.short/detail` reason, recipes, shopping and filters. **How Food Detail renders today:** a title and category, an optional phase pill, one 'Why this food?' paragraph (`why.short`) or 'About this food', a 'Good to know' box from `cautions`, then Find recipes, Add to shopping list and Log actions.

## 2. Smallest compatible schema extension (proposal)

Add one **new** file, `assets/content/food_profiles.json`, keyed by existing food id, and leave `foods.json` untouched. Each record: `reviewStatus` (`draft` | `verified` | `approved`), `sections` (`whatItOffers`, `practicalServing`, `howToEatIt`, `cycleRelevance`), `servingGrams`, `nutrients[]` (`name`, `amount`, `unit`, `percentOfReference`, `referenceLabel`), `source` (`usdaFdcId`, description, data type, published date, access date), `cautions[]` (each with its source) and `evidence`. A `FoodProfile` model is loaded next to the catalogue; **Food Detail shows the five-section block only for foods whose profile is `approved`**, and otherwise looks exactly as now. This keeps unverified records out of production by construction, preserves the layout (the sections sit under 'Why this food?' in the existing text style), and needs no database change. 'Key nutrients' is rendered from `nutrients[]`; 'Daily intake' is shown only as a percent of a verified reference for adults, labelled as a reference for the nutrient, never as a food requirement.

## 3. Method and sources (Phase 2)

- **Composition:** USDA FoodData Central, the SR Legacy records below, read on fdc.nal.usda.gov on 2026-10-25 (per 100 g, and the household measures USDA lists). Nothing was estimated; where a value is not available it is left out.
- **Reference intakes and statements:** NIH Office of Dietary Supplements fact sheets (Iron, Folate, Vitamin C, Vitamin K, Magnesium, Zinc, Potassium, Vitamin A), read 2026-10-25. Reference values are for **adult women aged 19 to 50** and describe the nutrient, not a need to eat one food every day.
- **Cross-check:** the app's per-serving numbers agree with the ODS food tables where both list the same food and serving (spinach iron 3 mg and folate 131 µg per ½ cup boiled; lentils iron 3 mg and zinc 1.3 mg per ½ cup; broccoli vitamin C 51 mg and vitamin K 110 µg per ½ cup cooked; orange vitamin C 70 mg).

## 4. The five reference profiles (Phase 4)

### Spinach (`spinach`)

**Source:** USDA FDC 168463, "Spinach, cooked, boiled, drained, without salt" (SR Legacy, published 4/1/2019). **Serving:** ½ cup cooked (1 cup = 180 g).

**What this food offers.** Spinach is a leafy green that cooks down to a small, soft portion rich in folate, magnesium and vitamin K, and it contributes some plant iron.

**Key nutrients** (per serving: 21 kcal, protein 2.7 g, fat 0.2 g, carbohydrate 3.4 g, fibre 2.2 g):

- Iron: 3.2 mg (18% of RDA, women 19–50 (NIH ODS Iron))
- Folate: 131 µg (33% of RDA, women 19+ (NIH ODS Folate))
- Magnesium: 78 mg (25% of RDA, women 19–30 is 310 mg, 31–50 is 320 mg (NIH ODS Magnesium); 310 used)
- Vitamin K: 445 µg (494% of AI, women 19+ (NIH ODS Vitamin K))
- Vitamin A: 472 µg RAE (67% of RDA, women 19–50 (NIH ODS Vitamin A))

**A practical serving.** ½ cup cooked (1 cup = 180 g)

**How to eat it.** Wilt it into soups, stews, omelettes or pasta, or stir it through warm lentils. A squeeze of lemon or a piece of orange alongside helps your body absorb the iron.

**Cycle relevance.** Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because menstrual blood loss increases iron losses (NIH ODS). Spinach is one plant source of iron, and plant (non-heme) iron is absorbed less easily; vitamin C eaten with it helps. This is general nutrition for anyone who menstruates, not a claim that spinach changes your cycle. If your periods are heavy, it is worth talking to a health professional rather than relying on food alone.

**Good to know:** High in oxalate _(source: existing catalogue text, retained; not re-verified in this pass)_; Very high in vitamin K: keep intake consistent if you take warfarin or a similar blood thinner _(source: NIH ODS Vitamin K (interaction with warfarin))_

_Evidence:_ Established requirement and iron-loss statement (NIH ODS). No food-specific trial of spinach and the menstrual cycle was used.  
_Status:_ composition verified (USDA), reference intakes verified (NIH ODS), editorial **pending your approval**, clinical review not done.

### Lentils (`green-lentil`)

**Source:** USDA FDC 172421, "Lentils, mature seeds, cooked, boiled, without salt" (SR Legacy, published 4/1/2019). **Serving:** ½ cup cooked (1 cup = 198 g).

**What this food offers.** Lentils are a filling, budget-friendly pulse that brings protein, fibre, folate and iron in one bowl.

**Key nutrients** (per serving: 115 kcal, protein 8.9 g, fat 0.4 g, carbohydrate 19.9 g, fibre 7.8 g):

- Iron: 3.3 mg (18% of RDA, women 19–50 (NIH ODS Iron))
- Folate: 179 µg (45% of RDA, women 19+ (NIH ODS Folate))
- Zinc: 1.3 mg (16% of RDA, women 19+ (NIH ODS Zinc))
- Potassium: 365 mg (14% of AI, women 19–50 (NIH ODS Potassium))

**A practical serving.** ½ cup cooked (1 cup = 198 g)

**How to eat it.** Simmer into soups and dals, cool for salads, or fold into grain bowls. Pair them with something rich in vitamin C, such as peppers, tomatoes or citrus; beans and grains contain phytate, which makes minerals harder to absorb, and vitamin C works the other way (NIH ODS).

**Cycle relevance.** Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because menstrual blood loss increases iron losses (NIH ODS). Lentils supply plant iron, and eating them with vitamin C foods can help. They also provide folate, a nutrient some women of childbearing age do not get enough of (NIH ODS). General nutrition, not a phase-specific treatment. If your periods are heavy, it is worth talking to a health professional rather than relying on food alone.

_Evidence:_ Established requirements and absorption statements (NIH ODS). No lentil-specific cycle trial used.  
_Status:_ composition verified (USDA), reference intakes verified (NIH ODS), editorial **pending your approval**, clinical review not done.

### Pumpkin seeds (`pumpkin-seeds`)

**Source:** USDA FDC 170556, "Seeds, pumpkin and squash seed kernels, dried" (SR Legacy, published 4/1/2019). **Serving:** 1 ounce (28 g) (1 cup = 129 g).

**What this food offers.** Pumpkin seeds (pepitas) are a crunchy, energy-dense source of magnesium, zinc, iron and plant protein.

**Key nutrients** (per serving: 158 kcal, protein 8.6 g, fat 13.9 g, carbohydrate 3.0 g, fibre 1.7 g):

- Magnesium: 168 mg (54% of RDA, women 19–30 is 310 mg, 31–50 is 320 mg (NIH ODS Magnesium); 310 used)
- Zinc: 2.2 mg (28% of RDA, women 19+ (NIH ODS Zinc))
- Iron: 2.5 mg (14% of RDA, women 19–50 (NIH ODS Iron))

**A practical serving.** 1 ounce (28 g) (1 cup = 129 g)

**How to eat it.** Scatter over porridge, yoghurt, soups or salads, or blend into a dressing or pesto. A little goes a long way, as they are rich in fat and calories.

**Cycle relevance.** Magnesium and zinc are part of an everyday balanced diet. We found no reliable evidence tying pumpkin seeds to a particular cycle phase or to relief of period symptoms, so they are here as one tasty source of minerals, not as a remedy. Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because menstrual blood loss increases iron losses (NIH ODS). The iron they provide is plant (non-heme) iron.

_Evidence:_ Nutrient amounts and references verified (USDA, NIH ODS). No cycle-specific claim made.  
_Status:_ composition verified (USDA), reference intakes verified (NIH ODS), editorial **pending your approval**, clinical review not done.

### Broccoli (`broccoli`)

**Source:** USDA FDC 169967, "Broccoli, cooked, boiled, drained, without salt" (SR Legacy, published 4/1/2019). **Serving:** ½ cup chopped, cooked (78 g).

**What this food offers.** Broccoli is a green vegetable with plenty of vitamin C and vitamin K, plus folate and fibre.

**Key nutrients** (per serving: 27 kcal, protein 1.9 g, fat 0.3 g, carbohydrate 5.6 g, fibre 2.6 g):

- Vitamin C: 51 mg (67% of RDA, women 19+ (NIH ODS Vitamin C))
- Vitamin K: 110 µg (122% of AI, women 19+ (NIH ODS Vitamin K))
- Folate: 84 µg (21% of RDA, women 19+ (NIH ODS Folate))
- Potassium: 229 mg (9% of AI, women 19–50 (NIH ODS Potassium))

**A practical serving.** ½ cup chopped, cooked (78 g)

**How to eat it.** Steam, roast or stir-fry until just tender. Serve it with beans, lentils or other plant iron foods: its vitamin C helps your body absorb the iron from them.

**Cycle relevance.** Vitamin C improves the absorption of non-heme iron, the form found in plant foods (NIH ODS). Broccoli has little iron of its own, so its role is as a companion to iron-rich plant foods in the same meal, relevant to everyone who menstruates (iron needs are higher for women 19–50, partly from menstrual blood loss). General nutrition, not a phase-specific treatment.

**Good to know:** Rich in vitamin K: keep intake consistent if you take warfarin or a similar blood thinner _(source: NIH ODS Vitamin K)_

_Evidence:_ Absorption and requirement statements from NIH ODS; no broccoli-specific cycle trial used.  
_Status:_ composition verified (USDA), reference intakes verified (NIH ODS), editorial **pending your approval**, clinical review not done.

### Orange (`orange`)

**Source:** USDA FDC 169097, "Oranges, raw, all commercial varieties" (SR Legacy, published 4/1/2019). **Serving:** 1 fruit (2⅝ in diameter, 131 g).

**What this food offers.** An orange is a juicy, portable fruit that is an excellent source of vitamin C, with some folate and fibre.

**Key nutrients** (per serving: 62 kcal, protein 1.2 g, fat 0.2 g, carbohydrate 15.5 g, fibre 3.1 g):

- Vitamin C: 70 mg (93% of RDA, women 19+ (NIH ODS Vitamin C))
- Folate: 39 µg (10% of RDA, women 19+ (NIH ODS Folate))
- Potassium: 237 mg (9% of AI, women 19–50 (NIH ODS Potassium))

**A practical serving.** 1 fruit (2⅝ in diameter, 131 g)

**How to eat it.** Eat it whole or in segments, add to salads, or squeeze over cooked greens and lentils. Having one with an iron-rich plant meal helps your body absorb the iron.

**Cycle relevance.** Vitamin C improves the absorption of non-heme iron from plant foods (NIH ODS), which is why an orange pairs well with lentils or spinach. Iron needs are higher for women 19–50, partly because of menstrual blood loss. General nutrition, not a claim that oranges change your cycle.

_Evidence:_ Absorption and requirement statements from NIH ODS; no orange-specific cycle trial used.  
_Status:_ composition verified (USDA), reference intakes verified (NIH ODS), editorial **pending your approval**, clinical review not done.

## 5. Open points for your decision

1. **Record choice:** I used USDA SR Legacy entries (frozen since 2019) because they have household measures and match the ODS tables; Foundation entries are newer for some foods (for example broccoli, raw: 747447). Prefer Foundation where it exists?
2. **Vitamin K percentages** look dramatic (spinach about 5 times the adequate intake). They are correct for these entries; we show the amount and the warfarin note, not a percentage, unless you prefer otherwise.
3. **Fibre** has no reference value from ODS, so it is shown as an amount only.
4. **'High in oxalate'** on spinach is retained from the existing catalogue and was not re-verified in this pass.
5. **Pumpkin seeds:** the record is the dried kernel; ODS tables list roasted seeds (magnesium 156 mg per ounce versus 168 mg here). The profile says which one it describes.
6. **Phase wording:** all five are in the menstrual phase today and the cycle relevance is the same general iron-and-absorption statement, not a phase-specific benefit. If you want something different for a food, there is no human-evidence basis in what I checked.
7. **The 142 JSON file** (`moon_cycle_142_food_profiles_draft.json`) was not provided, only the markdown. The mapping above used the markdown.

Machine-readable version: `docs/food-profiles/reference-profiles.json`. Next, after your approval: the schema extension and a first reviewed batch, each in its own PR.
