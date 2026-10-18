import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';

/// A small, stable string hash (FNV-1a), so a pick never changes between
/// rebuilds, launches or platforms.
int stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// The recipes of the real phase that the user can eat and that use [food]
/// as a key ingredient, in the stored order.
final recipesForFoodProvider = Provider.family<List<Recipe>, String>((
  ref,
  foodId,
) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final phase = ref.watch(actualPhaseProvider);
  return [
    for (final r in catalogue.recipesFor(phase))
      if (r.keyFoodIds.contains(foodId) && filter.allowsRecipe(r, catalogue)) r,
  ];
});

/// The real phase's featured foods the user eats, preferring those with at
/// least one recipe they can cook. Never depends on the phase being browsed.
final todaysPoolProvider = Provider<List<Food>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final phase = ref.watch(actualPhaseProvider);
  final foods = [
    for (final f in catalogue.foodsFor(phase))
      if (filter.allowsFood(f)) f,
  ];
  final cookable = [
    for (final f in foods)
      if (ref.watch(recipesForFoodProvider(f.id)).isNotEmpty) f,
  ];
  return cookable.isEmpty ? foods : cookable;
});

/// "Today's food": one food featured in the **real** phase, the same all day.
///
/// The pool is put in an order fixed by the cycle (seeded by the day the
/// cycle started) and the pick walks along it one food per day of the phase,
/// so:
/// - a food never repeats within a phase while the pool is longer than the
///   phase (a late period keeps walking, it doesn't restart);
/// - the next cycle has a new order, so a given cycle day gets a different
///   food;
/// - it changes with the date only, never with the screen or browsing;
/// - irregular or edited cycle lengths just move the starting day;
/// - with no cycle start known it falls back to the calendar date.
final todaysFoodProvider = Provider<Food?>((ref) {
  final pool = ref.watch(todaysPoolProvider);
  if (pool.isEmpty) return null;
  final phase = ref.watch(actualPhaseProvider);
  final cycle = ref.watch(cycleStateProvider).value;
  final today = ref.watch(todayProvider);

  final seed = stableHash(
    '${cycle?.lastPeriodStart ?? 'unknown'}|${phase.name}',
  );
  final ordered = [...pool]
    ..sort((a, b) {
      final byHash = stableHash('$seed|${a.id}') - stableHash('$seed|${b.id}');
      return byHash != 0 ? byHash : a.id.compareTo(b.id);
    });
  final step = cycle == null
      ? LocalDate(1970, 1, 1).daysUntil(today)
      : cycle.cycleDay - cycle.ranges.of(phase).firstDay;
  return ordered[step % ordered.length];
});
