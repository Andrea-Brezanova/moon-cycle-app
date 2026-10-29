# Publication plan for the Food Detail profiles

**Nothing is published by this plan.** All drafts stay unreviewed and outside the app until you approve them and a separate change moves them into `assets/content/food_profiles.json`. Food Detail, Build a Meal and the phase mapping are untouched.

## Where the 271 foods stand

| Group | Foods | Meaning |
|---|---|---|
| Already approved and published | 5 | Spinach, lentils, pumpkin seeds, broccoli, orange. Unchanged. |
| **Wave 1: recommended first group** | **98** | Ready, featured in a phase, every caution sourced or an allergen tag, no sodium note, no open question. |
| Ready, but not in Wave 1 | 96 | Also clean, held back for a reason listed below (not featured in a phase, sodium note, record note). Can follow in Wave 2. |
| Requires source work | 8 | Carry an inherited caution I could not source (9 more profiles also carry one but are counted under decisions). Publishable only if you accept it labelled as inherited, or after a source is found. |
| Requires your decision | 49 | Affected by one of the 13 decisions in `audit-report.md` section 3. |
| Blocked | 15 | Decision table in `audit-report.md` section 5. |
| **Total** | **271** | |

## What you need to decide to publish Wave 1 safely

These five decisions cover every Wave 1 profile; none needs a per-food judgment.

1. **Approve the five-part template and wording.** Cycle relevance reads "No cycle-phase claim is made for <food>." plus, where a serving gives 10% or more of the reference, a sourced NIH ODS sentence on iron or calcium. Opening lines are built from the recomputed numbers. (Section "Sampling sheet" shows 12 complete profiles.)
2. **Approve the cautions as written.** Every Wave 1 caution is either `sourced` (an authoritative page, named in the profile) or a `catalogue-tag` allergen line taken from `foods.json`. The list of distinct texts is in the sampling sheet and in `wave-1-candidate.json`.
3. **Approve the review label.** "Nutrition values checked against USDA and NIH sources; not clinically reviewed." (the same label the five approved profiles use).
4. **Name the reviewer and date.** An approved profile records who approved it and when; that is yours to fill in.
5. **Approve the publishing step.** After approval, a small separate change copies the approved profiles from `wave-1-candidate.json` into `assets/content/food_profiles.json` with `publishable: true`, runs CI, and then I rebuild the iPhone app. Approving a sample is not approval of a food that was not in the sample unless you say so.

Safe default if you approve nothing: no profile appears; Food Detail looks exactly as it does today.

## Wave 1 (98 profiles)

- **menstrual** (19): Beef, Beets, Black beans, Blueberry, Brussels sprouts, Cashew, Collard, Eggplant, Grapefruit, Grapes, Green bell pepper, Kale, Kidney bean, Papaya, Quinoa, Sardine, White beans, Wild rice, Yellow bell pepper
- **follicular** (23): Arugula (rocket), Avocado, Black-eyed pea, Bok choy, Cabbage, Canned salmon, Carrot, Chicken, Feta, Green pea, Haddock, Napa cabbage, Nectarine, Oat bran, Pecan, Plain yogurt, Plum, Pollock, Pomegranate, String bean, Trout, Turnip, Zucchini
- **ovulatory** (23): Almond, Apricot, Bean sprouts, Cantaloupe, Cottage cheese, Cucumber, Hazelnuts, Honeydew melon, Mandarin / tangerine, Mango, Peach, Pineapple, Pistachio, Radish, Raspberry, Red bell pepper, Red cabbage, Ricotta, Strawberry, Sugar snap peas, Sweet cherry, Tomato, Watermelon
- **luteal** (33): Apple, Artichoke, Banana, Barley, Blackberry, Buckwheat (kasha), Bulgur, Cauliflower, Chickpea, Cod, Edamame, Fig, Flounder, Goat cheese, Greek yogurt, Halibut, Lamb, Mackerel, Mixed nuts, Mozzarella, Parsnip, Peanuts, Pear, Pinto beans, Pork, Pumpkin, Salmon, Split pea, Sweet potato, Swiss cheese, Tilapia, Turkey, Walnut

