# Food profile quality audit: consolidated review package

Nothing here is published. All 251 drafts remain unreviewed and outside the app; the 5 approved profiles are unchanged. See `publication-plan.md` for the approval plan.

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

1. **Source identity, preparation, serving and amounts (all 251).** `audit_profiles.py` re-fetches every cited USDA FoodData Central record and compares FDC id, description, publication date, every stored per-100 g value (including sodium), the serving weight against the record's household measures, and every per-serving amount and reference percentage. **Result: 0 open findings**; two serving texts (chestnut, cottage cheese) were reviewed and accepted with reasons recorded in the script. No USDA value had been mis-copied.
2. **Prose (all 251).** Every section was read. Fixed: boilerplate cycle text, grammar slips, filler and promotional wording, robotic opening lines, awkward serving text, a unit-grammar bug.
3. **Claims.** No hormone, fertility, PMS, mood or phase-benefit claim in any profile; a test enforces it. Where a nutrient has a sourced reference (iron and menstrual blood loss, calcium, folate, vitamin C with plant iron), the sentence names its NIH ODS source.
4. **Safety and allergens.** Every caution now has a status: `sourced` (an authoritative page read supports the wording), `partly-sourced`, `catalogue-tag` (an allergen tag from `foods.json`), or `unverified-inherited` (carried over from the catalogue, no source found). Nothing unverified is described as verified.
5. **Regression tests.** `test/content/food_profile_drafts_test.dart` checks provenance, preparation state, sodium, allergen parity, caution status and sources, placeholder prose, and a wide claims list.

## 1. Corrected during the first audit (193 profiles)

| Correction | Profiles |
|---|---|
| cycle-relevance wording | 169 |
| offers wording | 102 |
| allergen line added | 51 |
| sodium note added | 19 |
| sourced safety caution added | 11 |
| serving wording | 3 |

No nutrient number was changed: every number matched USDA.

## 2. Resolved in the readiness pass (16)

Straightforward issues closed with a traceable source or an explicit wording fix:

- **Octopus** (`octopus`): Vitamin B12 of 36 µg per 100 g is consistent with USDA's raw octopus record (20 µg per 100 g): the cooked value is 1.8 times the raw one, in line with water loss (USDA 174218 raw, 174249 cooked).
- **Clam** (`clam`): Sodium of 1,200 mg per 100 g (cooked, moist heat) compares with 601 mg in USDA's raw mixed-species clam record (174214), a 2 times rise; the figures are USDA's own.
- **Crab** (`crab`): Sodium of 1,070 mg per 100 g (cooked) compares with 836 mg in USDA's raw Alaska king crab record (175164).
- **Shrimp** (`shrimp`): Sodium of 947 mg per 100 g (cooked) compares with 566 mg in the raw record (174210); both records carry the moisture-retention additives note.
- **Scallop** (`scallop`): Sodium of 667 mg per 100 g (steamed) compares with 392 mg in the raw record (174220).
- **Almond milk** (`almond-milk`): All of the vitamin E (6.33 mg per 100 g) is listed by USDA as "Vitamin E, added", so it comes from fortification and varies by brand.
- **White rice** (`white-rice`): Rice arsenic: added the FDA statement that rice tends to absorb more arsenic than other crops and can still be part of a well-balanced diet.
- **Rice cakes** (`rice-cakes`): Rice arsenic: see white rice (FDA).
- **Rice noodles** (`rice-noodles`): Rice arsenic: see white rice (FDA).
- **Tuna** (`tuna`): The mercury caution is now sourced: the FDA and EPA list "Tuna, canned light (includes skipjack)" as a Best Choice.
- **Wheat** (`wheat`): Opening line now says durum wheat (dry).
- **Mint** (`mint`): Opening line now says spearmint.
- **Granola** (`granola`): Opening line now says homemade granola.
- **Salsa** (`salsa`): Opening line now says ready-to-serve salsa with salt.
- **Snapper** (`red-snapper`): Opening line now says the USDA record covers mixed species.
- **Kidney bean** (`kidney-bean`): Safety correction made: the catalogue and the draft now use the FDA wording (soak at least 5 hours, boil in fresh water at least 30 minutes; no slow cookers; canned beans are already cooked), replacing the inherited '10 minutes'. Sources: FDA Natural Toxins in Food (09/26/2024) and the FDA Bad Bug Book, 2nd edition.

