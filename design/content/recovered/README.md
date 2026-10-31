# Sample recipe text removed

The twelve sample recipes that used to be here (`emergent-recipes.json`) and the three recipe CSVs derived from them (`recipe-data-template/recipes.csv`, `recipe_ingredients.csv`, `recipe_steps.csv`) were removed from the current tree on 31 Oct 2026. They were AI-generated sample content with no recorded licence for the wording. The app never used them: `design/` is not bundled, and the shipped library is the 112-recipe `assets/content/recipes.json`.

- The twelve legacy recipe ids are still checked by `test/content/content_validation_test.dart` (they must not appear in the shipped library); the ids are written into that test.
- The earlier files remain in Git history. No history was rewritten.
- Other files in `design/content/` (ingredient copy, classification, sample UI content, food shopping and safety CSV) are unchanged.
