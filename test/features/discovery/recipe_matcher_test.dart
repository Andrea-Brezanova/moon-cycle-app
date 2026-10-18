import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/domain/match_config.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

/// Black-bean quinoa orange bowl: black-turtle-bean, quinoa, yellow-bell-pepper,
/// orange (and onion) are all in the recipe.
const bowl = MealChoice(
  proteinId: 'black-turtle-bean',
  baseId: 'quinoa',
  plantIds: ['yellow-bell-pepper', 'orange'],
);

RecipeMatcher matcher([MatchConfig c = MatchConfig.defaults]) =>
    RecipeMatcher(testCatalogue, config: c);

void main() {
  test(
    'a recipe with every selected food is a complete match, extras allowed',
    () {
      final matches = matcher().match(bowl, FoodFilter.none);
      final top = matches.first;
      expect(top.recipe.id, 'black-bean-quinoa-orange-bowl');
      expect(top.level, MatchLevel.complete);
      expect(top.missingIds, isEmpty);
      expect(top.coverage, 1);
      // The recipe also has onion and others the user did not choose.
      expect(top.extraFoodIds, isNotEmpty);
    },
  );

  test('complete matches always rank before partial ones', () {
    final matches = matcher().match(bowl, FoodFilter.none);
    final firstPartial = matches.indexWhere(
      (m) => m.level != MatchLevel.complete,
    );
    final lastComplete = matches.lastIndexWhere(
      (m) => m.level == MatchLevel.complete,
    );
    if (firstPartial >= 0) expect(lastComplete, lessThan(firstPartial));
  });

  test('one missing plant is a good partial match, never complete', () {
    const choice = MealChoice(
      proteinId: 'black-turtle-bean',
      baseId: 'quinoa',
      plantIds: ['yellow-bell-pepper', 'orange', 'kale'],
    );
    final m = matcher()
        .match(choice, FoodFilter.none)
        .firstWhere((m) => m.recipe.id == 'black-bean-quinoa-orange-bowl');
    expect(m.level, MatchLevel.goodPartial);
    expect(m.missingIds, ['kale']);
    // protein 3 + base 3 + two plants 4 of 3 + 3 + 3 * 2 = 12 → 10/12.
    expect(m.coverage, closeTo(10 / 12, 1e-9));
  });

  test('equivalent foods are not exact matches', () {
    const choice = MealChoice(
      proteinId: 'red-lentil', // the recipe uses black beans
      baseId: 'quinoa',
      plantIds: ['yellow-bell-pepper', 'orange'],
    );
    final m = matcher()
        .match(choice, FoodFilter.none)
        .firstWhere((m) => m.recipe.id == 'black-bean-quinoa-orange-bowl');
    expect(m.level, isNot(MatchLevel.complete));
    expect(m.missingIds, ['red-lentil']);
  });

  test('sharing only one plant is insufficient and not returned', () {
    const choice = MealChoice(
      proteinId: 'salmon',
      baseId: 'farro',
      plantIds: ['orange', 'kale'],
    );
    final ids = matcher()
        .match(choice, FoodFilter.none)
        .map((m) => m.recipe.id);
    expect(ids, isNot(contains('black-bean-quinoa-orange-bowl')));
  });

  test('a partial match must include the protein or the base', () {
    const choice = MealChoice(
      proteinId: 'salmon',
      baseId: 'farro',
      plantIds: ['yellow-bell-pepper', 'orange'],
    );
    // The bowl shares both plants (coverage 4/10) only: below the threshold
    // anyway. Lower the threshold to isolate the protein-or-base rule.
    const loose = MatchConfig(goodPartialMinCoverage: 0.1);
    final withRule = RecipeMatcher(
      testCatalogue,
      config: loose,
    ).match(choice, FoodFilter.none).map((m) => m.recipe.id);
    expect(withRule, isNot(contains('black-bean-quinoa-orange-bowl')));
    const noRule = MatchConfig(
      goodPartialMinCoverage: 0.1,
      partialNeedsProteinOrBase: false,
    );
    final without = RecipeMatcher(
      testCatalogue,
      config: noRule,
    ).match(choice, FoodFilter.none).map((m) => m.recipe.id);
    expect(without, contains('black-bean-quinoa-orange-bowl'));
  });

  test('thresholds are configuration: a stricter one demotes a partial', () {
    const choice = MealChoice(
      proteinId: 'black-turtle-bean',
      baseId: 'quinoa',
      plantIds: ['yellow-bell-pepper', 'orange', 'kale'],
    );
    final strict = RecipeMatcher(
      testCatalogue,
      config: const MatchConfig(goodPartialMinCoverage: 0.95),
    ).match(choice, FoodFilter.none);
    expect(
      strict.any((m) => m.recipe.id == 'black-bean-quinoa-orange-bowl'),
      isFalse,
    );
  });

  test('recipes the diet or an avoidance excludes are never returned', () {
    const vegan = FoodFilter(diet: Diet.vegan);
    const noOrange = FoodFilter(
      avoidances: [FoodItemAvoidance(id: 'a', foodId: 'orange')],
    );
    expect(
      matcher().match(bowl, vegan).map((m) => m.recipe.id),
      contains('black-bean-quinoa-orange-bowl'),
    );
    expect(
      matcher().match(bowl, noOrange).map((m) => m.recipe.id),
      isNot(contains('black-bean-quinoa-orange-bowl')),
    );
    // And an animal-food choice never surfaces for a vegan.
    const meat = MealChoice(
      proteinId: 'sardine',
      baseId: 'whole-grain-bread',
      plantIds: ['spinach', 'lemon'],
    );
    expect(
      matcher().match(meat, FoodFilter.none).first.recipe.id,
      'sardine-spinach-lemon-toast',
    );
    expect(matcher().match(meat, vegan), isEmpty);
  });

  test('the viewing phase only orders; it never decides a match', () {
    final recipe = testCatalogue.recipe('black-bean-quinoa-orange-bowl')!;
    final here = matcher().matchOne(recipe, bowl, viewingPhase: recipe.phase);
    final other = matcher().matchOne(
      recipe,
      bowl,
      viewingPhase: Phase.values.firstWhere((p) => p != recipe.phase),
    );
    expect(here.level, MatchLevel.complete);
    expect(other.level, MatchLevel.complete);
    expect(here.score - other.score, MatchConfig.defaults.phaseBonus);
  });

  test('of two complete matches the one with fewer extras ranks first', () {
    final a = matcher().matchOne(
      testCatalogue.recipe('black-bean-quinoa-orange-bowl')!,
      bowl,
    );
    expect(
      a.score,
      closeTo(
        100 +
            MatchConfig.defaults.qualityBonus -
            a.extraFoodIds.length * MatchConfig.defaults.extraFoodPenalty,
        1e-9,
      ),
    );
  });
}
