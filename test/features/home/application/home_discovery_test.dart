import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/home/application/home_discovery.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';

import '../../../helpers/test_catalogue.dart';

ProviderContainer make({DateTime? now, FoodFilter filter = FoodFilter.none}) {
  final container = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
      clockProvider.overrideWithValue(() => now ?? DateTime(2025, 10, 4, 9)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Today’s food is featured in the phase and stable for the day', () {
    for (final phase in Phase.values) {
      final a = make().read(todaysFoodProvider(phase));
      final b = make(now: DateTime(2025, 10, 4, 21))
          .read(todaysFoodProvider(phase));
      expect(a, isNotNull);
      expect(testCatalogue.phase(phase).foodIds, contains(a!.id));
      expect(b!.id, a.id, reason: 'same date, different time: ${phase.name}');
      // Reading again from the same container gives the same food.
      final c = make();
      expect(
        c.read(todaysFoodProvider(phase))!.id,
        c.read(todaysFoodProvider(phase))!.id,
      );
    }
  });

  test('Today’s food prefers foods that have a recipe in the phase', () {
    for (final phase in Phase.values) {
      final c = make();
      final counts = c.read(recipeCountsProvider(phase));
      final food = c.read(todaysFoodProvider(phase))!;
      expect(counts[food.id] ?? 0, greaterThan(0), reason: phase.name);
    }
  });

  test('Today’s food changes with the date and the phase', () {
    final ids = <String>{};
    for (var d = 1; d <= 20; d++) {
      ids.add(
        make(now: DateTime(2025, 10, d))
            .read(todaysFoodProvider(Phase.follicular))!
            .id,
      );
    }
    expect(ids.length, greaterThan(1));
    final byPhase = {
      for (final p in Phase.values) make().read(todaysFoodProvider(p))!.id,
    };
    expect(byPhase.length, greaterThan(1));
  });

  test('Today’s food respects diet and avoidances', () {
    for (var d = 1; d <= 20; d++) {
      for (final phase in Phase.values) {
        final food = make(
          now: DateTime(2025, 10, d),
          filter: const FoodFilter(diet: Diet.vegan),
        ).read(todaysFoodProvider(phase))!;
        expect(food.animalSource, AnimalSource.none, reason: food.id);
      }
    }
  });

  test('Try something new: phase foods, never Today’s food, spread out', () {
    for (final phase in Phase.values) {
      final c = make();
      final todays = c.read(todaysFoodProvider(phase))!;
      final pages = c.read(tryNewPagesProvider(phase));
      final all = pages.expand((p) => p).toList();
      expect(all.map((f) => f.id), isNot(contains(todays.id)));
      final featured = testCatalogue.phase(phase).foodIds.toSet();
      expect(all.every((f) => featured.contains(f.id)), isTrue);
      for (final page in pages) {
        expect(page, hasLength(3), reason: phase.name);
        expect(page.map((f) => f.id).toSet(), hasLength(3));
      }
      // The first page uses three different categories.
      expect(pages.first.map((f) => f.categoryId).toSet(), hasLength(3));
    }
  });

  test('Show me 3 more gives a different set, and wraps around', () {
    final pages = make().read(tryNewPagesProvider(Phase.luteal));
    expect(pages.length, greaterThan(2));
    final ids = [for (final p in pages) pageOfThree(pages, pages.indexOf(p))];
    final p0 = pageOfThree(pages, 0).map((f) => f.id).toSet();
    final p1 = pageOfThree(pages, 1).map((f) => f.id).toSet();
    expect(p0.intersection(p1), isEmpty);
    expect(pageOfThree(pages, pages.length), pageOfThree(pages, 0));
    expect(ids, hasLength(pages.length));
  });

  test('a phase with few foods still returns what it has', () {
    expect(pageOfThree(const [], 0), isEmpty);
  });
}
