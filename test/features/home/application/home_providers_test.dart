import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';

List<String> foods(FoodFilter filter, Phase phase) {
  final container = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
    ],
  );
  addTearDown(container.dispose);
  return [for (final f in container.read(foodsForPhaseProvider(phase))) f.id];
}

void main() {
  test('the first food of each category, up to six', () {
    expect(foods(FoodFilter.none, Phase.follicular), [
      'farro',
      'arugula',
      'avocado',
      'black-eyed-pea',
      'brazil-nut',
      'chicken',
    ]);
  });

  test('avoided foods give way to the next one; empty categories drop', () {
    const filter = FoodFilter(
      diet: Diet.vegetarian,
      avoidances: [AllergenAvoidance(id: 'a', allergenId: 'gluten')],
    );
    // Farro and oat bran (may contain gluten) leave Grains empty; chicken
    // and every seafood food are not vegetarian, so eggs and feta take over.
    expect(foods(filter, Phase.follicular), [
      'arugula',
      'avocado',
      'black-eyed-pea',
      'brazil-nut',
      'eggs',
      'feta',
    ]);
  });
}
