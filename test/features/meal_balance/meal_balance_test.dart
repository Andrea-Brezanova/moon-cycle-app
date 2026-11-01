import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/meal_balance/domain/complement_ranker.dart';
import 'package:moon_cycle/features/meal_balance/domain/meal_balance.dart';
import 'package:moon_cycle/features/meal_balance/domain/pairing_rules.dart';
import 'package:moon_cycle/features/meal_balance/domain/plate_group.dart';

import '../../helpers/test_catalogue.dart';

/// Build a Meal 2.0 foundations (docs/build-a-meal-2.md). Pure utilities: not
/// wired to any screen, so production behaviour is unchanged.
void main() {
  final foods = testCatalogue.foods;
  Food f(String id) => testCatalogue.food(id)!;
  final noPhaseOrHealthClaim = RegExp(
    r'phase|menstru|luteal|follic|ovulat|hormon|detox|balanc\w* your|boost|cure|heal',
    caseSensitive: false,
  );

  group('plate groups', () {
    test('every catalogue food has a group, and herbs are seasoning', () {
      for (final food in foods) {
        expect(plateGroupOf(food), isA<PlateGroup>(), reason: food.id);
      }
      for (final id in ['parsley', 'mint', 'basil', 'cilantro', 'dill']) {
        if (testCatalogue.food(id) != null) {
          expect(plateGroupOf(f(id)), PlateGroup.seasoning, reason: id);
        }
      }
    });

    test('the common foods land where a cook would put them', () {
      expect(plateGroupOf(f('broccoli')), PlateGroup.vegetableFruit);
      expect(plateGroupOf(f('orange')), PlateGroup.vegetableFruit);
      expect(plateGroupOf(f('quinoa')), PlateGroup.grainStarch);
      expect(plateGroupOf(f('green-lentil')), PlateGroup.legume);
      expect(plateGroupOf(f('beef')), PlateGroup.protein);
      expect(plateGroupOf(f('sardine')), PlateGroup.protein);
      expect(plateGroupOf(f('almond')), PlateGroup.nutSeed);
    });

    test('grouping ignores the phase a food is featured in', () {
      // The group comes from the food's own category: no phase input exists.
      for (final food in foods) {
        expect(food.categoryId, isNotEmpty, reason: food.id);
      }
    });

    test('the iron and vitamin C id lists point at real foods', () {
      for (final id in [...plantIronFoodIds, ...vitaminCFoodIds]) {
        expect(testCatalogue.food(id), isNotNull, reason: id);
      }
    });
  });

  group('MealBalance', () {
    test('an empty meal is missing all three core parts, in order', () {
      final b = MealBalance.evaluate(const []);
      expect(b.missing, MealBalance.core);
      expect(b.score, 0);
      expect(b.isBalanced, isFalse);
    });

    test('vegetable, grain and protein make a balanced meal', () {
      final b = MealBalance.evaluate([f('broccoli'), f('quinoa'), f('beef')]);
      expect(b.isBalanced, isTrue);
      expect(b.score, 1);
    });

    test('legumes cover the protein part, once', () {
      final b = MealBalance.evaluate([f('green-lentil'), f('red-lentil')]);
      expect(b.present, {PlateGroup.protein});
      expect(b.missing, [PlateGroup.vegetableFruit, PlateGroup.grainStarch]);
    });

    test('order and duplicates do not matter', () {
      final a = MealBalance.evaluate([f('beef'), f('quinoa'), f('beef')]);
      final b = MealBalance.evaluate([f('quinoa'), f('beef')]);
      expect(a.present, b.present);
      expect(a.score, b.score);
    });

    test('herbs and seasoning never make a meal balanced', () {
      final b = MealBalance.evaluate([f('parsley'), f('basil')]);
      expect(b.score, 0);
      expect(b.missing, MealBalance.core);
    });
  });

  group('suggestComplements', () {
    test('starting from one protein, vegetables and fruit come first', () {
      final s = suggestComplements(chosen: [f('beef')], candidates: foods);
      expect(s, isNotEmpty);
      expect(plateGroupOf(s.first.food), PlateGroup.vegetableFruit);
      expect(s.first.reasons.first.code, 'completes-plate');
    });

    test('works from any food, including a fruit, and from nothing', () {
      expect(
        suggestComplements(chosen: [f('strawberry')], candidates: foods),
        isNotEmpty,
      );
      final fromNothing = suggestComplements(
        chosen: const [],
        candidates: foods,
      );
      expect(fromNothing, isNotEmpty);
      expect(plateGroupOf(fromNothing.first.food), PlateGroup.vegetableFruit);
    });

    test('safety is never scored: a disallowed food is never returned', () {
      final noFish = suggestComplements(
        chosen: [f('broccoli'), f('quinoa')],
        candidates: foods,
        allows: (food) => !food.allergenIds.contains('fish'),
        config: const RankerConfig(limit: 200),
      );
      expect(
        noFish.map((s) => s.food.allergenIds).any((a) => a.contains('fish')),
        isFalse,
      );
      // Without the filter a protein, including fish, is suggested.
      final all = suggestComplements(
        chosen: [f('broccoli'), f('quinoa')],
        candidates: foods,
        config: const RankerConfig(limit: 200),
      );
      expect(all.any((s) => s.food.allergenIds.contains('fish')), isTrue);
    });

    test('disliked and already chosen foods are not suggested', () {
      final s = suggestComplements(
        chosen: [f('beef')],
        candidates: foods,
        dislikedIds: {'broccoli'},
        config: const RankerConfig(limit: 200),
      );
      expect(s.map((x) => x.food.id), isNot(contains('broccoli')));
      expect(s.map((x) => x.food.id), isNot(contains('beef')));
    });

    test('herbs, fermented sides and other foods are not suggested', () {
      final s = suggestComplements(
        chosen: [f('beef')],
        candidates: foods,
        config: const RankerConfig(limit: 500),
      );
      for (final x in s) {
        expect(
          plateGroupOf(x.food).countsTowardBalance,
          isTrue,
          reason: x.food.id,
        );
      }
    });

    test(
      'plant iron with vitamin C is suggested with its documented reason',
      () {
        final s = suggestComplements(
          chosen: [f('green-lentil')],
          candidates: foods,
          config: const RankerConfig(limit: 200),
        );
        final orange = s.firstWhere((x) => x.food.id == 'orange');
        expect(
          orange.reasons.map((r) => r.code),
          contains('plant-iron-vitamin-c'),
        );
        expect(
          orange.reasons
              .firstWhere((r) => r.code == 'plant-iron-vitamin-c')
              .source,
          contains('NIH'),
        );
        // It outranks a vegetable with no documented pairing.
        final cucumber = s.firstWhere((x) => x.food.id == 'cucumber');
        expect(orange.score, greaterThan(cucumber.score));
      },
    );

    test('deterministic: the same input gives the same list', () {
      List<String> run() => [
        for (final x in suggestComplements(
          chosen: [f('chicken'), f('brown-rice')],
          candidates: foods,
        ))
          '${x.food.id}:${x.score}',
      ];
      expect(run(), run());
    });

    test('featured ids only break exact ties, never change a score order', () {
      final base = suggestComplements(
        chosen: [f('beef')],
        candidates: foods,
        config: const RankerConfig(limit: 500),
      );
      final withFeatured = suggestComplements(
        chosen: [f('beef')],
        candidates: foods,
        featuredIds: {for (final x in base.reversed.take(20)) x.food.id},
        config: const RankerConfig(limit: 500),
      );
      // Scores are non-increasing in both, and the multiset of scores is equal.
      for (final list in [base, withFeatured]) {
        for (var i = 0; i < list.length - 1; i++) {
          expect(list[i].score, greaterThanOrEqualTo(list[i + 1].score));
        }
      }
      expect(
        [for (final x in base) x.score],
        [for (final x in withFeatured) x.score],
      );
    });

    test('the limit is respected and empty candidates give nothing', () {
      expect(
        suggestComplements(
          chosen: [f('beef')],
          candidates: foods,
          config: const RankerConfig(limit: 3),
        ),
        hasLength(3),
      );
      expect(
        suggestComplements(chosen: [f('beef')], candidates: const []),
        isEmpty,
      );
    });

    test(
      'no explanation anywhere mentions a phase, hormones or a health outcome',
      () {
        for (final seed in foods.take(80)) {
          for (final s in suggestComplements(
            chosen: [seed],
            candidates: foods,
          )) {
            expect(s.reasons, isNotEmpty, reason: '${seed.id} -> ${s.food.id}');
            for (final r in s.reasons) {
              expect(
                noPhaseOrHealthClaim.hasMatch(r.text),
                isFalse,
                reason: r.text,
              );
              expect(r.source, isNotEmpty);
            }
          }
        }
      },
    );
  });
}