## Ready but not in Wave 1 (96)

- Adzuki bean: not featured in a phase
- Almond milk: not featured in a phase
- Amaranth: not featured in a phase
- Avocado oil: not featured in a phase
- Basil: not featured in a phase
- Brazil nut: has a partly sourced caution
- Brown rice: has a partly sourced caution
- Burdock: not featured in a phase
- Canned tomatoes: not featured in a phase
- Catfish: not featured in a phase
- Celeriac: not featured in a phase
- Cheddar cheese: not featured in a phase
- Chestnut: not featured in a phase
- Chicory: not featured in a phase
- Chili pepper: not featured in a phase
- Chive: not featured in a phase
- Cilantro (coriander): not featured in a phase
- Concord grape: not featured in a phase
- Corn: not featured in a phase
- Couscous: not featured in a phase
- Cranberry: not featured in a phase
- Cream cheese: not featured in a phase
- Daikon: not featured in a phase
- Dandelion: not featured in a phase
- Date: not featured in a phase
- Dill: not featured in a phase
- Dried apricots: not featured in a phase
- Duck: not featured in a phase
- Egg noodles: not featured in a phase
- Endive: not featured in a phase
- Escarole: not featured in a phase
- Fava (broad) beans: not featured in a phase
- Garlic: not featured in a phase
- Ginger: not featured in a phase
- Great northern bean: not featured in a phase
- Guava: not featured in a phase
- Hemp seeds: not featured in a phase
- Herring: not featured in a phase
- Hickory: not featured in a phase
- Honey: not featured in a phase
- Hummus: record narrower than the catalogue name or unusual value (resolved in the text)
- Kefir: record narrower than the catalogue name or unusual value (resolved in the text)
- Kelp: not featured in a phase
- Kohlrabi: not featured in a phase
- Leek: not featured in a phase
- Lemon: not featured in a phase
- Lettuce (Bibb, Boston, romaine): record narrower than the catalogue name or unusual value (resolved in the text)
- Lime: not featured in a phase
- Lychee: not featured in a phase
- Macadamia nuts: not featured in a phase
- Maple syrup: not featured in a phase
- Millet: not featured in a phase
- Mung bean: not featured in a phase
- Mushrooms (button, shiitake): record narrower than the catalogue name or unusual value (resolved in the text)
- Mustard greens: not featured in a phase
- Navy bean: not featured in a phase
- Nut butter: record narrower than the catalogue name or unusual value (resolved in the text)
- Okra: not featured in a phase
- Olive oil: not featured in a phase
- Onion: not featured in a phase
- Parmesan: not featured in a phase
- Parsley: not featured in a phase
- Pasta: not featured in a phase
- Peppermint: not featured in a phase
- Persimmon: not featured in a phase
- Pickles: has a partly sourced caution
- Pine nut: not featured in a phase
- Pita bread (whole-wheat): not featured in a phase
- Plantain: not featured in a phase
- Popcorn (plain): not featured in a phase
- Prunes (dried plums): not featured in a phase
- Radicchio: not featured in a phase
- Raisin: not featured in a phase
- Rhubarb: not featured in a phase
- Rice cakes: not featured in a phase
- Rice noodles: not featured in a phase
- Rye bread: not featured in a phase
- Salsa: not featured in a phase; record narrower than the catalogue name or unusual value (resolved in the text)
- Scallion: not featured in a phase
- Shallot: not featured in a phase
- Soba noodles: not featured in a phase
- Sour cherry: not featured in a phase
- Sour cream: not featured in a phase
- Soy milk: not featured in a phase
- Squash: record narrower than the catalogue name or unusual value (resolved in the text)
- Tahini: not featured in a phase
- Tofu: record narrower than the catalogue name or unusual value (resolved in the text)
- Tomato paste: not featured in a phase
- Turmeric: not featured in a phase
- Vinegar: not featured in a phase
- Wakame: not featured in a phase; has a partly sourced caution
- Water chestnut: not featured in a phase
- Watercress: not featured in a phase
- White potato: record narrower than the catalogue name or unusual value (resolved in the text)
- White rice: not featured in a phase
- Whole-wheat pasta: not featured in a phase

