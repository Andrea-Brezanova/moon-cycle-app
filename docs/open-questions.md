# Open questions

Only decisions that are genuinely yours. Each has the default the build uses until you decide, so nothing waits on it. Newest first.

| # | Question | Default in the build | Needed before |
|---|---|---|---|
| 6 | **Quantities on the shopping list.** The Shop rows in the design show no quantity, so recipe amounts ("150 g", merged "1.2 kg") are kept but not shown. Show them in the source line, e.g. "Lemon Herb Chicken · 150 g"? | Not shown, as designed | Release (nice to have) |
| 5 | **Recipe photos.** The 12 recovered recipes link to Unsplash photos (Unsplash License: free commercial use; credits optional). Bundling them means downloading them into the app. May I download and bundle them, and should the app credit the photographers? | Tinted placeholders (spec §6) | Release |
| 4 | **Allergen, diet and aisle data** for the 157 foods and 7 non-catalogue recipe lines is a draft (`assets/content/README.md`). Allergy filtering is safety-relevant: who reviews it? | Conservative draft: over-marks (e.g. oats, miso, tamari as gluten; chocolate as dairy and soy; coconut as tree nut; plant milk as soy, tree nut and gluten) | Release |
| 3 | **Recipe content flags** (23, `design/content/RECIPE-DATA-NEEDED.md`): two intros make health claims ("iron-supporting", "to steady cravings"), salt and oil missing from some lists, can sizes, coconut milk → Coconut mapping | Recipes ship verbatim as recovered | Release |
| 2 | **Food content flags** (26, `ingredients.json` › `dataQualityFlags`): Lychee under Nuts & seeds, Eggs under Meat, iodine and safety notes | Placement and copy exactly as exported; the 4 not-ship-ready foods hidden | Release |
| 1 | Tab bar labels at large text sizes (`design-deviations.md` #10) | Labels stay 11 pt | Release |
