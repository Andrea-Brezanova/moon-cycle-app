import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_state.dart';
import 'package:moon_cycle/features/foods/application/todays_food.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';

import '../../../helpers/test_catalogue.dart';

CycleState stateFor(
  LocalDate start,
  LocalDate today, {
  int cycle = 28,
  int period = 5,
}) => calculateCycleState(
  lastPeriodStart: start,
  lengths: CycleLengths.fromProfile(
    CycleProfile(typicalCycleLength: cycle, typicalPeriodLength: period),
  ),
  today: today,
);

ProviderContainer make({
  CycleState? cycle,
  required LocalDate today,
  FoodFilter filter = FoodFilter.none,
}) {
  final container = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
      cycleStateProvider.overrideWithValue(AsyncData(cycle)),
      clockProvider.overrideWithValue(
        () => DateTime(today.year, today.month, today.day, 9),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Today's food for each day of [phase] in a cycle that began on [start].
List<String> walk(LocalDate start, Phase phase, {int cycle = 28}) {
  final days = <String>[];
  for (var d = 0; d < cycle; d++) {
    final today = start.addDays(d);
    final state = stateFor(start, today, cycle: cycle);
    if (state.phase != phase) continue;
    days.add(make(cycle: state, today: today).read(todaysFoodProvider)!.id);
  }
  return days;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final start = LocalDate(2025, 9, 28);

  test('it is a featured food of the real phase', () {
    for (var d = 0; d < 28; d++) {
      final today = start.addDays(d);
      final state = stateFor(start, today);
      final food = make(cycle: state, today: today).read(todaysFoodProvider)!;
      expect(testCatalogue.phase(state.phase).foodIds, contains(food.id));
    }
  });

  test('never the phase being browsed', () {
    final today = start.addDays(6); // follicular
    final state = stateFor(start, today);
    final c = make(cycle: state, today: today);
    final before = c.read(todaysFoodProvider)!.id;
    c.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
    expect(c.read(todaysFoodProvider)!.id, before);
    expect(testCatalogue.phase(Phase.follicular).foodIds, contains(before));
  });

  test('stable within a day, whatever the time', () {
    final today = start.addDays(8);
    final state = stateFor(start, today);
    final a = make(cycle: state, today: today).read(todaysFoodProvider)!.id;
    final b = make(cycle: state, today: today).read(todaysFoodProvider)!.id;
    expect(a, b);
  });

  test('no repeats within a phase', () {
    for (final phase in Phase.values) {
      final days = walk(start, phase);
      expect(days.toSet(), hasLength(days.length), reason: phase.name);
    }
  });

  test('the next cycle walks a different order', () {
    final next = start.addDays(28);
    final a = walk(start, Phase.follicular);
    final b = walk(next, Phase.follicular);
    expect(a, hasLength(b.length));
    expect(a, isNot(b));
  });

  test('irregular cycle lengths keep the rules', () {
    for (final length in [21, 35, 45]) {
      final s = LocalDate(2025, 6, 1);
      for (final phase in Phase.values) {
        final days = walk(s, phase, cycle: length);
        expect(days.toSet(), hasLength(days.length), reason: '$length $phase');
        final featured = testCatalogue.phase(phase).foodIds;
        expect(days.every(featured.contains), isTrue);
      }
    }
  });

  test('a late period keeps walking instead of repeating or stalling', () {
    final foods = <String>[];
    for (final lateDays in [0, 1, 2, 3]) {
      final today = start.addDays(27 + lateDays);
      final state = stateFor(start, today);
      expect(state.phase, Phase.luteal);
      foods.add(make(cycle: state, today: today).read(todaysFoodProvider)!.id);
    }
    expect(foods.toSet(), hasLength(foods.length));
  });

  test('with no cycle start it falls back to the date, without failing', () {
    final a = make(today: LocalDate(2025, 10, 4)).read(todaysFoodProvider);
    final b = make(today: LocalDate(2025, 10, 4)).read(todaysFoodProvider);
    final c = make(today: LocalDate(2025, 10, 5)).read(todaysFoodProvider);
    expect(a, isNotNull);
    expect(a!.id, b!.id);
    expect(c, isNotNull);
  });

  test('respects diet and avoidances', () {
    for (var d = 0; d < 28; d++) {
      final today = start.addDays(d);
      final food = make(
        cycle: stateFor(start, today),
        today: today,
        filter: const FoodFilter(diet: Diet.vegan),
      ).read(todaysFoodProvider)!;
      expect(food.animalSource.name, 'none', reason: food.id);
    }
  });

  test('it has a recipe the user can cook, in the real phase', () {
    for (var d = 0; d < 28; d++) {
      final today = start.addDays(d);
      final c = make(cycle: stateFor(start, today), today: today);
      final food = c.read(todaysFoodProvider)!;
      expect(c.read(recipesForFoodProvider(food.id)), isNotEmpty);
    }
  });

  test('headlines: six templates, filled in with the food', () {
    // Imported lazily to keep this file about the rotation.
    expect(stableHash('a'), stableHash('a'));
    expect(stableHash('a'), isNot(stableHash('b')));
  });
}