## Requires source work (8)

- Chard: High in oxalate
- Chia seeds: Soak before eating: dry seeds swell when wet
- Ketchup: High in sugar and salt
- Kiwi: Kiwi can cause allergic reactions; people with latex allergy may also react.
- Lima bean: Always cook thoroughly
- Spirulina: Contamination risk: tested brands only; Pregnancy or autoimmune conditions: check with doctor
- Tempeh: Check the label for gluten-containing grains
- Whole-grain bread: Check the label for soy, dairy or sesame

## Requires your decision (49 profiles)

- **D1 Dry-weight servings**: Oat, Farro, Rye, Wheat, Polenta / cornmeal, Wheat flour (whole-grain), Red lentil
- **D2 Raw squid record**: Squid
- **D3 Record narrower than the catalogue name**: Sourdough bread, Snapper, Sea bass
- **D4 Tuna listed twice**: Tuna, Canned tuna
- **D5 Vitamin E left out**: Bagel, Granola
- **D6 High iron values from few data points**: Olives, Mint
- **D7 Chocolate**: Chocolate
- **D8 Moderate vitamin K**: Asparagus, Fennel
- **D9 Fat statements**: Butter, Coconut oil, Heavy cream
- **D10 Raw handling of milk and eggs**: Milk, Eggs
- **D11 How sodium appears**: Anchovies, Bacon, Bagel, Baked beans, Clam, Crab, Ham, Miso, Sauerkraut, Scallop, Shrimp, Smoked salmon, Tamari, Octopus, Naan, Lobster, Kimchi, Tortillas (wheat)
- **D12 Allergen tags broader or narrower than the food**: Coconut, Tamari, Miso, Chocolate, Granola, Bagel, Celery, Clam, Mussel, Oyster, Octopus, Scallop, Squid
- **D13 Seed foods (flax, sesame, sunflower)**: Flaxseeds, Sesame seeds, Sunflower seeds

## Blocked (15)

Alcohol (moderate), Bancha tea, Black soybean, Coffee, Decaf coffee, Dulse, Fresh-water clam, Guacamole, Hijiki, Kombu, Muesli, Oat milk, Salt, Seitan, Soft-shell crab

## Sampling sheet: 12 complete Wave 1 profiles

### Beef (`beef`, menstrual, protein)

- Record: USDA FDC 171793, "Beef, ground, 90% lean meat / 10% fat, patty, cooked, pan-broiled" (SR Legacy, 4/1/2019); serving 3 ounces cooked (USDA: 3 oz = 85 g)
- What it offers: Cooked 90% lean ground beef is a dense source of vitamin B12 (about 99% of the reference in 3 ounces), zinc (about 67%) and iron (about 13%), with about 21 g of protein.
- How to eat it: Brown for sauces, chilli and tacos, shape into burgers, or mix with grated vegetables or lentils to stretch it. Pair with vitamin C foods such as tomatoes or peppers.
- Cycle relevance: Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because of menstrual blood loss (NIH ODS). Iron from meat is absorbed more readily than iron from plant foods, so beef is an efficient source; 3 ounces provide about 2.4 mg. No phase-specific claim is made.
- Caution (sourced): Cook steaks, chops and roasts to 145 °F (62.8 °C) and let them rest for at least 3 minutes; cook ground meat to 160 °F (71.1 °C). *[USDA FSIS, Safe Minimum Internal Temperature Chart (read 2026-10-27)]*

### Arugula (rocket) (`arugula`, follicular, vegetables)

