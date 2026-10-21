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
  bool all = false,
  bool mealInScope = true,
}) => RecipeList(
  phase: Phase.follicular,
  all: all,
  mealInScope: mealInScope,
  filter: RecipeFilter(mealType: meal, foodId: food),
  recipes: testCatalogue.recipesFor(Phase.follicular).take(shown).toList(),
  fitPreferences: fit,
  withFoodAnyMeal: withFood,
  mealTypes: MealType.values,
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
    final snacks = recipesEmptyCopy(
      list(meal: MealType.snacks, mealInScope: false),
    )!;
    expect(snacks.title, 'No follicular snacks *yet*');
    expect(
      snacks.body,
      'There aren’t any snack recipes for this phase yet. '
      'Try another meal type.',
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

  test('a meal type that exists but is filtered out by preferences', () {
    for (final (meal, noun) in [
      (MealType.breakfast, 'breakfast'),
      (MealType.meals, 'meal'),
      (MealType.snacks, 'snack'),
    ]) {
      for (final all in [false, true]) {
        final copy = recipesEmptyCopy(list(meal: meal, all: all))!;
        expect(copy.title, 'Nothing fits your *preferences*');
        expect(
          copy.body,
          'No $noun recipes match your current preferences. '
          'Try another meal type or review your food preferences.',
        );
        expect(copy.actions, [
          EmptyAction.showAllMealTypes,
          EmptyAction.reviewPreferences,
        ]);
        expect(copy.body, isNot(contains('None of')));
      }
    }
  });

  test('none exist in the scope: the plain "not yet" wording', () {
    for (final (meal, noun) in [
      (MealType.breakfast, 'breakfast'),
      (MealType.meals, 'meal'),
      (MealType.snacks, 'snack'),
    ]) {
      final phase = recipesEmptyCopy(list(meal: meal, mealInScope: false))!;
      expect(
        phase.body,
        'There aren’t any $noun recipes for this phase yet. '
        'Try another meal type.',
      );
      final all = recipesEmptyCopy(
        list(meal: meal, all: true, mealInScope: false),
      )!;
      expect(
        all.body,
        'There aren’t any $noun recipes yet. Try another meal type.',
      );
    }
  });

  test('merge and skip notes', () {
    final tray = testCatalogue.recipe('lemon-chicken-green-bean-tray')!;
    final lines = tray.ingredients;
    expect(mergeNote(const []), isNull);
    expect(
      mergeNote([lines[1], lines[3], lines[4]]),
      'Green beans, lemon and garlic are already on your list. We’ll merge '
      'them, not add them twice.',
    );
    expect(
      mergeNote([lines[3]]),
      'Lemon is already on your list. We’ll merge it, not add it twice.',
    );
    expect(
      skipNote([lines[5]]),
      'We’ll leave out olive oil: it’s on your avoid list.',
    );
  });
}
