# Food profile quality audit: consolidated review package

Nothing here is published. All 251 drafts remain unreviewed and outside the app; the 5 approved profiles are unchanged.

## Exact totals

| | Count |
|---|---|
| Catalogue foods | 271 |
| Approved and published (unchanged) | 5 |
| Drafted, unreviewed, unpublished | 251 |
| Blocked | 15 |
| Missing | 0 |
| Drafts marked publishable | 0 |

## What was checked, and how

1. **Source identity, preparation, serving and amounts (all 251).** `audit_profiles.py` re-fetches every cited USDA FoodData Central record and compares: FDC id, description, publication date, every stored per-100 g value (including sodium), the serving weight against the record's household measures, and every per-serving amount and reference-intake percentage. **Result: 0 open findings.** Two serving texts (chestnut, cottage cheese) were reviewed and accepted with reasons recorded in the script. No USDA value had been mis-copied.
2. **Prose (all 251).** Every section was read. Fixed: boilerplate cycle text, grammar slips, filler and promotional wording, robotic opening lines, awkward serving text, a unit-grammar bug ("1 calories").
3. **Claims.** Cycle relevance makes no hormone, fertility, PMS or phase-specific benefit claim in any profile. Where a nutrient has a sourced reference (iron and menstrual blood loss, calcium, folate, vitamin C with plant iron), the sentence says so with its NIH ODS source.
4. **Safety and allergens.** Allergen tags from the catalogue are now carried on every profile and shown in its cautions (parity is tested). Sourced cautions were added only after the source page was read: sodium (FDA, Dietary Guidelines), raw sprouts, smoked fish, deli ham and unpasteurised cheeses (FDA People at Risk of Foodborne Illness), honey and infants (CDC), fava beans and G6PD deficiency (MedlinePlus Genetics), seaweed iodine (NIH ODS). Existing catalogue cautions and exclusions are preserved.
5. **Regression tests.** `test/content/food_profile_drafts_test.dart` now also checks provenance, duplicate ids, preparation state against the USDA description, sodium recomputation, allergen parity, placeholder and boilerplate prose, doubled words, and a wider claims list.

## 1. Corrected during the audit (193 profiles)

| Correction | Profiles |
|---|---|
| cycle-relevance wording | 169 |
| offers wording | 102 |
| allergen line added | 51 |
| sodium note added | 19 |
| sourced safety caution added | 11 |
| serving wording | 3 |

- **sourced safety caution added**: Bean sprouts, Fava (broad) beans, Feta, Goat cheese, Ham, Honey, Kelp, Mozzarella, Ricotta, Smoked salmon, Wakame
- **sodium note added**: Anchovies, Bacon, Bagel, Baked beans, Clam, Cottage cheese, Crab, Ham, Kimchi, Lobster, Miso, Naan, Octopus, Sauerkraut, Scallop, Shrimp, Smoked salmon, Tamari, Tortillas (wheat)
- **serving wording**: Cucumber, Duck, Sourdough bread
- **allergen line added**: Almond milk, Anchovies, Bagel, Bulgur, Butter, Canned salmon, Canned tuna, Cheddar cheese, Chocolate, Coconut, Couscous, Cream cheese, Egg noodles, Farro, Feta, Goat cheese, Granola, Haddock, Hazelnuts, Heavy cream, Herring, Hummus, Kefir, Macadamia nuts, Mackerel, Milk, Miso, Mixed nuts, Mozzarella, Naan, Parmesan, Pasta, Peanuts, Pita bread (whole-wheat), Plain yogurt, Pollock, Snapper, Ricotta, Rye bread, Sea bass, Smoked salmon, Soba noodles, Sour cream, Sourdough bread, Soy milk, Swiss cheese, Tahini, Tilapia, Tortillas (wheat), Wheat flour (whole-grain), Whole-wheat pasta

No nutrient number was changed: every number matched USDA.

## 2. Profiles needing editorial judgment (43)

### Food identity differs from the catalogue name (18)