- Record: USDA FDC 169387, "Arugula, raw" (SR Legacy, 4/1/2019); serving 2 cups (USDA: 0.5 cup = 10 g)
- What it offers: Arugula (rocket) is a peppery salad leaf. Two cups give vitamin K, folate, calcium and some vitamin A for about 10 calories.
- How to eat it: Toss it raw into salads, pile it onto pizza or pasta after cooking, or blend it into pesto. Its peppery bite softens when wilted.
- Cycle relevance: Folate is a nutrient some women of childbearing age do not get enough of (NIH ODS), and leafy greens such as arugula contribute some. No cycle-phase claim is made.
- Caution (sourced): Arugula (rocket) contains vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician. *[NIH ODS Vitamin K (interaction with warfarin and other anticoagulants)]*

### Almond (`almond`, ovulatory, nuts-seeds)

- Record: USDA FDC 2346393, "Nuts, almonds, whole, raw" (Foundation, 10/28/2022); serving 30 g (USDA reference amount), a small handful
- What it offers: Almonds are a crunchy tree nut with plant protein, fibre, magnesium, iron and zinc. They are energy dense, so a small handful goes a long way.
- How to eat it: Eat as a snack, chop over porridge or salads, or blend into nut butter. Soak and peel for a milder taste in sauces.
- Cycle relevance: No cycle-phase claim is made for almond.
- Caution (sourced): Tree-nut allergen *[FDA, Food Allergies (the nine major food allergens; content current as of 03/11/2026; read 2026-10-28) (supports the existing caution)]*
- Caution (sourced): Nuts are high in oxalate. If you have had calcium oxalate kidney stones, ask a health professional how many to eat. *[NIDDK, Eating, Diet & Nutrition for Kidney Stones (lists nuts and nut products among foods to reduce for calcium oxalate stones)]*

### Apple (`apple`, luteal, fruit)

- Record: USDA FDC 171688, "Apples, raw, with skin (Includes foods for USDA's Food Distribution Program)" (SR Legacy, 4/1/2019); serving 1 medium apple (USDA: 1 medium, 3 in across = 182 g)
- What it offers: An apple is a crunchy, portable fruit with fibre (more of it in the skin) and a little vitamin C.
- How to eat it: Eat whole with the skin on, slice into salads or porridge, or bake or stew with cinnamon. Pair with nut butter for a more filling snack.
- Cycle relevance: No cycle-phase claim is made for apple.

### Beets (`beets`, menstrual, vegetables)

- Record: USDA FDC 169146, "Beets, cooked, boiled, drained" (SR Legacy, 4/1/2019); serving ½ cup sliced, cooked (USDA: 0.5 cup = 85 g)
- What it offers: Beets are a sweet, earthy root vegetable with folate and potassium.
- How to eat it: Roast or boil until tender, then slice into salads, blend into soups or dips, or grate raw into slaws.
- Cycle relevance: No cycle-phase claim is made for beets.

### Avocado (`avocado`, follicular, fruit)

- Record: USDA FDC 171705, "Avocados, raw, all commercial varieties" (SR Legacy, 4/1/2019); serving about 1/3 of an avocado (USDA NLEA serving = 50 g)
- What it offers: Avocado is a creamy, energy-dense fruit rich in unsaturated fat, with fibre, folate and potassium.
- How to eat it: Mash onto toast, slice into salads and bowls, blend into dressings or smoothies, or eat with a squeeze of lime. A third of a fruit is a typical serving.
- Cycle relevance: No cycle-phase claim is made for avocado.

### Apricot (`apricot`, ovulatory, fruit)

- Record: USDA FDC 171697, "Apricots, raw" (SR Legacy, 4/1/2019); serving 2 apricots (USDA: 1 apricot = 35 g)
- What it offers: Apricots are small, tangy-sweet fruits with vitamin A (from beta-carotene), vitamin C and potassium. Two apricots are about 34 calories.
- How to eat it: Eat fresh, halve and roast with honey or spices, or chop into grain salads and porridge.
- Cycle relevance: No cycle-phase claim is made for apricots.

### Artichoke (`artichoke`, luteal, vegetables)

