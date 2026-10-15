import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/application/recipe_list.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_copy.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preferences remove every breakfast: it exists, so say that', () {
    final breakfasts = [
      for (final r in testCatalogue.recipesFor(Phase.follicular))
        if (r.mealType == MealType.breakfast) r,
    ];
    expect(breakfasts, isNotEmpty);
    // Avoid one ingredient from every follicular breakfast.
    final avoided = {
      for (final r in breakfasts)
        r.ingredients.firstWhere((l) => l.foodId != null).foodId!,
    };
    final container = ProviderContainer(
      overrides: [
        catalogueProvider.overrideWithValue(testCatalogue),
        actualPhaseProvider.overrideWithValue(Phase.follicular),
        foodFilterProvider.overrideWithValue(
          FoodFilter(
            avoidances: [
              for (final id in avoided)
                FoodItemAvoidance(id: 'a-$id', foodId: id),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(recipeFilterProvider.notifier)
        .setMealType(MealType.breakfast);

    final list = container.read(recipeListProvider);
    expect(list.filter.mealType, MealType.breakfast);
    expect(list.recipes, isEmpty);
    expect(list.mealInScope, isTrue);
    final copy = recipesEmptyCopy(list)!;
    expect(
      copy.body,
      startsWith('No breakfast recipes match your current preferences.'),
    );
  });
}