- **Wheat** (`wheat`): The catalogue says 'Wheat'; the profile uses durum wheat (USDA 'Wheat, durum'). Other wheat differs.
- **Lettuce (Bibb, Boston, romaine)** (`lettuce`): Catalogue name covers Bibb, Boston and romaine; the USDA record is cos/romaine only.
- **Mushrooms (button, shiitake)** (`mushrooms`): Catalogue name says 'button, shiitake'; the USDA record is white (button) mushrooms only.
- **Nut butter** (`nut-butter`): Catalogue says 'Nut butter'; the USDA record is smooth peanut butter without salt. Almond and other nut butters differ.
- **Sourdough bread** (`sourdough-bread`): USDA has no sourdough-only record; the record is 'Bread, french or vienna (includes sourdough)'.
- **Mint** (`mint`): Catalogue 'Mint' uses the USDA spearmint record; peppermint is a separate profile.
- **Kefir** (`kefir`): The USDA record is a branded product (Lifeway, lowfat, plain). Other kefir varies.
- **Tofu** (`tofu`): Calcium depends on the setting agent; the record is firm tofu set with calcium sulfate.
- **Hummus** (`hummus`): Commercial hummus; salt, oil and tahini vary by brand.
- **Salsa** (`salsa`): Ready-to-serve salsa with salt; brands vary.
- **Granola** (`granola`): The USDA record is homemade granola; commercial products differ.
- **Shrimp** (`shrimp`): The USDA record 'may contain additives to retain moisture', which raises its sodium.
- **Snapper** (`red-snapper`): Mixed-species USDA record; species differ in mercury.
- **Sea bass** (`sea-bass`): Mixed-species USDA record; species differ in mercury (the caution says so).
- **Canned tuna** (`canned-tuna`): Light tuna in water; albacore (white) tuna differs in mercury.
- **Tuna** (`tuna`): Same USDA record as canned light tuna; consider merging or distinguishing the two entries.
- **Squash** (`squash`): 'Winter squash, all varieties' average; varieties differ.
- **White potato** (`white-potato`): Baked flesh and skin; boiled or fried potato differs.

### Serving is in a different state from how it is eaten (8)

- **Oat** (`oat`): Serving is dry rolled oats; a bowl of porridge has far fewer nutrients per gram.
- **Farro** (`farro`): Serving is dry pearled farro.
- **Rye** (`rye`): Serving is dry rye grain.
- **Wheat** (`wheat`): Serving is dry durum wheat.
- **Polenta / cornmeal** (`polenta`): Serving is dry cornmeal.
- **Wheat flour (whole-grain)** (`wheat-flour`): Serving is flour, not a baked food.
- **Red lentil** (`red-lentil`): Serving is dry lentils (the text says a cooked portion has about a third of these amounts).
- **Squid** (`squid`): USDA record is raw squid; it is eaten cooked, and cooking changes the values.

### Surprising or low-confidence USDA values (10)

- **Octopus** (`octopus`): Vitamin B12 of 36 µg per 100 g (about 1,275% of the reference per serving) is the USDA figure; it is an estimated value (no data points). Check against a second source before publishing.
- **Bagel** (`bagel`): Vitamin E of 7.5 mg per 100 g (about 52% of the reference per serving) is the USDA figure from two data points; unusually high for a plain bagel.
- **Granola** (`granola`): Vitamin E of 11.1 mg per 100 g is a USDA estimate (no data points).
- **Almond milk** (`almond-milk`): Vitamin E (111%) comes from fortification (USDA 'Vitamin E, added'); fortification varies by brand.
- **Olives** (`olives`): Iron of 6.3 mg per 100 g (one data point) is high for canned olives.
- **Mint** (`mint`): Iron of 11.9 mg per 100 g (two data points) is high; fresh herbs are eaten in tiny amounts.
- **Clam** (`clam`): USDA sodium for cooked clams is 1,200 mg per 100 g, probably reflecting the cooking medium. A serving shows about 1,020 mg.
- **Crab** (`crab`): USDA sodium for cooked Alaska king crab is 1,070 mg per 100 g.
- **Shrimp** (`shrimp`): USDA sodium is 947 mg per 100 g (moisture-retaining additives).
- **Scallop** (`scallop`): USDA sodium is 667 mg per 100 g for steamed scallops.

### Safety wording not researched or not added (12)

