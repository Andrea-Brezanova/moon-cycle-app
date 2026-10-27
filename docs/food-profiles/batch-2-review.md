# Draft batch 2: what an editor must check (nothing here is published)

Twelve foods: apple, banana, avocado, strawberry, cauliflower, cabbage, pumpkin, walnut,
brown rice, cucumber, red bell pepper, green pea. Same method as batch 1 (see
`batch-1-review.md`): USDA FoodData Central values and household measures read on
26 Oct 2026, recomputed by `build_draft_batch.py 2`, re-checked by
`test/content/food_profile_drafts_test.dart`. Output: `draft-batch-2.json`, every profile
`publishable: false`.

## Sourced
- Composition, preparation state and serving weight of each USDA record.
- Cautions: vitamin K for cabbage (NIH ODS Vitamin K, as in the approved broccoli profile);
  nuts and oxalate for walnut (NIDDK page).

## Please check
- Tips in "How to eat it" and descriptive phrases ("exceptional source", "creamy") are
  unsourced editorial wording.
- Avocado serving is one third of a fruit (USDA NLEA serving, 50 g): confirm it feels
  realistic. Cucumber uses USDA's single 85 g measure. Apple is the generic SR Legacy
  record with skin (the Foundation records are single varieties).
- Cooked or raw is stated in each profile's preparation state; nothing mixes the two.
