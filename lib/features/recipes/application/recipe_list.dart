import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/browse_scope.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/viewing_phase.dart';
import 'recipe_filter.dart';
import 'recipes_scope.dart';

/// What the Recipes list shows, and what its empty states need to know.
final class RecipeList {
  const RecipeList({
    required this.phase,
    this.all = false,
    required this.filter,
    required this.recipes,
    required this.fitPreferences,
    required this.withFoodAnyMeal,
  });

  /// The shared viewing phase (also the phase "Cook with…" lists foods for).
  final Phase phase;

  /// "All recipes": every phase's recipes, not just [phase]'s.
  final bool all;
  final RecipeFilter filter;

  /// After every filter, in the stored order (the first is featured).
  final List<Recipe> recipes;

  /// The phase's recipes the user's preferences allow, any meal type.
  final int fitPreferences;

  /// Of those, how many use the "Cook with…" food, any meal type.
  final int withFoodAnyMeal;
}

final recipeListProvider = Provider<RecipeList>((ref) {
  final phase = ref.watch(viewingPhaseProvider);
  final all = ref.watch(recipesScopeProvider) == BrowseScope.all;
  final filter = ref.watch(recipeFilterProvider);
  final catalogue = ref.watch(catalogueProvider);
  final prefs = ref.watch(foodFilterProvider);
  final fit = [
    for (final r in all ? catalogue.recipes : catalogue.recipesFor(phase))
      if (prefs.allowsRecipe(r, catalogue)) r,
  ];
  final withFood = filter.foodId == null
      ? fit
      : [
          for (final r in fit)
            if (r.keyFoodIds.contains(filter.foodId)) r,
        ];
  return RecipeList(
    phase: phase,
    all: all,
    filter: filter,
    recipes: [
      for (final r in withFood)
        if (filter.mealType == null || r.mealType == filter.mealType) r,
    ],
    fitPreferences: fit.length,
    withFoodAnyMeal: withFood.length,
  );
});
