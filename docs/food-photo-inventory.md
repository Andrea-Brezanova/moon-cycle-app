# Food photo inventory (3 Plants a Day)

Eligible = `isDiscoveryPlant` (vegetables, fruit, legumes, whole grains, nuts and
seeds; no herbs or processed foods). Every food belongs to exactly one phase,
so there is no overlap.

| Phase | Eligible | With photo | Missing |
|---|---|---|---|
| Follicular (current in dev) | 20 | 1 (avocado) | 19 |
| Ovulatory | 23 | 0 | 23 |
| Luteal | 25 | 0 | 25 |
| Menstrual | 26 | 2 (broccoli, blueberry) | 24 |
| **Total unique** | **94** | **3** | **91** |

Eligible by category: vegetables 35, fruit 26, legumes 11, nuts and seeds 13,
whole grains 9 (see lists below for each phase).

## Proposed sourcing strategy
1. **Order:** the user's current phase first, then the next phase in the cycle,
   so photos arrive before they are needed: follicular, ovulatory, luteal, menstrual.
2. **Source:** Unsplash (or Pexels), one photo per food, plain background so the
   multiply tone treatment works. Record photographer, source URL, licence and
   attribution wording per photo in `docs/photo-credits.md`; the in-app
   Credits & Sources page reads the same list.
3. **Size:** about 600 px square, JPEG quality 75, roughly 30-40 KB each, so all 94
   add about 3-4 MB. One file per food id in `assets/images/foods/<food-id>.jpg`,
   mapped in `plant_photos.dart`; the same file serves Home, Eat and Food Detail.
4. **Batches:** about 20 photos per batch (one phase), reviewed before the next.
5. **Fallback:** foods without a photo keep the emoji tile.

## Eligible foods by phase
### Follicular: 20 eligible, 1 with a photo

- `farro` Farro (grains)
- `oat-bran` Oat bran (grains)
- `arugula` Arugula (vegetables)
- `bok-choy` Bok choy (vegetables)
- `cabbage` Cabbage (vegetables)
- `carrot` Carrot (vegetables)
- `green-pea` Green pea (vegetables)
- `lettuce` Lettuce (vegetables)
- `napa-cabbage` Napa cabbage (vegetables)
- `string-bean` String bean (vegetables)
- `turnip` Turnip (vegetables)
- `zucchini` Zucchini (vegetables)
- `avocado` Avocado (fruit) ✔ photo
- `nectarine` Nectarine (fruit)
- `plum` Plum (fruit)
- `pomegranate` Pomegranate (fruit)
- `black-eyed-pea` Black-eyed pea (legumes)
- `brazil-nut` Brazil nut (nuts-seeds)
- `flaxseeds` Flaxseeds (nuts-seeds)
- `pecan` Pecan (nuts-seeds)

### Ovulatory: 23 eligible, 0 with a photo

- `asparagus` Asparagus (vegetables)
- `bean-sprouts` Bean sprouts (vegetables)
- `celery` Celery (vegetables)
- `cucumber` Cucumber (vegetables)
- `radish` Radish (vegetables)
- `red-bell-pepper` Red bell pepper (vegetables)
- `red-cabbage` Red cabbage (vegetables)
- `sugar-snap-peas` Sugar snap peas (vegetables)
- `tomato` Tomato (vegetables)
- `apricot` Apricot (fruit)
- `cantaloupe` Cantaloupe (fruit)
- `honeydew` Honeydew melon (fruit)
- `mandarin` Mandarin / tangerine (fruit)
- `mango` Mango (fruit)
- `peach` Peach (fruit)
- `pineapple` Pineapple (fruit)
- `raspberry` Raspberry (fruit)
- `strawberry` Strawberry (fruit)
- `sweet-cherry` Sweet cherry (fruit)
- `watermelon` Watermelon (fruit)
- `almond` Almond (nuts-seeds)
- `hazelnuts` Hazelnuts (nuts-seeds)
- `pistachio` Pistachio (nuts-seeds)

### Luteal: 25 eligible, 0 with a photo

- `barley` Barley (grains)
- `brown-rice` Brown rice (grains)
- `buckwheat` Buckwheat (grains)
- `bulgur` Bulgur (grains)
- `oat` Oat (grains)
- `artichoke` Artichoke (vegetables)
- `cauliflower` Cauliflower (vegetables)
- `parsnip` Parsnip (vegetables)
- `pumpkin` Pumpkin (vegetables)
- `squash` Squash (vegetables)
- `apple` Apple (fruit)
- `banana` Banana (fruit)
- `blackberry` Blackberry (fruit)
- `fig` Fig (fruit)
- `pear` Pear (fruit)
- `chickpea` Chickpea (legumes)
- `edamame` Edamame (legumes)
- `lima-bean` Lima bean (legumes)
- `pinto-beans` Pinto beans (legumes)
- `red-lentil` Red lentil (legumes)
- `split-pea` Split pea (legumes)
- `chia-seeds` Chia seeds (nuts-seeds)
- `peanuts` Peanuts (nuts-seeds)
- `sunflower-seeds` Sunflower seeds (nuts-seeds)
- `walnut` Walnut (nuts-seeds)

### Menstrual: 26 eligible, 2 with a photo

- `quinoa` Quinoa (grains)
- `wild-rice` Wild rice (grains)
- `beets` Beets (vegetables)
- `broccoli` Broccoli (vegetables) ✔ photo
- `brussels-sprouts` Brussels sprouts (vegetables)
- `chard` Chard (vegetables)
- `collard` Collard (vegetables)
- `eggplant` Eggplant (vegetables)
- `green-bell-pepper` Green bell pepper (vegetables)
- `kale` Kale (vegetables)
- `mushrooms` Mushrooms (vegetables)
- `spinach` Spinach (vegetables)
- `yellow-bell-pepper` Yellow bell pepper (vegetables)
- `blueberry` Blueberry (fruit) ✔ photo
- `grapefruit` Grapefruit (fruit)
- `grapes` Grapes (fruit)
- `kiwi` Kiwi (fruit)
- `orange` Orange (fruit)
- `papaya` Papaya (fruit)
- `black-turtle-bean` Black beans (legumes)
- `kidney-bean` Kidney bean (legumes)
- `green-lentil` Lentils (legumes)
- `white-beans` White beans (legumes)
- `cashew` Cashew (nuts-seeds)
- `pumpkin-seeds` Pumpkin seeds (nuts-seeds)
- `sesame-seeds` Sesame seeds (nuts-seeds)

