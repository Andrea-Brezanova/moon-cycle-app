import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../foods/application/food_providers.dart';
import '../domain/daily_plants.dart';

/// Whole grains that count as a plant to discover (refined grains, breads,
/// pasta, noodles and cereals do not).
const _wholeGrainIds = {
  'amaranth',
  'barley',
  'brown-rice',
  'buckwheat',
  'bulgur',
  'farro',
  'millet',
  'oat',
  'oat-bran',
  'quinoa',
  'rye',
  'wild-rice',
};

/// Prepared or processed foods in plant categories.
const _processedIds = {
  'baked-beans',
  'hummus',
  'mixed-nuts',
  'nut-butter',
  'tahini',
};

/// Whether [food] makes sense as "a plant to discover": a vegetable or fruit,
/// a legume, a whole grain, or a nut or seed. Not herbs, refined or prepared
/// products, oils, or foods of another kind (meat, dairy, ferments).
bool isDiscoveryPlant(Food food) {
  if (isHerb(food) || _processedIds.contains(food.id)) return false;
  return switch (food.categoryId) {
    'vegetables' || 'fruit' => isMealPlant(food),
    'legumes' || 'nuts-seeds' => true,
    'grains' => _wholeGrainIds.contains(food.id),
    _ => false,
  };
}

/// The eligible plants of the user's **real** phase that they eat (diet and
/// avoidances applied). Never depends on the phase being browsed.
final plantPoolProvider = Provider<List<Food>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final phase = ref.watch(actualPhaseProvider);
  return [
    for (final f in catalogue.foodsFor(phase))
      if (isDiscoveryPlant(f) && filter.allowsFood(f)) f,
  ];
});

/// Today's three plants: distinct, from the real phase, the same all day, and
/// different from day to day (see [dailyPlantIds]). Independent of "Today's
/// food" on the Foods page.
final threePlantsProvider = Provider<List<Food>>((ref) {
  final pool = ref.watch(plantPoolProvider);
  final phase = ref.watch(actualPhaseProvider);
  final cycle = ref.watch(cycleStateProvider).value;
  final today = ref.watch(todayProvider);
  // Days along the phase from the cycle; with no cycle start, calendar days.
  final dayIndex = cycle == null
      ? LocalDate(1970, 1, 1).daysUntil(today)
      : cycle.cycleDay - cycle.ranges.of(phase).firstDay;
  final ids = dailyPlantIds(
    poolIds: [for (final f in pool) f.id],
    seed: '${cycle?.lastPeriodStart ?? 'unknown'}|${phase.name}|plants',
    dayIndex: dayIndex,
  );
  return [for (final id in ids) pool.firstWhere((f) => f.id == id)];
});

/// Which of today's plants the user has picked.
final plantPicksProvider =
    NotifierProvider.autoDispose<PlantPicks, Set<String>>(PlantPicks.new);

class PlantPicks extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}
