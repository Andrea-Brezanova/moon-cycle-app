# Draft batch 1: what an editor must check (nothing here is published)

Twelve foods, drafted from USDA FoodData Central values read on 26 Oct 2026 and the NIH
ODS reference intakes already used for the five approved profiles:
kale, sweet potato, beets, carrot, chickpea, quinoa, almond, flaxseeds, blueberry, tomato,
oat, chia seeds. Output: `draft-batch-1.json` (every profile `publishable: false`).

## Verified from a source
- Composition, preparation state and household measure of each USDA record (the script
  recomputes every serving amount and percentage; a test re-checks them).
- Reference intakes: as in the approved profiles (NIH ODS, adult women).
- Almond: "nuts and nut products" are listed by NIDDK among foods to reduce for calcium
  oxalate stones (page read 26 Oct 2026). Kale: vitamin K and warfarin, as in the approved
  broccoli profile (NIH ODS Vitamin K).

## Not sourced: please accept, change or remove
- Preparation tips in "How to eat it" (e.g. massaging kale, grinding flaxseed, cooking carrots
  with a little fat for beta-carotene absorption, soaking chia before eating).
- Descriptive phrases ("excellent source", "rich in fibre", beta-glucan in oats).
- Every "cycle relevance" sentence is a no-claim statement; no profile links a food to a
  phase or to symptoms.
- Cautions not yet added, to be decided: tree-nut allergy (almond) and seed-related notes.
  Allergens are already handled by the app's food exclusions.

## Open choices
- Serving sizes use USDA household measures or reference amounts; confirm they feel realistic.
- Oats are for dry oats before cooking (the label says so); a cooked-porridge record could
  replace it.
