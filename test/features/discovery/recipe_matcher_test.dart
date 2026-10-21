import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/domain/match_config.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

/// Black-bean quinoa orange bowl uses black-turtle-bean, quinoa,
/// yellow-bell-pepper, orange (and onion and more).
const bowlId = 'black-bean-quinoa-orange-bowl';

RecipeMatcher matcher([MatchConfig c = MatchConfig.defaults]) =>
    RecipeMatcher(testCatalogue, config: c);

RecipeMatch? ofBowl(MealChoice choice, {MatchConfig? config}) =>
    matcher(config ?? MatchConfig.defaults)
        .matchOne(testCatalogue.recipe(bowlId)!, choice);

void main() {
  group('a recipe qualifies with at least one chosen food', () {
    test('one food: every recipe that uses it, and only those', () {
      final matches = matcher().match(MealChoice(['quinoa']), FoodFilter.none);
      expect(matches, isNotEmpty);
      for (final m in matches) {
        final present = {
          for (final l in m.recipe.ingredients) ?l.foodId,
          ...m.recipe.keyFoodIds,
        };
        expect(present, contains('quinoa'), reason: m.recipe.id);
        expect(m.level, MatchLevel.complete); // it uses the one food chosen
      }
      final all = testCatalogue.recipes.where((r) {
        final present = {
          for (final l in r.ingredients) ?l.foodId,
          ...r.keyFoodIds,
        };
        return present.contains('quinoa');
      });
      expect(matches.length, all.length);
    });

    test('a recipe using none of the foods is not returned', () {
      final m = ofBowl(MealChoice(['salmon', 'farro']));
      expect(m, isNull);
      final ids = matcher()
          .match(MealChoice(['salmon', 'farro']), FoodFilter.none)
          .map((m) => m.recipe.id);
      expect(ids, isNot(contains(bowlId)));
    });

    test('nothing chosen finds nothing', () {
      expect(matcher().match(MealChoice([]), FoodFilter.none), isEmpty);
    });

    test('other ingredients in the recipe are fine', () {
      final m = ofBowl(MealChoice(['quinoa']))!;
      expect(m.extraFoodIds, isNotEmpty);
      expect(m.level, MatchLevel.complete);
    });
  });

  group('how complete a match is, and how it is described', () {
    test('three of three is complete', () {
      final m = ofBowl(MealChoice(['black-turtle-bean', 'quinoa', 'orange']))!;
      expect(m.level, MatchLevel.complete);
      expect(m.missingIds, isEmpty);
      expect(m.matchedIds, ['black-turtle-bean', 'quinoa', 'orange']);
    });

    test('two of three is good, never complete', () {
      final m = ofBowl(MealChoice(['quinoa', 'orange', 'salmon']))!;
      expect(m.level, MatchLevel.good);
      expect(m.matchedIds, ['quinoa', 'orange']);
      expect(m.missingIds, ['salmon']);
    });

    test('one of three is partial, never complete', () {
      final m = ofBowl(MealChoice(['quinoa', 'salmon', 'farro']))!;
      expect(m.level, MatchLevel.partial);
      expect(m.matchedIds, ['quinoa']);
      expect(m.missingIds, ['salmon', 'farro']);
    });

    test('any recipe that misses a chosen food is not complete', () {
      for (final choice in [
        MealChoice(['quinoa', 'salmon']),
        MealChoice(['quinoa', 'orange', 'salmon', 'farro']),
      ]) {
        final m = ofBowl(choice)!;
        expect(m.level, isNot(MatchLevel.complete));
        expect(m.missingIds, isNotEmpty);
      }
    });

    test('the thresholds in the config decide good and partial', () {
      // Two of four: partial by default (0.5 < 0.6), good if the bar is 0.5.
      final choice = MealChoice(['quinoa', 'orange', 'salmon', 'farro']);
      expect(ofBowl(choice)!.level, MatchLevel.partial);
      expect(
        ofBowl(choice, config: const MatchConfig(goodMinCoverage: 0.5))!.level,
        MatchLevel.good,
      );
      // Three of four is good by default.
      expect(
        ofBowl(MealChoice(['quinoa', 'orange', 'onion', 'salmon']))!.level,
        MatchLevel.good,
      );
    });
  });

  group('ranking', () {
    test('the more chosen foods a recipe uses, the higher it ranks', () {
      final choice = MealChoice(['black-turtle-bean', 'quinoa', 'orange']);
      final matches = matcher().match(choice, FoodFilter.none);
      final counts = [for (final m in matches) m.matchedIds.length];
      expect([...counts]..sort((a, b) => b.compareTo(a)), counts);
      expect(matches.first.recipe.id, bowlId);
      expect(matches.first.level, MatchLevel.complete);
    });

    test('complete before good before partial', () {
      final choice = MealChoice(['quinoa', 'orange', 'onion', 'salmon']);
      final order = [
        for (final m in matcher().match(choice, FoodFilter.none)) m.level.index,
      ];
      expect([...order]..sort(), order);
    });

    test('the current phase only orders; it never decides a match', () {
      final recipe = testCatalogue.recipe(bowlId)!;
      final choice = MealChoice(['quinoa']);
      final here = matcher().matchOne(
        recipe,
        choice,
        currentPhase: recipe.phase,
      )!;
      final other = matcher().matchOne(
        recipe,
        choice,
        currentPhase: Phase.values.firstWhere((p) => p != recipe.phase),
      )!;
      expect(here.level, other.level);
      expect(here.score - other.score, MatchConfig.defaults.phaseBonus);
    });

    test('of two recipes using the same foods, the simpler ranks first', () {
      final m = ofBowl(MealChoice(['quinoa']))!;
      expect(
        m.score,
        closeTo(
          100 +
              MatchConfig.defaults.qualityBonus -
              m.extraFoodIds.length * MatchConfig.defaults.extraFoodPenalty,
          1e-9,
        ),
      );
    });
  });

  group('exclusions stay in force', () {
    test('a diet removes recipes with foods it excludes, at every level', () {
      const vegan = FoodFilter(diet: Diet.vegan);
      final choice = MealChoice(['sardine', 'spinach']);
      expect(matcher().match(choice, FoodFilter.none), isNotEmpty);
      for (final m in matcher().match(choice, vegan)) {
        expect(vegan.allowsRecipe(m.recipe, testCatalogue), isTrue);
      }
      expect(
        matcher().match(choice, vegan).map((m) => m.recipe.id),
        isNot(contains('sardine-spinach-lemon-toast')),
      );
    });

    test('an avoided food removes every recipe that contains it', () {
      const noOrange = FoodFilter(
        avoidances: [FoodItemAvoidance(id: 'a', foodId: 'orange')],
      );
      final ids = matcher()
          .match(MealChoice(['quinoa']), noOrange)
          .map((m) => m.recipe.id);
      expect(ids, isNot(contains(bowlId)));
    });

    test('an allergen removes recipes whose foods carry it', () {
      const noGluten = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'g', allergenId: 'gluten')],
      );
      for (final m in matcher().match(MealChoice(['carrot']), noGluten)) {
        expect(noGluten.allowsRecipe(m.recipe, testCatalogue), isTrue);
      }
    });
  });
}
