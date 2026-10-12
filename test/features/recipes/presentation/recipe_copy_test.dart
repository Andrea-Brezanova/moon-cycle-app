import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/application/recipe_list.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_copy.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../../helpers/test_catalogue.dart';

RecipeList list({
  int shown = 0,
  int fit = 3,
  int withFood = 0,
  MealType? meal,
  String? food,
}) => RecipeList(
  phase: Phase.follicular,
  filter: RecipeFilter(mealType: meal, foodId: food),
  recipes: testCatalogue.recipesFor(Phase.follicular).take(shown).toList(),
  fitPreferences: fit,
  withFoodAnyMeal: withFood,
);

void main() {
  test('count lines', () {
    expect(recipeCountLine(list(shown: 3)), '3 follicular recipes');
    expect(
      recipeCountLine(list(shown: 1, food: 'chicken'), foodName: 'chicken'),
      '1 follicular recipe with chicken',
    );
    expect(recipeCountLine(list(meal: MealType.snacks)), '0 follicular snacks');
    expect(
      recipeCountLine(
        list(meal: MealType.breakfast, food: 'x'),
        foodName: 'chicken',
      ),
      '0 follicular breakfasts with chicken',
    );
  });

  test('empty states, as designed', () {
    expect(recipesEmptyCopy(list(shown: 1)), isNull);
    final snacks = recipesEmptyCopy(list(meal: MealType.snacks))!;
    expect(snacks.title, 'No follicular snacks *yet*');
    expect(
      snacks.body,
      'None of this phase’s recipes is a snack. Try another meal type.',
    );
    expect(snacks.actions, [EmptyAction.showAllMealTypes]);

    final breakfast = recipesEmptyCopy(
      list(meal: MealType.breakfast, food: 'chicken', withFood: 1),
      foodName: 'chicken',
    )!;
    expect(breakfast.title, 'No breakfasts with *chicken*');
    expect(
      breakfast.body,
      'There’s a follicular recipe with chicken in another meal type.',
    );
    expect(breakfast.actions, [
      EmptyAction.showAllMealTypes,
      EmptyAction.clearIngredient,
    ]);

    final none = recipesEmptyCopy(list(food: 'rye'), foodName: 'rye')!;
    expect(none.title, 'No follicular recipes with *rye*');
    expect(none.actions, [EmptyAction.clearIngredient]);

    final prefs = recipesEmptyCopy(list(fit: 0))!;
    expect(prefs.title, 'Nothing fits your *preferences*');
    expect(prefs.actions, [EmptyAction.reviewPreferences]);
  });

  test('merge and skip notes', () {
    final zesty = testCatalogue.recipe('zesty-lentil-broccoli-bowl')!;
    final lines = zesty.ingredients;
    expect(mergeNote(const []), isNull);
    expect(
      mergeNote([lines[1], lines[3], lines[7]]),
      'Broccoli, lemon and sauerkraut are already on your list. We’ll merge '
      'them, not add them twice.',
    );
    expect(
      mergeNote([lines[3]]),
      'Lemon is already on your list. We’ll merge it, not add it twice.',
    );
    expect(
      skipNote([lines[6]]),
      'We’ll leave out olive oil: it’s on your avoid list.',
    );
  });
}
