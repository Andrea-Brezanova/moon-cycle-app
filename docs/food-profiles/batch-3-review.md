# Draft batch 3: vegetables (24 foods; nothing here is published)

mushrooms, brussels sprouts, chard, eggplant, collard greens, green and yellow bell pepper,
white potato, lettuce (romaine), green beans, zucchini, arugula, bok choy, napa cabbage,
turnip, asparagus, celery, radish, bean sprouts, red cabbage, sugar snap peas, artichoke,
parsnip, squash. Built by `build_draft_batch.py 3` from `batch-3.src.json` (USDA
FoodData Central values read on 27 Oct 2026; key nutrients are chosen by a fixed rule, see
the script), re-checked by `test/content/food_profile_drafts_test.dart`.

## Identity questions for you
- **Mushrooms:** the catalogue says button and shiitake; the record is white (button).
- **Lettuce:** the catalogue covers Bibb, Boston and romaine; the record is romaine.
- **Squash:** the catalogue entry is not specific; the record is winter squash, baked.
- **Bean sprouts:** read as mung bean sprouts. Raw sprouts are a food-safety topic (FDA and
  USDA advise cooking them for higher-risk groups); no caution has been added because I
  have not read that page this session. Decide whether to add one.
- **Asparagus:** the "without salt" record is frozen; this is the plain cooked record
  (169313 is the salted one), which lists no salt.
- **Low-nutrient foods** (eggplant, celery, radish, zucchini, mushrooms) show their two best
  nutrients even when small, so some percentages are low. That is accurate; you may prefer
  fewer rows.

## Cautions
Vitamin K (blood-thinner note, NIH ODS) is added automatically to foods with 100 µg or more
per 100 g: brussels sprouts, chard, collards, arugula, romaine. No oxalate caution was added
for any vegetable here (NIDDK's page names spinach and rhubarb, not these).

## Unsourced wording to accept, change or remove
Preparation tips in "How to eat it", flavour words ("peppery", "sweet"), and the sentence
that eggplant soaks up oil when fried.
