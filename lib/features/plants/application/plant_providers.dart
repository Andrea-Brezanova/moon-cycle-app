import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../foods/application/food_providers.dart';
import '../../home/application/home_providers.dart' show homeShownDayProvider;
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

/// The phase and cycle day the three plants are for: today's, or, when Home's
/// cycle wheel has been moved to another day (or a phase was chosen), that day.
/// A preview only: it reads the wheel, it never changes the stored cycle, the
/// diary, saved plants or the shopping list.
final plantsDayProvider = Provider<({Phase phase, int day, bool preview})>((
  ref,
) {
  final actual = ref.watch(actualPhaseProvider);
  final cycle = ref.watch(cycleStateProvider).value;
  if (cycle == null) return (phase: actual, day: 0, preview: false);
  final shown = ref.watch(homeShownDayProvider);
  if (shown == null) {
    return (phase: actual, day: cycle.cycleDay, preview: false);
  }
  return (phase: cycle.ranges.forDay(shown).phase, day: shown, preview: true);
});

/// The eligible plants of the day's phase that the user eats (diet and
/// avoidances applied).
final plantPoolProvider = Provider<List<Food>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final phase = ref.watch(plantsDayProvider.select((d) => d.phase));
  return [
    for (final f in catalogue.foodsFor(phase))
      if (isDiscoveryPlant(f) && filter.allowsFood(f)) f,
  ];
});

/// The day's three plants: distinct, from that day's phase, the same every
/// time the day is shown, and different from day to day (see
/// [dailyPlantIds]). Independent of "Today's food" on the Foods page.
final threePlantsProvider = Provider<List<Food>>((ref) {
  final pool = ref.watch(plantPoolProvider);
  final day = ref.watch(plantsDayProvider);
  final cycle = ref.watch(cycleStateProvider).value;
  final today = ref.watch(todayProvider);
  // Days along the phase from the cycle; with no cycle start, calendar days.
  final dayIndex = cycle == null
      ? LocalDate(1970, 1, 1).daysUntil(today)
      : day.day - cycle.ranges.of(day.phase).firstDay;
  final ids = dailyPlantIds(
    poolIds: [for (final f in pool) f.id],
    seed: '${cycle?.lastPeriodStart ?? 'unknown'}|${day.phase.name}|plants',
    dayIndex: dayIndex,
  );
  return [for (final id in ids) pool.firstWhere((f) => f.id == id)];
});

/// Which of today's plants the user has picked.
final plantPicksProvider =
    NotifierProvider.autoDispose<PlantPicks, Set<String>>(PlantPicks.new);

class PlantPicks extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Picks belong to the plants shown: a different day starts afresh.
    ref.watch(
      threePlantsProvider.select((l) => [for (final f in l) f.id].join(',')),
    );
    return const {};
  }

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}
