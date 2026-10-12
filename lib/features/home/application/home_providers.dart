import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/cycle_providers.dart';

/// The day Home's moon is previewing after a drag, or null for today.
/// Local to Home: nothing else follows it (PRD §7).
final homePreviewProvider = NotifierProvider<HomePreview, int?>(
  HomePreview.new,
);

class HomePreview extends Notifier<int?> {
  @override
  int? build() {
    // A new day (or a logged period) ends any preview.
    ref.watch(cycleStateProvider.select((s) => s.value?.cycleDay));
    return null;
  }

  /// Previews [day] of the cycle; previewing today is the same as none.
  void preview(int day) {
    final today = ref.read(cycleStateProvider).value?.orbitDay;
    state = day == today ? null : day;
  }

  void backToToday() => state = null;
}

/// "Foods for today": up to six foods, the first the user eats from each
/// category, in the stored order (PRD §7).
final foodsForTodayProvider = Provider.family<List<Food>, Phase>((ref, phase) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  return [
    for (final category in catalogue.phase(phase).categories)
      ?category.foodIds
          .map(catalogue.food)
          .whereType<Food>()
          .where(filter.allowsFood)
          .firstOrNull,
  ].take(6).toList();
});

/// "Recipes for today": the phase's recipes the user's preferences allow,
/// in the stored order.
final recipesForTodayProvider = Provider.family<List<Recipe>, Phase>((
  ref,
  phase,
) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  return [
    for (final r in catalogue.recipesFor(phase))
      if (filter.allowsRecipe(r, catalogue)) r,
  ];
});