- **White rice** (`white-rice`): Arsenic in rice: only brown rice carries a (unsourced) catalogue caution. FDA guidance on rice and arsenic was not read for this project.
- **Rice cakes** (`rice-cakes`): Arsenic in rice products: see white rice.
- **Rice noodles** (`rice-noodles`): Arsenic in rice products: see white rice.
- **Chocolate** (`chocolate`): Caffeine and theobromine content is not stated, and no source was read.
- **Spirulina** (`spirulina`): The catalogue cautions (contamination, pregnancy and autoimmune conditions) have no recorded source.
- **Tuna** (`tuna`): The catalogue mercury caution ('prefer light/skipjack') has no recorded source.
- **Asparagus** (`asparagus`): Vitamin K about 46 µg per serving, below the rule that adds the blood-thinner note (100 µg per 100 g); an editor may want it.
- **Fennel** (`fennel`): Vitamin K about 55 µg per serving, below the rule that adds the blood-thinner note (100 µg per 100 g); an editor may want it.
- **Coconut oil** (`coconut-oil`): No saturated-fat statement is made; an editor may decide whether one is needed.
- **Butter** (`butter`): No saturated-fat statement is made; an editor may decide whether one is needed.
- **Milk** (`milk`): Raw (unpasteurised) milk is not covered; the profile describes pasteurised milk.
- **Eggs** (`eggs`): Raw or undercooked eggs are covered only by the cooking-temperature caution.

## 3. Existing catalogue cautions with no recorded source (59 profiles)

These are carried over from the catalogue unchanged so no existing exclusion is lost. An editor should confirm or source each. Listed as `food: caution`.

- Almond: Tree-nut allergen
- Barley: Contains gluten
- Brazil nut: Limit to 1–2 nuts a day; Tree-nut allergen
- Brown rice: Vary grains (arsenic in rice)
- Cantaloupe: Wash the rind before cutting
- Cashew: Tree-nut allergen
- Catfish: Fish allergen
- Celery: Celery allergen (EU)
- Chard: High in oxalate
- Chestnut: Tree-nut allergen
- Chia seeds: Soak before eating: dry seeds swell when wet
- Clam: Mollusc allergen
- Cod: Fish allergen
- Cottage cheese: Dairy allergen
- Crab: Crustacean allergen
- Edamame: Soy allergen
- Eggs: Egg allergen
- Flounder: Fish allergen
- Greek yogurt: Dairy allergen
- Halibut: Fish allergen
- Hickory: Tree-nut allergen
- Kelp: Can exceed the safe iodine limit; Thyroid conditions: check with a doctor
- Ketchup: High in sugar and salt
- Kidney bean: Dried beans: boil hard for 10 minutes; don't slow-cook from raw
- Kimchi: Check the label for fish sauce or shrimp, and for vegetarian or vegan status
- Kiwi: Kiwi can cause allergic reactions; people with latex allergy may also react.
- Lima bean: Always cook thoroughly
- Lobster: Crustacean allergen
- Miso: Soy allergen
- Mung bean: Raw sprouts: food-safety risk
- Mussel: Mollusc allergen
- Nut butter: Tree-nut or peanut allergen, depending on type
- Oat: Choose certified gluten-free oats if avoiding gluten.
- Oat bran: Choose certified gluten-free oats if avoiding gluten.
- Octopus: Mollusc allergen
- Olives: High in salt
- Oyster: Mollusc allergen; Raw oysters: food-safety risk
- Pecan: Tree-nut allergen
- Pickles: High in salt
- Pine nut: Tree-nut allergen
- Pistachio: Tree-nut allergen
- Rhubarb: Leaves are poisonous: stalks only
- Rye: Contains gluten
- Salmon: Fish allergen
- Sardine: Fish allergen
- Scallop: Mollusc allergen
- Sesame seeds: Sesame allergen
- Shrimp: Crustacean allergen
- Spirulina: Contamination risk: tested brands only; Pregnancy or autoimmune conditions: check with doctor
- Squid: Mollusc allergen
- Tamari: Check gluten-free label; Soy allergen
- Tempeh: Soy allergen; Check the label for gluten-containing grains
- Tofu: Soy allergen
- Trout: Fish allergen
- Tuna: Fish allergen; Mercury: prefer light/skipjack
- Wakame: Iodine: normal portions
- Walnut: Tree-nut allergen
- Wheat: Contains gluten
- Whole-grain bread: Contains wheat (gluten); Check the label for soy, dairy or sesame

## 4. Blocked entries (15): decision table

