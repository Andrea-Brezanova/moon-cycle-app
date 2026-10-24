# Food photograph audit (item 5)

The older list is `food-photo-inventory.md`; this audit adds the V2 view.

Audit of `plant_photos.dart` and the bundled catalogue (271 foods, 112 recipes).

## Mapping
- `plantPhotos` is an explicit id → file table, so a photo can never be matched to a
  similarly named food by accident. Entries: broccoli, avocado, blueberry (Unsplash,
  credited in `docs/photo-credits.md` and on the Credits page). **No mismatches found.**
- Foods without a photo show an attractive fallback tile (phase tint with a leaf
  icon, or the emoji on Foods rows). No other ingredient's photo is substituted.
- 40 of 112 recipes have a photo; the rest show the phase-tinted tile. Not audited
  food-by-food here; a recipe photo is only used for its own recipe.

## Missing (priority order)
1. **Foods that can appear as a daily plant** (the 3 a Day pool): 164 foods,
   161 without a photo. These are the visible ones, so they come first.
2. Today's food on Foods (any catalogue food, rotates daily) and the Foods list.
3. The remaining catalogue: seafood, protein, dairy alternatives, fermented, other.

Daily-plant foods missing a photo (161):
Buckwheat (kasha), Wild rice, Beets, Burdock, Dulse, Hijiki, Kale, Kelp, Kombu, Mushrooms (button, shiitake), Wakame, Water chestnut, Blackberry, Concord grape, Watermelon, Adzuki bean, Black soybean, Black beans, Kidney bean, Chestnut, Sesame seeds, Sunflower seeds, Barley, Oat, Rye, Artichoke, Carrot, Lettuce (Bibb, Boston, romaine), Parsley, Green pea, Rhubarb, String bean, Zucchini, Grapefruit, Lemon, Lime, Orange, Plum, Pomegranate, Sour cherry, Black-eyed pea, Lentils, Lima bean, Mung bean, Split pea, Brazil nut, Cashew, Flaxseeds, Lychee, Pumpkin seeds, Olives, Amaranth, Corn, Quinoa, Asparagus, Red bell pepper, Brussels sprouts, Chard, Chicory, Chive, Dandelion, Eggplant, Endive, Escarole, Okra, Scallion, Spinach, Tomato, Apricot, Cantaloupe, Coconut, Fig, Guava, Persimmon, Raspberry, Strawberry, Red lentil, Almond, Pecan, Pistachio, Brown rice, Millet, Cabbage, Cauliflower, Celery, Collard, Cucumber, Daikon, Garlic, Ginger, Leek, Mustard greens, Onion, Parsnip, Pumpkin, Radish, Squash, Sweet potato, Watercress, Apple, Date, Peach, Pear, Raisin, Chickpea, Great northern bean, Navy bean, Hickory, Pine nut, Walnut, Mint, Peppermint, Arugula (rocket), Banana, Bean sprouts, Bok choy, Bulgur, Canned tomatoes, Celeriac, Chia seeds, Chili pepper, Cranberry, Dried apricots, Edamame, Farro, Fava (broad) beans, Fennel, Grapes, Green bell pepper, Guacamole, Hazelnuts, Hemp seeds, Honeydew melon, Kiwi, Kohlrabi, Macadamia nuts, Mandarin / tangerine, Mango, Napa cabbage, Nectarine, Oat bran, Papaya, Peanuts, Pineapple, Pinto beans, Plantain, Prunes (dried plums), Radicchio, Red cabbage, Salsa, Shallot, Sugar snap peas, Sweet cherry, Turnip, White beans, White potato, Yellow bell pepper, Basil, Cilantro (coriander), Dill, Tomato paste.

## Quality notes
The three photos are good crops but come from three different photographers and
light styles; a consistent set (original or reviewed AI-generated, rights confirmed)
would look more coherent than mixing stock photos.

## Plan
Phase D: produce a first batch for the highest-use plants (about 30), each a single,
accurate subject on a plain background, reviewed by the owner and credited. Keep the
fallback until each asset exists.
