import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../foods/application/todays_food.dart';

/// One suggestion in "Try something new": a food and an existing recipe that
/// really uses it.
///
/// The experience is a list of these. Today it is three (Today's food plus two
/// more, one recipe each). A future generation-based version can return three
/// foods with three recipes that each use all of them, and the screen that
/// shows the list does not change.
final class DiscoverySuggestion {
  const DiscoverySuggestion({
    required this.food,
    required this.recipe,
    this.isTodaysFood = false,
  });

  final Food food;
  final Recipe recipe;
  final bool isTodaysFood;
}

/// The recipe suggested for [food]: one of the real phase's recipes that use
/// it, chosen by the date (so it is stable for the day).
final _recipeForProvider = Provider.family<Recipe?, String>((ref, foodId) {
  final recipes = ref.watch(recipesForFoodProvider(foodId));
  if (recipes.isEmpty) return null;
  final today = ref.watch(todayProvider);
  return recipes[stableHash('recipe|$today|$foodId') % recipes.length];
});

/// Pages of suggestions for the real phase. Every page starts with Today's
/// food, then two other featured foods, from different categories where the
/// phase has them, each with a recipe that uses it. "Show me more" moves to
/// the next page; the pages wrap around.
final tryNewPagesProvider = Provider<List<List<DiscoverySuggestion>>>((ref) {
  final todays = ref.watch(todaysFoodProvider);
  if (todays == null) return const [];
  final todaysRecipe = ref.watch(_recipeForProvider(todays.id));
  if (todaysRecipe == null) return const [];
  final catalogue = ref.watch(catalogueProvider);
  final today = ref.watch(todayProvider);

  // Other foods that have a recipe, grouped by category.
  final byCategory = <String, List<Food>>{};
  for (final food in ref.watch(todaysPoolProvider)) {
    if (food.id == todays.id) continue;
    if (ref.watch(_recipeForProvider(food.id)) == null) continue;
    byCategory.putIfAbsent(food.categoryId, () => []).add(food);
  }
  final lanes = [for (final c in catalogue.categories) ?byCategory[c.id]];
  if (lanes.isEmpty) return const [];
  final seed = stableHash('try|$today');
  final queues = [
    for (final (i, lane) in lanes.indexed)
      [
        ...lane.skip((seed + i) % lane.length),
        ...lane.take((seed + i) % lane.length),
      ],
  ];
  final turn = seed % queues.length;
  final ordered = [...queues.skip(turn), ...queues.take(turn)];

  // Pairs from the categories with the most foods left, so a page's two extra
  // foods differ in category whenever two categories remain.
  final pairs = <List<Food>>[];
  while (ordered.any((q) => q.isNotEmpty)) {
    final live = [
      for (final q in ordered)
        if (q.isNotEmpty) q,
    ]..sort((a, b) => b.length - a.length);
    pairs.add([for (final q in live.take(2)) q.removeAt(0)]);
  }
  // A last pair of one borrows a food from an earlier pair.
  final all = [for (final p in pairs) ...p];
  if (all.length >= 2) {
    for (final pair in pairs) {
      for (final f in all) {
        if (pair.length >= 2) break;
        if (!pair.any((o) => o.id == f.id)) pair.add(f);
      }
    }
  }

  return [
    for (final pair in pairs)
      [
        DiscoverySuggestion(
          food: todays,
          recipe: todaysRecipe,
          isTodaysFood: true,
        ),
        for (final f in pair)
          DiscoverySuggestion(
            food: f,
            recipe: ref.watch(_recipeForProvider(f.id))!,
          ),
      ],
  ];
});

/// Page [page] of [pages], wrapping around.
List<DiscoverySuggestion> suggestionPage(
  List<List<DiscoverySuggestion>> pages,
  int page,
) => pages.isEmpty ? const [] : pages[page % pages.length];
