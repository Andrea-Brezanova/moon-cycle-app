import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_state.dart';
import 'package:moon_cycle/features/foods/application/todays_food.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/plants/application/plant_providers.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

/// A container for [today] in a cycle that started on [start] (null: the cycle
/// start is not known).
ProviderContainer on(
  LocalDate today, {
  LocalDate? start,
  int cycleLength = 28,
  int periodLength = 5,
  FoodFilter filter = FoodFilter.none,
}) {
  final AsyncValue<CycleState?> state = start == null
      ? const AsyncData(null)
      : AsyncData(
          calculateCycleState(
            lastPeriodStart: start,
            lengths: CycleLengths.fromProfile(
              CycleProfile(
                typicalCycleLength: cycleLength,
                typicalPeriodLength: periodLength,
              ),
            ),
            today: today,
          ),
        );
  final c = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
      clockProvider.overrideWithValue(
        () => DateTime(today.year, today.month, today.day, 9),
      ),
      cycleStateProvider.overrideWithValue(state),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

List<String> ids(ProviderContainer c) => [
  for (final f in c.read(threePlantsProvider)) f.id,
];

final start = LocalDate(2025, 9, 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Food f(String id) => testCatalogue.food(id)!;

  group('what counts as a plant to discover', () {
    test('vegetables, fruit, legumes, whole grains, nuts and seeds', () {
      for (final id in [
        'broccoli',
        'kale',
        'orange',
        'chickpea',
        'green-lentil',
        'quinoa',
        'brown-rice',
        'oat',
        'walnut',
        'pumpkin-seeds',
      ]) {
        expect(isDiscoveryPlant(f(id)), isTrue, reason: id);
      }
    });

    test('not herbs, refined or prepared foods, oils, or other foods', () {
      for (final id in [
        'basil',
        'white-rice',
        'pasta',
        'whole-grain-bread',
        'granola',
        'hummus',
        'baked-beans',
        'nut-butter',
        'tahini',
        'tomato-paste',
        'olive-oil',
        'chicken',
        'tofu',
        'feta',
        'miso',
        'kimchi',
      ]) {
        expect(isDiscoveryPlant(f(id)), isFalse, reason: id);
      }
    });
  });

  group('three plants from the real phase', () {
    // Day 3, 10, 14 and 21 of a 28/5 cycle: one day in each phase.
    for (final (phase, cycleDay) in [
      (Phase.menstrual, 3),
      (Phase.follicular, 10),
      (Phase.ovulatory, 14),
      (Phase.luteal, 21),
    ]) {
      test('${phase.name}: three distinct eligible foods of that phase', () {
        final c = on(start.addDays(cycleDay - 1), start: start);
        expect(c.read(actualPhaseProvider), phase);
        final plants = c.read(threePlantsProvider);
        expect(plants, hasLength(3));
        expect({for (final p in plants) p.id}, hasLength(3));
        final featured = testCatalogue.phase(phase).foodIds.toSet();
        for (final p in plants) {
          expect(featured, contains(p.id));
          expect(isDiscoveryPlant(p), isTrue, reason: p.id);
        }
      });
    }

    test('today, without touching the wheel, is the real phase and day', () {
      final c = on(start.addDays(9), start: start);
      final d = c.read(plantsDayProvider);
      expect(d.preview, isFalse);
      expect(d.phase, c.read(actualPhaseProvider));
      expect(d.day, 10);
    });
  });

  group('the day Home’s cycle wheel is on (a preview)', () {
    // Today is cycle day 10 (follicular) of a 28/5 cycle.
    ProviderContainer wheel() => on(start.addDays(9), start: start);

    test(
      'a day in the same phase gives different plants from the same pool',
      () {
        final c = wheel();
        final today = ids(c);
        c.read(homePreviewProvider.notifier).preview(8);
        expect(c.read(plantsDayProvider).preview, isTrue);
        expect(c.read(plantsDayProvider).phase, Phase.follicular);
        final other = ids(c);
        expect(other, hasLength(3));
        expect(other, isNot(today));
        final featured = testCatalogue.phase(Phase.follicular).foodIds.toSet();
        expect(featured.containsAll(other), isTrue);
      },
    );

    test('crossing a phase boundary swaps the pool to that phase', () {
      final c = wheel();
      for (final (day, phase) in [
        (3, Phase.menstrual),
        (14, Phase.ovulatory),
        (21, Phase.luteal),
        (10, Phase.follicular),
      ]) {
        c.read(homePreviewProvider.notifier).preview(day);
        expect(c.read(plantsDayProvider).phase, phase, reason: 'day $day');
        final featured = testCatalogue.phase(phase).foodIds.toSet();
        expect(featured.containsAll(ids(c)), isTrue, reason: 'day $day');
        expect(ids(c), hasLength(3));
      }
    });

    test('returning to a day shows the same three again', () {
      final c = wheel();
      final notifier = c.read(homePreviewProvider.notifier);
      notifier.preview(20);
      final first = ids(c);
      notifier.preview(4);
      expect(ids(c), isNot(first));
      notifier.preview(20);
      expect(ids(c), first);
    });

    test('back to today restores today’s plants', () {
      final c = wheel();
      final today = ids(c);
      c.read(homePreviewProvider.notifier).preview(18);
      expect(ids(c), isNot(today));
      c.read(homePreviewProvider.notifier).backToToday();
      expect(c.read(plantsDayProvider).preview, isFalse);
      expect(ids(c), today);
    });

    test('a phase chosen elsewhere previews that phase', () {
      final c = wheel();
      c.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
      expect(c.read(plantsDayProvider).phase, Phase.luteal);
      final featured = testCatalogue.phase(Phase.luteal).foodIds.toSet();
      expect(featured.containsAll(ids(c)), isTrue);
    });

    test(
      'a restart (new container) gives the same plants for the same day',
      () {
        final a = wheel();
        a.read(homePreviewProvider.notifier).preview(19);
        final fresh = wheel();
        fresh.read(homePreviewProvider.notifier).preview(19);
        expect(ids(fresh), ids(a));
      },
    );

    test('consecutive days never repeat the same trio', () {
      final c = wheel();
      final n = c.read(homePreviewProvider.notifier);
      List<String>? previous;
      for (var day = 1; day <= 28; day++) {
        n.preview(day);
        final now = ids(c);
        if (previous != null &&
            c.read(plantPoolProvider).length > 3 &&
            c.read(plantsDayProvider).phase ==
                c
                    .read(cycleStateProvider)
                    .value!
                    .ranges
                    .forDay(day - 1)
                    .phase) {
          expect(now.toSet(), isNot(previous.toSet()), reason: 'day $day');
        }
        previous = now;
      }
    });

    test('dietary exclusions apply to previewed days', () {
      const filter = FoodFilter(
        diet: Diet.vegan,
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'tree-nut')],
      );
      final c = on(start.addDays(9), start: start, filter: filter);
      for (var day = 1; day <= 28; day++) {
        c.read(homePreviewProvider.notifier).preview(day);
        for (final p in c.read(threePlantsProvider)) {
          expect(filter.allowsFood(p), isTrue, reason: '${p.id} day $day');
        }
      }
    });

    test('irregular and late cycles still give three plants per day', () {
      for (final length in [21, 35]) {
        final c = on(
          start.addDays(length ~/ 2),
          start: start,
          cycleLength: length,
        );
        for (var day = 1; day <= length; day++) {
          c.read(homePreviewProvider.notifier).preview(day);
          expect(ids(c), hasLength(3), reason: '$length-day cycle, day $day');
        }
      }
      // A late period (today is past the cycle length): today still gives three
      // and previewing an earlier day works.
      final late = on(start.addDays(33), start: start);
      expect(ids(late), hasLength(3));
      late.read(homePreviewProvider.notifier).preview(8);
      expect(ids(late), hasLength(3));
    });

    test('previewing changes no stored cycle data', () {
      final c = wheel();
      final before = c.read(cycleStateProvider).value!;
      c.read(homePreviewProvider.notifier).preview(22);
      final after = c.read(cycleStateProvider).value!;
      expect(identical(before, after), isTrue);
      expect(after.cycleDay, 10);
      expect(after.lastPeriodStart, start);
    });

    test('picks reset when the day changes', () {
      final c = wheel();
      c.listen(plantPicksProvider, (_, _) {});
      final first = c.read(threePlantsProvider).first.id;
      c.read(plantPicksProvider.notifier).toggle(first);
      expect(c.read(plantPicksProvider), {first});
      c.read(homePreviewProvider.notifier).preview(13);
      expect(c.read(plantPicksProvider), isEmpty);
    });
  });

  group('stable all day, new every day', () {
    test('the same date always gives the same three', () {
      final a = ids(on(start.addDays(9), start: start));
      final b = ids(on(start.addDays(9), start: start));
      expect(a, b);
    });

    test('every day of a phase gives different plants, with no repeat while '
        'the pool lasts', () {
      // Follicular is cycle days 6–13 of a 28/5 cycle.
      final pool = on(
        start.addDays(9),
        start: start,
      ).read(plantPoolProvider).length;
      final days = <List<String>>[];
      for (var d = 6; d <= 13; d++) {
        days.add(ids(on(start.addDays(d - 1), start: start)));
      }
      for (var i = 1; i < days.length; i++) {
        expect(days[i], isNot(days[i - 1]));
      }
      final fullDays = pool ~/ 3;
      final shown = [for (final d in days.take(fullDays)) ...d];
      expect(shown.toSet(), hasLength(shown.length));
    });

    test('independent of Today’s food', () {
      final c = on(start.addDays(9), start: start);
      c.read(todaysFoodProvider); // reading it changes nothing here
      expect(ids(c), ids(on(start.addDays(9), start: start)));
    });
  });

  group('rotation across cycles and cycle lengths', () {
    test('the next cycle walks the same phase in a different order', () {
      List<String> run(LocalDate s) => [
        for (var d = 6; d <= 13; d++) ...ids(on(s.addDays(d - 1), start: s)),
      ];
      expect(run(start), isNot(run(start.addDays(28))));
    });

    for (final length in [21, 24, 28, 35, 45]) {
      test('a $length-day cycle: three distinct plants every day', () {
        for (var d = 1; d <= length; d++) {
          final c = on(start.addDays(d - 1), start: start, cycleLength: length);
          final plants = c.read(threePlantsProvider);
          expect(plants, hasLength(3), reason: 'day $d of $length');
          expect({for (final p in plants) p.id}, hasLength(3));
        }
      });
    }

    test('a late period keeps walking and keeps three', () {
      for (var d = 29; d <= 40; d++) {
        final c = on(start.addDays(d - 1), start: start);
        expect(c.read(threePlantsProvider), hasLength(3), reason: 'day $d');
      }
    });

    test('no cycle start known: still three, stable, new tomorrow', () {
      final today = LocalDate(2025, 10, 4);
      final a = ids(on(today));
      expect(a, hasLength(3));
      expect(a, ids(on(today)));
      expect(ids(on(today.addDays(1))), isNot(a));
    });
  });

  group('diet and avoidances', () {
    test('a vegan with a tree-nut allergy gets no animal food or nuts', () {
      const filter = FoodFilter(
        diet: Diet.vegan,
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'tree-nut')],
      );
      for (var d = 1; d <= 28; d++) {
        final c = on(start.addDays(d - 1), start: start, filter: filter);
        for (final p in c.read(threePlantsProvider)) {
          expect(filter.allowsFood(p), isTrue, reason: '${p.id} day $d');
        }
      }
    });

    test('an avoided food is never suggested', () {
      final c0 = on(start.addDays(9), start: start);
      final first = ids(c0).first;
      final filter = FoodFilter(
        avoidances: [FoodItemAvoidance(id: 'x', foodId: first)],
      );
      final c = on(start.addDays(9), start: start, filter: filter);
      expect(ids(c), isNot(contains(first)));
      expect(ids(c), hasLength(3));
    });

    test('fewer than three eligible foods: only those, never padded', () {
      final pool = on(start.addDays(9), start: start).read(plantPoolProvider);
      final keep = pool.take(2).map((p) => p.id).toSet();
      final filter = FoodFilter(
        avoidances: [
          for (final p in pool)
            if (!keep.contains(p.id)) FoodItemAvoidance(id: p.id, foodId: p.id),
        ],
      );
      final c = on(start.addDays(9), start: start, filter: filter);
      expect(ids(c).toSet(), keep);
      final none = on(
        start.addDays(9),
        start: start,
        filter: FoodFilter(
          avoidances: [
            for (final p in pool) FoodItemAvoidance(id: p.id, foodId: p.id),
          ],
        ),
      );
      expect(none.read(threePlantsProvider), isEmpty);
    });
  });

  group('picking', () {
    test('one, two or three; toggling off', () {
      final c = on(start.addDays(9), start: start);
      final n = c.read(plantPicksProvider.notifier);
      c.listen(plantPicksProvider, (_, _) {});
      expect(c.read(plantPicksProvider), isEmpty);
      n.toggle('a');
      n.toggle('b');
      n.toggle('c');
      expect(c.read(plantPicksProvider), {'a', 'b', 'c'});
      n.toggle('b');
      expect(c.read(plantPicksProvider), {'a', 'c'});
    });
  });
}
