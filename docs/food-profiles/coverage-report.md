# Food profile coverage report

All numbers computed by `build_reports.py` from the catalogue and the draft files.

- Catalogue foods: **271**
- Approved and published (unchanged): **5**
- Drafted (USDA-sourced, validated by script/test, **unreviewed, unpublished**): **251**
- Blocked (no sound source or needs an owner decision): **15**
- Missing: **0**

Phase-assigned foods (from mapping-142.json): 142; approved 5, drafted 137, blocked 0, missing 0.

Tracking states used: Published (approved only) / Drafted / Source matched (USDA record named, FDC id and serving recorded) / Validated (numbers recomputed by script and Dart test) / Editorial review needed (all drafted foods) / Blocked.
Every drafted food is Drafted + Source matched + Validated + Editorial review needed. None is Published.

## By category

| Category | Total | Approved | Drafted | Blocked |
|---|---|---|---|---|
| dairy-alternatives | 19 | 0 | 18 | 1 |
| fermented | 5 | 0 | 5 | 0 |
| fruit | 39 | 1 | 38 | 0 |
| grains | 33 | 0 | 32 | 1 |
| legumes | 19 | 1 | 17 | 1 |
| nuts-seeds | 21 | 1 | 20 | 0 |
| other | 15 | 0 | 10 | 5 |
| protein | 12 | 0 | 11 | 1 |
| seafood | 30 | 0 | 28 | 2 |
| vegetables | 78 | 2 | 72 | 4 |

## Blocked foods

| Food | Reason |
|---|---|
| Alcohol (moderate) (`alcohol`) | 'Alcohol (moderate)' is not a nutrient-offering food, and any profile would be a health-risk message that needs expert/editorial wording (Dietary Guidelines, NIAAA). Needs an owner decision on whether to profile it at all. |
| Bancha tea (`bancha-tea`) | Brewed tea has almost no nutrients in USDA records and any caffeine/fluoride/tannin message needs a sourced caution. Needs an editorial decision on format. |
| Black soybean (`black-soybean`) | No USDA record for black soybeans. The yellow soybean record (174271) is a different variety and was not substituted without owner approval. |
| Coffee (`coffee`) | Brewed coffee has almost no nutrients in USDA records; caffeine guidance (FDA, pregnancy) needs sourced wording that was not read for this project. Needs an editorial decision. |
| Decaf coffee (`decaf-coffee`) | As coffee: almost no nutrients; residual caffeine and sourcing need an editorial decision. |
| Dulse (`dulse`) | No USDA FoodData Central record for dulse (searched SR Legacy and Foundation). Needs a verified composition source before a profile. |
| Fresh-water clam (`fresh-water-clam`) | USDA has only marine/mixed clam records; freshwater clam composition differs. The catalogue marks it not ship-ready. |
| Guacamole (`guacamole`) | No USDA SR Legacy record for guacamole; composition varies by recipe (avocado, onion, lime, salt). Needs a defined recipe or a branded product. |
| Hijiki (`hijiki`) | No USDA record for hijiki. Hijiki also has a known inorganic-arsenic concern raised by food-safety agencies; a sourced caution (not read for this project) would be needed before any profile. |
| Kombu (`kombu`) | No USDA record for kombu (dried kelp). Raw kelp (168457) exists and is drafted as 'kelp', but it is a different preparation (raw vs dried) and was not used as a stand-in. Iodine content is very high and needs a sourced caution. |
| Muesli (`muesli`) | No generic USDA record for muesli (only brand cereals such as Alpen and Familia). Needs a defined product. |
| Oat milk (`oat-milk`) | No USDA SR Legacy record for oat milk; composition is brand-specific (fortification, added oil, sugar). Needs a defined product or label data. |
| Salt (`salt`) | Not a nutrient-offering food: salt supplies sodium (and iodine only if iodised), and sodium guidance (e.g. the Dietary Guidelines limit) is a safety/limit message, not a 'what this food offers' profile. Needs an editorial decision on format before any draft. |
| Seitan (`seitan`) | No USDA record for seitan. Values depend on the product (vital wheat gluten content, added soy sauce, salt). Needs a defined product. |
| Soft-shell crab (`soft-shell-crab`) | Soft-shell crab is blue crab caught after moulting and eaten whole, usually fried. USDA has cooked blue crab (174205) but not soft-shell crab, so the preparation and whole-animal composition differ. Needs a decision on whether blue crab may stand in. |
