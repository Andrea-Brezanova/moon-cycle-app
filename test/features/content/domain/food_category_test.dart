import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  test('a listed food keeps the category its phase lists place it in', () {
    for (final phase in Phase.values) {
      for (final food in testCatalogue.foodsFor(phase)) {
        expect(
          testCatalogue.categoryFor(food).id,
          testCatalogue.categoryOf(food.id, phase)!.id,
          reason: '${food.id} in ${phase.name}',
        );
      }
    }
  });

  test('every shippable food has a category, listed on a phase or not', () {
    final listed = {
      for (final p in Phase.values) ...testCatalogue.phase(p).foodIds,
    };
    expect(testCatalogue.foods.any((f) => !listed.contains(f.id)), isTrue);
    for (final food in testCatalogue.foods) {
      expect(testCatalogue.categoryFor(food), isNotNull, reason: food.id);
    }
  });

  test('All foods holds the whole catalogue, not only featured foods', () {
    final container = ProviderContainer(
      overrides: [catalogueProvider.overrideWithValue(testCatalogue)],
    );
    addTearDown(container.dispose);
    final shown = {
      for (final (_, foods) in container.read(allFoodsByCategoryProvider))
        for (final f in foods) f.id,
    };
    expect(shown, {for (final f in testCatalogue.foods) f.id});
    expect(shown, contains('blackberry'));
  });

  test('food to recipe links count every recipe that uses a key food', () {
    final container = ProviderContainer(
      overrides: [catalogueProvider.overrideWithValue(testCatalogue)],
    );
    addTearDown(container.dispose);
    final counts = container.read(allRecipeCountsProvider);
    // Counted independently from the recipes themselves.
    final expected = <String, int>{};
    for (final r in testCatalogue.recipes) {
      for (final id in r.keyFoodIds.toSet()) {
        expected[id] = (expected[id] ?? 0) + 1;
      }
    }
    expect(counts, expected);
    expect(testCatalogue.recipes, hasLength(112));
    // A food the first 40 recipes never used is now linked.
    expect(counts['turnip'], greaterThan(0));
    for (final r in testCatalogue.recipes) {
      for (final id in r.keyFoodIds) {
        expect(counts[id], greaterThan(0), reason: '${r.id} / $id');
      }
    }
  });
}