| Food | Why blocked | Standard nutrient information? | Alternative format | Keep in catalogue? | Recommendation |
|---|---|---|---|---|---|
| Dulse | No USDA FoodData Central record in SR Legacy, Foundation or FNDDS. | No. Only generic 'Seaweed, dried' (FNDDS 2709988), which is not dulse. | Short seaweed note (iodine, sourced from NIH ODS) instead of a nutrient profile. | Yes, unprofiled (already not ship-ready). | Leave unprofiled until a verified composition source is chosen. |
| Hijiki | No USDA record. Hijiki has a known inorganic-arsenic concern raised by food-safety agencies; no such source was read for this project. | No. | Safety-first note only, once an agency source is read and quoted. | Owner decision. Recommend removing it, or keeping it unprofiled and not ship-ready. | Do not profile. Needs an agency source before any wording. |
| Kombu | No USDA record for dried kombu. Raw kelp (168457) is drafted as 'kelp' but is a different preparation. | Partly. Generic 'Seaweed, dried' (FNDDS 2709988) exists but is not kombu. NIH ODS names kombu among the best food sources of iodine. | Seaweed note led by the sourced iodine fact (NIH ODS: upper limit 1,100 µg/day), or merge into the kelp profile. | Yes (ship-ready in the catalogue). | Owner decision: iodine-led note, or merge with kelp. |
| Guacamole | No SR Legacy or Foundation record. Earlier note said no USDA record; FNDDS does have one. | Yes, as an average recipe: FNDDS 2709307 'Guacamole, NFS' and 2709308 'Guacamole with tomatoes'. | A dish-style profile stating it is an average recipe and that salt and ingredients vary. | Yes. | Draftable from FNDDS once you accept survey (average-recipe) data. |
| Black soybean | No USDA record for black soybeans; the yellow soybean record is a different variety. | No. | None needed. | Owner decision. Already not ship-ready; recommend leaving it unprofiled or removing it. | Hold until a label or lab source is chosen. |
| Seitan | Composition depends on the product (vital wheat gluten, soy sauce, salt). | Only generic: vital wheat gluten ingredient (SR 168147) and a generic 'meat substitute, cereal- and vegetable protein-based' (FNDDS 2709163). Neither is seitan as eaten. | Label-based profile for a named product, or a note that values vary. | Yes (gluten allergen). | Hold; needs a defined product. |
| Oat milk | Earlier note said no SR Legacy record. A USDA Foundation record does exist. | Yes: Foundation 2257046 'Oat milk, unsweetened, plain, refrigerated' and FNDDS 2705412 'Oat milk'. | Standard profile, stating it is unsweetened plain oat milk and that fortification varies by brand. | Yes. | Draftable now from Foundation 2257046. Not drafted in this audit (scope). |
| Muesli | No generic USDA record; only brand cereals (SR 169075 Alpen, 169076 Familia). | Brand-specific only. | Label-based profile for a named product. | Yes (gluten and tree-nut allergens). | Hold; needs a defined product. |
| Salt | Salt is not a nutrient-offering food. A profile would be a sodium limit message. | Yes for sodium, but there is nothing to 'offer'. The sourced limit is verified: FDA/Dietary Guidelines advise adults to keep sodium under 2,300 mg a day. | A 'Salt and sodium' information card (not a Food Detail profile). The sodium cautions now added to salty foods already carry the limit. | Owner decision. Recommend an information card or removing it from the food list. | Do not profile as a food. |
| Alcohol (moderate) | Not a nutrient-offering food; any text is a health-risk message needing expert wording. | Yes (SR/FNDDS list beer, wine, spirits) but nutrient content is not the point. | Safety information card with sourced guidance (Dietary Guidelines, NIAAA, pregnancy advice), none of which was read here. | Owner decision. Recommend an information card or removing it from the food list. | Do not profile as a food. |
| Bancha tea | Brewed tea has almost no nutrients; caffeine, fluoride and tannin wording needs sources. | Partly: SR 171917 'tea, green, brewed' exists, not bancha specifically; values are close to zero. | Short drink note (caffeine) with a sourced FDA statement. | Yes. | Owner decision on format; low priority. |
| Coffee | Brewed coffee has almost no nutrients; caffeine guidance needs sourced wording. | Yes, trivial: FNDDS 2710375 'Coffee, brewed'. | Short drink note with sourced caffeine guidance. | Yes. | Owner decision on format; low priority. |
| Decaf coffee | As coffee; residual caffeine wording needs a source. | Yes, trivial: FNDDS 2710452 'Coffee, brewed, decaffeinated'. | Combine with the coffee drink note. | Yes. | Decide together with coffee. |
| Soft-shell crab | Soft-shell crab is blue crab eaten whole, usually fried; the cooked blue crab record is a different preparation. | Yes, as a prepared food: FNDDS 2706346 'Crab, soft shell'. Cooked blue crab: SR 174205. | Standard profile from FNDDS with the preparation stated, or merge into the crab profile. | Yes (already not ship-ready; shellfish allergen). | Owner decision: draft from FNDDS or merge with crab. |
| Fresh-water clam | USDA has only marine and mixed clam records; freshwater clam composition differs. | No. | None. | Owner decision. Already not ship-ready; recommend removing it. | Hold; no source. |