- Record: USDA FDC 168386, "Artichokes, (globe or french), cooked, boiled, drained, without salt" (SR Legacy, 4/1/2019); serving 1 medium artichoke, cooked (USDA: 1 medium = 120 g, edible parts)
- What it offers: A cooked artichoke is a fibre-rich vegetable (about 6.8 g in one medium artichoke) with folate, magnesium and potassium.
- How to eat it: Steam or boil it whole until a leaf pulls out easily, dip the leaf bases in a sauce, and eat the heart. Canned or jarred hearts work in salads and pasta.
- Cycle relevance: Folate is a nutrient some women of childbearing age do not get enough of (NIH ODS); artichoke is a good source. No phase-specific claim is made.

### Black beans (`black-turtle-bean`, menstrual, legumes)

- Record: USDA FDC 175187, "Beans, black turtle, mature seeds, cooked, boiled, without salt" (SR Legacy, 4/1/2019); serving ½ cup cooked (USDA: 1 cup = 185 g)
- What it offers: Black turtle beans are small, dense, earthy beans. Half a cup gives about 7.7 g of protein and 7.7 g of fibre, with folate (20% of the reference), potassium and plant iron.
- How to eat it: Simmer into soups, stews and chilli, mash for burritos and tacos, or add to rice and salads. Canned beans, rinsed, are a shortcut.
- Cycle relevance: Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because of menstrual blood loss (NIH ODS). Black beans add plant iron, which is absorbed less readily than iron from meat; vitamin C in the same meal helps. No phase-specific claim is made.

### Black-eyed pea (`black-eyed-pea`, follicular, legumes)

- Record: USDA FDC 173759, "Cowpeas, common (blackeyes, crowder, southern), mature seeds, cooked, boiled, without salt" (SR Legacy, 4/1/2019); serving ½ cup cooked (USDA: 1 cup = 171 g)
- What it offers: Black-eyed peas are small, savoury beans with a lot of folate (about 44% of the reference in half a cup), plus magnesium, zinc, 6.6 g of protein and 5.6 g of fibre.
- How to eat it: Simmer with onion and spices, add to salads and grain bowls, or stew with greens.
- Cycle relevance: Folate is a nutrient some women of childbearing age do not get enough of (NIH ODS); Black-eyed peas are a good source. No phase-specific claim is made.

### Bean sprouts (`bean-sprouts`, ovulatory, vegetables)

- Record: USDA FDC 169957, "Mung beans, mature seeds, sprouted, raw" (SR Legacy, 4/1/2019); serving ½ cup (USDA: 1 cup = 104 g)
- What it offers: Mung bean sprouts are crisp and light, with some vitamin C and folate and about 1.6 g of protein in half a cup.
- How to eat it: Add them to stir-fries and noodle dishes at the end of cooking, or to salads and spring rolls.
- Cycle relevance: No cycle-phase claim is made for bean sprouts.
- Caution (sourced): Raw sprouts (alfalfa, bean or any other sprout) are on the FDA's list of foods to avoid if you are at greater risk of foodborne illness, for example during pregnancy, in older age or with a weakened immune system. *[FDA, People at Risk of Foodborne Illness (Foods to Avoid; content current as of 01/16/2025; read 2026-10-28)]*

### Barley (`barley`, luteal, grains)

- Record: USDA FDC 170285, "Barley, pearled, cooked" (SR Legacy, 4/1/2019); serving ½ cup cooked (USDA: 1 cup = 157 g)
- What it offers: Pearled barley is a chewy grain with fibre (about 3 g in half a cup), plus some zinc and iron.
- How to eat it: Simmer into soups and stews, cook as a risotto-style dish, or serve cooled in salads.
- Cycle relevance: No cycle-phase claim is made for barley. It contains gluten (see the caution).
- Caution (sourced): Contains gluten *[NIDDK, Celiac Disease: Eating, Diet & Nutrition (last reviewed October 2020; read 2026-10-28) (supports the existing caution)]*

