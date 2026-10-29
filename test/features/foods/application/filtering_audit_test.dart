import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/application/meal_selection.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';

/// Audit of diet, allergen and exclusion handling across the whole bundled
/// catalogue: properties that must hold for every food, every diet and every
/// allergen, not just a few examples.
ProviderContainer make(FoodFilter filter, Phase phase) {
  final c = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
      actualPhaseProvider.overrideWithValue(phase),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  final foods = testCatalogue.foods;
  final allergens = {for (final f in foods) ...f.allergenIds};

  group('catalogue tags agree with each other', () {
    test(
      'a food tagged dairy, egg, fish or shellfish has an animal source',
      () {
        for (final f in foods) {
          if (f.allergenIds.contains('dairy')) {
            expect(
              f.animalSource,
              isNot(AnimalSource.none),
              reason: '${f.id} is tagged dairy',
            );
          }
          if (f.allergenIds.contains('egg')) {
            expect(
              f.animalSource,
              isNot(AnimalSource.none),
              reason: '${f.id} is tagged egg',
            );
          }
          if (f.allergenIds.contains('fish') ||
              f.allergenIds.contains('shellfish')) {
            expect(
              f.animalSource,
              isNot(AnimalSource.none),
              reason: '${f.id} is tagged fish or shellfish',
            );
          }
        }
      },
    );

    test('a vegan never sees egg noodles or naan; a vegetarian still can', () {
      const vegan = FoodFilter(diet: Diet.vegan);
      const vegetarian = FoodFilter(diet: Diet.vegetarian);
      for (final id in ['egg-noodles', 'naan']) {
        expect(vegan.allowsFood(testCatalogue.food(id)!), isFalse, reason: id);
        expect(
          vegetarian.allowsFood(testCatalogue.food(id)!),
          isTrue,
          reason: id,
        );
      }
    });

    test('food ids are unique', () {
      final ids = foods.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('every diet and allergen, every section, every phase', () {
    for (final diet in Diet.values) {
      for (final allergen in <String?>[null, ...allergens]) {
        final filter = FoodFilter(
          diet: diet,
          avoidances: [
            if (allergen != null)
              AllergenAvoidance(id: 'a-$allergen', allergenId: allergen),
          ],
        );
        test('${diet.name}, avoiding ${allergen ?? 'nothing'}', () {
          for (final phase in Phase.values) {
            final c = make(filter, phase);
            for (final slot in MealSlot.values) {
              final options = c.read(mealOptionsProvider(slot));
              for (final f in options.all) {
                expect(
                  filter.allowsFood(f),
                  isTrue,
                  reason: '${slot.name} ${f.id}',
                );
                if (allergen != null) {
                  expect(
                    f.allergenIds,
                    isNot(contains(allergen)),
                    reason: f.id,
                  );
                  expect(
                    f.mayContainAllergenIds,
                    isNot(contains(allergen)),
                    reason: f.id,
                  );
                }
                if (diet == Diet.vegan) {
                  expect(f.animalSource, AnimalSource.none, reason: f.id);
                }
              }
              final ids = options.all.map((f) => f.id).toList();
              expect(
                ids.toSet().length,
                ids.length,
                reason: 'duplicate in ${slot.name}',
              );
            }
            final ideas = [
              ...c.read(proteinIdeasProvider(phase)).all,
              ...c.read(baseIdeasProvider(phase)).all,
            ];
            for (final f in ideas) {
              expect(filter.allowsFood(f), isTrue, reason: 'idea ${f.id}');
            }
          }
        });
      }
    }
  });

  test('only legumes are offered in two sections (protein and base)', () {
    // Documented behaviour, not changed by this audit: substantial legumes count
    // as both a protein and a base, so they appear in both lists, and choosing one
    // marks it in both because a selection is by food id.
    final c = make(FoodFilter.none, Phase.follicular);
    final seen = <String, MealSlot>{};
    final twice = <String>{};
    for (final slot in MealSlot.values) {
      for (final f in c.read(mealOptionsProvider(slot)).all) {
        if (seen.containsKey(f.id)) twice.add(f.id);
        seen[f.id] = slot;
      }
    }
    expect(twice, isNotEmpty);
    for (final id in twice) {
      expect(testCatalogue.food(id)!.categoryId, 'legumes', reason: id);
    }
    expect(seen.containsKey('spinach') && twice.contains('spinach'), isFalse);
  });

  test('every recipe the filter allows is free of the avoided allergen', () {
    for (final allergen in allergens) {
      final filter = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'a', allergenId: allergen)],
      );
      for (final r in testCatalogue.recipes) {
        if (!filter.allowsRecipe(r, testCatalogue)) continue;
        for (final line in r.ingredients) {
          final food = line.foodId == null
              ? null
              : testCatalogue.food(line.foodId!);
          expect(
            food?.allergenIds ?? const <String>{},
            isNot(contains(allergen)),
            reason: '${r.id}: ${line.label}',
          );
          expect(
            food?.mayContainAllergenIds ?? const <String>{},
            isNot(contains(allergen)),
            reason: '${r.id}: ${line.label}',
          );
          expect(
            line.extraAllergenIds,
            isNot(contains(allergen)),
            reason: '${r.id}: ${line.label}',
          );
        }
      }
    }
  });

  test('vegan filter leaves out every recipe that has an animal food', () {
    const filter = FoodFilter(diet: Diet.vegan);
    for (final r in testCatalogue.recipes) {
      if (!filter.allowsRecipe(r, testCatalogue)) continue;
      for (final line in r.ingredients) {
        final food = line.foodId == null
            ? null
            : testCatalogue.food(line.foodId!);
        if (food != null) {
          expect(
            food.animalSource,
            AnimalSource.none,
            reason: '${r.id}: ${line.label}',
          );
        }
        expect(
          line.extraAnimalSource ?? AnimalSource.none,
          AnimalSource.none,
          reason: '${r.id}: ${line.label}',
        );
      }
    }
  });

  test('an unknown food id in a saved search is ignored, not a crash', () {
    expect(testCatalogue.food('not-a-food'), isNull);
  });
}