Correction to an earlier statement: guacamole, oat milk and soft-shell crab do have USDA records (Survey/FNDDS or Foundation); the original search only covered SR Legacy and Foundation for some of them. They stay blocked pending your decision on using survey (average-recipe) data.

## 5. Validated without substantive concerns (164 profiles)

Data matches USDA, prose read and corrected where needed, no open identity, state, value or safety note. Still **unreviewed and unpublished**: an editor must approve every profile before it can appear in Food Detail.

Adzuki bean, Amaranth, Anchovies, Apple, Apricot, Artichoke, Arugula (rocket), Avocado, Avocado oil, Bacon, Baked beans, Banana, Basil, Bean sprouts, Beef, Beets, Black-eyed pea, Black beans, Blackberry, Blueberry, Bok choy, Brussels sprouts, Buckwheat (kasha), Bulgur, Burdock, Cabbage, Canned salmon, Canned tomatoes, Carrot, Cauliflower, Celeriac, Cheddar cheese, Chicken, Chickpea, Chicory, Chili pepper, Chive, Cilantro (coriander), Coconut, Collard, Concord grape, Corn, Couscous, Cranberry, Cream cheese, Cucumber, Daikon, Dandelion, Date, Dill, Dried apricots, Duck, Egg noodles, Eggplant, Endive, Escarole, Fava (broad) beans, Feta, Fig, Flaxseeds, Garlic, Ginger, Goat cheese, Grapefruit, Grapes, Great northern bean, Green bell pepper, Green pea, Guava, Haddock, Ham, Hazelnuts, Heavy cream, Hemp seeds, Herring, Honey, Honeydew melon, Kale, Kohlrabi, Lamb, Leek, Lemon, Lime, Lychee, Macadamia nuts, Mackerel, Mandarin / tangerine, Mango, Maple syrup, Millet, Mixed nuts, Mozzarella, Mustard greens, Naan, Napa cabbage, Navy bean, Nectarine, Okra, Olive oil, Onion, Papaya, Parmesan, Parsley, Parsnip, Pasta, Peach, Peanuts, Pear, Peppermint, Persimmon, Pineapple, Pinto beans, Pita bread (whole-wheat), Plain yogurt, Plantain, Plum, Pollock, Pomegranate, Popcorn (plain), Pork, Prunes (dried plums), Pumpkin, Quinoa, Radicchio, Radish, Raisin, Raspberry, Red bell pepper, Red cabbage, Ricotta, Rye bread, Sauerkraut, Scallion, Shallot, Smoked salmon, Soba noodles, Sour cherry, Sour cream, Soy milk, Split pea, Strawberry, String bean, Sugar snap peas, Sunflower seeds, Sweet cherry, Sweet potato, Swiss cheese, Tahini, Tilapia, Tomato, Tomato paste, Tortillas (wheat), Turkey, Turmeric, Turnip, Vinegar, Water chestnut, Watercress, Watermelon, White beans, Whole-wheat pasta, Wild rice, Yellow bell pepper, Zucchini

## What you need to approve

1. The editorial wording and structure of the draft profiles (start with section 2, then sample section 5; `review-list.md` has sampling sheets by category).
2. The new sourced cautions and the sodium and allergen lines (section 1).
3. A decision for each of the 15 blocked entries (section 4), including whether survey (FNDDS) data is acceptable.
4. How to treat the carried-over catalogue cautions that have no source (section 3).
5. Publishing itself: no draft is publishable. Each approved profile must be moved into `assets/content/food_profiles.json` with the review fields filled by a person; that is a separate change.
