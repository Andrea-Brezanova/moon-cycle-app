import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/phase_content.dart';

/// For each food, how many of [phase]'s recipes use it as a key ingredient,
/// counting only recipes the user's preferences allow (what Recipes shows).
final recipeCountsProvider = Provider.family<Map<String, int>, Phase>((
  ref,
  phase,
) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final counts = <String, int>{};
  for (final recipe in catalogue.recipesFor(phase)) {
    if (!filter.allowsRecipe(recipe, catalogue)) continue;
    for (final id in recipe.keyFoodIds.toSet()) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
});

/// For each food, how many of all recipes use it as a key ingredient,
/// counting only recipes the user's preferences allow ("All foods").
final allRecipeCountsProvider = Provider<Map<String, int>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final counts = <String, int>{};
  for (final recipe in catalogue.recipes) {
    if (!filter.allowsRecipe(recipe, catalogue)) continue;
    for (final id in recipe.keyFoodIds.toSet()) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
});

/// The whole searchable catalogue grouped by each food's own category (stored
/// category order), foods A–Z within each, whether or not any phase features
/// it. Empty categories are left out; avoided foods are not removed here.
final allFoodsByCategoryProvider = Provider<List<(FoodCategory, List<Food>)>>((
  ref,
) {
  final catalogue = ref.watch(catalogueProvider);
  final byCategory = <String, List<Food>>{};
  for (final food in catalogue.foods) {
    byCategory.putIfAbsent(catalogue.categoryFor(food).id, () => []).add(food);
  }
  return [
    for (final category in catalogue.categories)
      if (byCategory[category.id] case final foods? when foods.isNotEmpty)
        (
          category,
          foods..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          ),
        ),
  ];
});