Also: sodium no longer appears as a caution. It is stored as data for every profile; a calm nutrition note appears only at 460 mg or more per serving (the FDA's 20%-of-Daily-Value "high" line) and is not worded as a warning. The kidney bean caution was corrected to the FDA wording in both the catalogue and the draft (soak 5 hours, boil 30 minutes, no slow cooker, canned beans already cooked). Vitamin E was dropped from the key nutrients of bagel and granola because the USDA value looks unreliable (D5).

## 3. Decisions for you (13 decisions, 49 profiles)

**D1. Dry-weight servings** (Oat, Farro, Rye, Wheat, Polenta / cornmeal, Wheat flour (whole-grain), Red lentil)  
These servings are for the dry food (USDA has no cooked record for most). Accept dry servings, clearly labelled, or switch to cooked records where they exist?  
*Recommendation:* Accept, labelled "dry" (done in the text).

**D2. Raw squid record** (Squid)  
USDA has raw and fried squid but no plainly cooked record. The raw values are shown with "cook before eating". Accept, use the fried record, or hold?  
*Recommendation:* Hold squid until you choose.

**D3. Record narrower than the catalogue name** (Sourdough bread, Snapper, Sea bass)  
sourdough-bread uses a French/Vienna bread record that includes sourdough; snapper and sea bass use mixed-species records. Accept with the record named, or rename the catalogue entries?  
*Recommendation:* Accept with the record named.

**D4. Tuna listed twice** (Tuna, Canned tuna)  
Both entries use the same USDA record (canned light tuna in water). Keep both, merge, or distinguish them?  
*Recommendation:* Merge or distinguish at the catalogue level; profiles are identical in substance.

**D5. Vitamin E left out** (Bagel, Granola)  
USDA vitamin E for these is unusually high (7.5 and 11.1 mg per 100 g; granola is an estimate). Vitamin E is omitted from their key nutrients. Accept the omission?  
*Recommendation:* Accept.

**D6. High iron values from few data points** (Olives, Mint)  
Iron of 6.3 and 11.9 mg per 100 g from one or two data points. Accept, or omit the iron highlight?  
*Recommendation:* Accept (8% of the reference per serving).

**D7. Chocolate** (Chocolate)  
No caffeine or theobromine statement (no source read), and the dairy and soy tags depend on the product. Add a sourced note, and keep the tags?  
*Recommendation:* Keep the tags; decide on a caffeine note after a source is read.

**D8. Moderate vitamin K** (Asparagus, Fennel)  
About 46 and 55 µg of vitamin K per serving, below the 100 µg per 100 g rule that adds the blood-thinner note. Add the note?  
*Recommendation:* Leave as data; the existing rule is conservative enough.

**D9. Fat statements** (Butter, Coconut oil, Heavy cream)  
No saturated-fat statement is made. Add a sourced one, or leave the data to speak?  
*Recommendation:* Leave.

**D10. Raw handling of milk and eggs** (Milk, Eggs)  
Profiles describe pasteurised milk and hard-boiled eggs. Add a sourced raw-milk or raw-egg line for people at greater risk (FDA)?  
*Recommendation:* Optional; a one-line FDA statement is available.

**D11. How sodium appears** (Anchovies, Bacon, Bagel, Baked beans, Clam, Crab, Ham, Miso, Sauerkraut, Scallop, Shrimp, Smoked salmon, Tamari, Octopus, Naan, Lobster, Kimchi, Tortillas (wheat))  
Sodium is stored as data for every profile. A calm "nutrition note" appears only at 460 mg or more (the FDA's 20% of Daily Value "high" line). Food Detail has no notes field today. Show the note as a "Good to know" line, or keep it as data only?  
*Recommendation:* Keep as data; add the note only if Food Detail gains a place for it.

**D12. Allergen tags broader or narrower than the food** (Coconut, Tamari, Miso, Chocolate, Granola, Bagel, Celery, Clam, Mussel, Oyster, Octopus, Scallop, Squid)  
Coconut counted as a tree nut; tamari and miso gluten (many tamari are wheat-free); chocolate dairy and soy (product-dependent); sesame in bagels; celery and molluscs (EU lists, not on the US list of nine). Keep every tag (protective) or refine?  
*Recommendation:* Keep all tags; refine wording only with an allergist or label source.

**D13. Seed foods (flax, sesame, sunflower)** (Flaxseeds, Sesame seeds, Sunflower seeds)  
Small, mixed studies exist on seeds (or their components) in PMS and PCOS populations, and a 1993 crossover trial found flaxseed lengthened the luteal phase. The standard line "We found no reliable research linking this food to a particular phase" would be too blunt for these. Hold them back, write a seed-specific note, or publish with the standard wording? Pumpkin seeds (already approved) use older wording.  
*Recommendation:* Hold these three out of Wave 1 until you decide.

## 4. Inherited cautions: verification status

| Status | Cautions |
|---|---|
| sourced | 122 |
| partly-sourced | 10 |
| catalogue-tag | 56 |
| unverified-inherited | 18 |

The earlier audit counted 59 profiles carrying an inherited caution with no recorded source. After reading authoritative pages (FDA, NIDDK, NIH ODS, MedlinePlus), allergen categories, gluten, oats, brown rice, cantaloupe, rhubarb, kelp and tuna cautions now carry sources. **17 profiles still carry an inherited caution I could not source** (kept, labelled `unverified-inherited`, not described as verified):

- Celery: Celery allergen (EU)
- Chard: High in oxalate
- Chia seeds: Soak before eating: dry seeds swell when wet
- Clam: Mollusc allergen
- Ketchup: High in sugar and salt
- Kimchi: Check the label for fish sauce or shrimp, and for vegetarian or vegan status
- Kiwi: Kiwi can cause allergic reactions; people with latex allergy may also react.
- Lima bean: Always cook thoroughly
- Mussel: Mollusc allergen
- Octopus: Mollusc allergen
- Oyster: Mollusc allergen
- Scallop: Mollusc allergen
- Spirulina: Contamination risk: tested brands only; Pregnancy or autoimmune conditions: check with doctor
- Squid: Mollusc allergen
- Tamari: Check gluten-free label
- Tempeh: Check the label for gluten-containing grains
- Whole-grain bread: Check the label for soy, dairy or sesame

Sources that did not support an inherited caution: NIDDK's kidney-stone page lists spinach, rhubarb, nuts, peanuts and wheat bran but not chard, so the chard oxalate caution stays unverified. The FDA page read does not mention lima beans, so "always cook thoroughly" stays unverified. Mollusc and celery allergen tags rest on the EU allergen list, which I could not load.

`partly-sourced` (10 profiles) means the page supports the topic but not every detail, for example "limit to 1-2 Brazil nuts a day" (NIH ODS supports high selenium and the 400 mcg upper limit, not the 1-2 figure).

## 5. Blocked entries (15): decision table

| Food | Why blocked | Standard nutrient information? | Survey/FNDDS or other record appropriate? | Alternative format | Keep in catalogue? | Recommendation |
|---|---|---|---|---|---|---|
| Dulse | No USDA FoodData Central record in SR Legacy, Foundation or FNDDS. | No. Only generic 'Seaweed, dried' (FNDDS 2709988), which is not dulse. | **none exists**: No SR Legacy, Foundation or FNDDS record for dulse. Generic FNDDS "Seaweed, dried" (2709988) is not dulse and must not stand in for it. | Short seaweed note (iodine, sourced from NIH ODS) instead of a nutrient profile. | Yes, unprofiled (already not ship-ready). | Leave unprofiled until a verified composition source is chosen. |
| Hijiki | No USDA record. Hijiki has a known inorganic-arsenic concern raised by food-safety agencies; no such source was read for this project. | No. | **none exists**: No record. Nothing should stand in for it; the open issue is safety, not composition. | Safety-first note only, once an agency source is read and quoted. | Owner decision. Recommend removing it, or keeping it unprofiled and not ship-ready. | Do not profile. Needs an agency source before any wording. |
| Kombu | No USDA record for dried kombu. Raw kelp (168457) is drafted as 'kelp' but is a different preparation. | Partly. Generic 'Seaweed, dried' (FNDDS 2709988) exists but is not kombu. NIH ODS names kombu among the best food sources of iodine. | **no**: Only generic FNDDS "Seaweed, dried" (2709988) and raw kelp (SR 168457, already used for kelp). Neither is dried kombu; iodine differs widely between seaweeds. | Seaweed note led by the sourced iodine fact (NIH ODS: upper limit 1,100 µg/day), or merge into the kelp profile. | Yes (ship-ready in the catalogue). | Owner decision: iodine-led note, or merge with kelp. |
| Guacamole | No SR Legacy or Foundation record. Earlier note said no USDA record; FNDDS does have one. | Yes, as an average recipe: FNDDS 2709307 'Guacamole, NFS' and 2709308 'Guacamole with tomatoes'. | **conditional**: FNDDS 2709307 "Guacamole, NFS" (updated 10/31/2024) is a survey average of recipes eaten in the US, not a defined recipe. If used, the profile must say "average guacamole" and that avocado share, salt and added ingredients vary. | A dish-style profile stating it is an average recipe and that salt and ingredients vary. | Yes. | Draftable from FNDDS once you accept survey (average-recipe) data. |
| Black soybean | No USDA record for black soybeans; the yellow soybean record is a different variety. | No. | **none exists**: No black soybean record. The yellow soybean record is a different variety and must not stand in. | None needed. | Owner decision. Already not ship-ready; recommend leaving it unprofiled or removing it. | Hold until a label or lab source is chosen. |
| Seitan | Composition depends on the product (vital wheat gluten, soy sauce, salt). | Only generic: vital wheat gluten ingredient (SR 168147) and a generic 'meat substitute, cereal- and vegetable protein-based' (FNDDS 2709163). Neither is seitan as eaten. | **no**: The only FNDDS candidate (2709163, "Meat substitute, cereal- and vegetable protein-based, fried") is a generic fried product, not seitan; vital wheat gluten (SR 168147) is an ingredient. Neither represents seitan as eaten. | Label-based profile for a named product, or a note that values vary. | Yes (gluten allergen). | Hold; needs a defined product. |
| Oat milk | Earlier note said no SR Legacy record. A USDA Foundation record does exist. | Yes: Foundation 2257046 'Oat milk, unsweetened, plain, refrigerated' and FNDDS 2705412 'Oat milk'. | **yes**: USDA Foundation 2257046 "Oat milk, unsweetened, plain, refrigerated" (4/28/2022) is a defined product type and the best fit. Limitation: one plain unsweetened product; fortification, oil and sugar vary by brand, and the record lists no household measure, so a cup weight must be sourced when drafting. | Standard profile, stating it is unsweetened plain oat milk and that fortification varies by brand. | Yes. | Draftable now from Foundation 2257046. Not drafted in this audit (scope). |
| Muesli | No generic USDA record; only brand cereals (SR 169075 Alpen, 169076 Familia). | Brand-specific only. | **no**: Only brand cereals (SR 169075 Alpen, 169076 Familia). Using one would present a brand as muesli in general. | Label-based profile for a named product. | Yes (gluten and tree-nut allergens). | Hold; needs a defined product. |
| Salt | Salt is not a nutrient-offering food. A profile would be a sodium limit message. | Yes for sodium, but there is nothing to 'offer'. The sourced limit is verified: FDA/Dietary Guidelines advise adults to keep sodium under 2,300 mg a day. | **not applicable**: Composition exists but a nutrient profile is the wrong format. | A 'Salt and sodium' information card (not a Food Detail profile). The sodium cautions now added to salty foods already carry the limit. | Owner decision. Recommend an information card or removing it from the food list. | Do not profile as a food. |
| Alcohol (moderate) | Not a nutrient-offering food; any text is a health-risk message needing expert wording. | Yes (SR/FNDDS list beer, wine, spirits) but nutrient content is not the point. | **not applicable**: FNDDS/SR list beers, wines and spirits separately; "moderate alcohol" is a drinking pattern, not a food record. | Safety information card with sourced guidance (Dietary Guidelines, NIAAA, pregnancy advice), none of which was read here. | Owner decision. Recommend an information card or removing it from the food list. | Do not profile as a food. |
| Bancha tea | Brewed tea has almost no nutrients; caffeine, fluoride and tannin wording needs sources. | Partly: SR 171917 'tea, green, brewed' exists, not bancha specifically; values are close to zero. | **conditional**: SR 171917 "Beverages, tea, green, brewed, regular" (4/1/2019) is generic green tea. Bancha is a specific Japanese green tea; values are near zero either way, so the limitation is identity, not numbers. | Short drink note (caffeine) with a sourced FDA statement. | Yes. | Owner decision on format; low priority. |
| Coffee | Brewed coffee has almost no nutrients; caffeine guidance needs sourced wording. | Yes, trivial: FNDDS 2710375 'Coffee, brewed'. | **yes**: FNDDS 2710375 "Coffee, brewed" (10/31/2024) is appropriate for the (negligible) nutrient data. Limitation: caffeine is not in the nutrient set tracked here, and it is the point of the entry. | Short drink note with sourced caffeine guidance. | Yes. | Owner decision on format; low priority. |
| Decaf coffee | As coffee; residual caffeine wording needs a source. | Yes, trivial: FNDDS 2710452 'Coffee, brewed, decaffeinated'. | **yes**: FNDDS 2710452 "Coffee, brewed, decaffeinated" (10/31/2024), same limitation as coffee. | Combine with the coffee drink note. | Yes. | Decide together with coffee. |
| Soft-shell crab | Soft-shell crab is blue crab eaten whole, usually fried; the cooked blue crab record is a different preparation. | Yes, as a prepared food: FNDDS 2706346 'Crab, soft shell'. Cooked blue crab: SR 174205. | **conditional**: FNDDS 2706346 "Crab, soft shell" (10/31/2024, about 227 kcal per 100 g) is a prepared survey average, probably fried. If used, the profile must state that it is the prepared dish, not the animal; cooked blue crab (SR 174205) is a different preparation. | Standard profile from FNDDS with the preparation stated, or merge into the crab profile. | Yes (already not ship-ready; shellfish allergen). | Owner decision: draft from FNDDS or merge with crab. |
| Fresh-water clam | USDA has only marine and mixed clam records; freshwater clam composition differs. | No. | **none exists**: No freshwater clam record; marine clam records must not stand in. | None. | Owner decision. Already not ship-ready; recommend removing it. | Hold; no source. |

Rule applied: no average-recipe or generic record stands in for an exact ingredient unless the limitation is stated in the profile. Nothing is substituted in this pass.

## 6. Validated without substantive concerns (194 profiles)

Data matches USDA, prose read, every caution sourced or a catalogue tag, and no open decision. Still **unreviewed and unpublished**.

Adzuki bean, Almond, Almond milk, Amaranth, Apple, Apricot, Artichoke, Arugula (rocket), Avocado, Avocado oil, Banana, Barley, Basil, Bean sprouts, Beef, Beets, Black-eyed pea, Black beans, Blackberry, Blueberry, Bok choy, Brazil nut, Brown rice, Brussels sprouts, Buckwheat (kasha), Bulgur, Burdock, Cabbage, Canned salmon, Canned tomatoes, Cantaloupe, Carrot, Cashew, Catfish, Cauliflower, Celeriac, Cheddar cheese, Chestnut, Chicken, Chickpea, Chicory, Chili pepper, Chive, Cilantro (coriander), Cod, Collard, Concord grape, Corn, Cottage cheese, Couscous, Cranberry, Cream cheese, Cucumber, Daikon, Dandelion, Date, Dill, Dried apricots, Duck, Edamame, Egg noodles, Eggplant, Endive, Escarole, Fava (broad) beans, Feta, Fig, Flounder, Garlic, Ginger, Goat cheese, Grapefruit, Grapes, Great northern bean, Greek yogurt, Green bell pepper, Green pea, Guava, Haddock, Halibut, Hazelnuts, Hemp seeds, Herring, Hickory, Honey, Honeydew melon, Hummus, Kale, Kefir, Kelp, Kidney bean, Kohlrabi, Lamb, Leek, Lemon, Lettuce (Bibb, Boston, romaine), Lime, Lychee, Macadamia nuts, Mackerel, Mandarin / tangerine, Mango, Maple syrup, Millet, Mixed nuts, Mozzarella, Mung bean, Mushrooms (button, shiitake), Mustard greens, Napa cabbage, Navy bean, Nectarine, Nut butter, Oat bran, Okra, Olive oil, Onion, Papaya, Parmesan, Parsley, Parsnip, Pasta, Peach, Peanuts, Pear, Pecan, Peppermint, Persimmon, Pickles, Pine nut, Pineapple, Pinto beans, Pistachio, Pita bread (whole-wheat), Plain yogurt, Plantain, Plum, Pollock, Pomegranate, Popcorn (plain), Pork, Prunes (dried plums), Pumpkin, Quinoa, Radicchio, Radish, Raisin, Raspberry, Red bell pepper, Red cabbage, Rhubarb, Rice cakes, Rice noodles, Ricotta, Rye bread, Salmon, Salsa, Sardine, Scallion, Shallot, Soba noodles, Sour cherry, Sour cream, Soy milk, Split pea, Squash, Strawberry, String bean, Sugar snap peas, Sweet cherry, Sweet potato, Swiss cheese, Tahini, Tilapia, Tofu, Tomato, Tomato paste, Trout, Turkey, Turmeric, Turnip, Vinegar, Wakame, Walnut, Water chestnut, Watercress, Watermelon, White beans, White potato, White rice, Whole-wheat pasta, Wild rice, Yellow bell pepper, Zucchini

