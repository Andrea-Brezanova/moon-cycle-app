import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';

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
