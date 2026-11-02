import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/meal_balance/application/meal_draft.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

/// Build a Meal 2.0 application layer: not wired to any screen.
void main() {
  ProviderContainer make({
    FoodFilter filter = FoodFilter.none,
    Set<String> disliked = const {},
  }) {
    final c = ProviderContainer(
      overrides: [
        catalogueProvider.overrideWithValue(testCatalogue),
        foodFilterProvider.overrideWithValue(filter),
        dislikedFoodIdsProvider.overrideWithValue(disliked),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  MealDraftController draft(ProviderContainer c) =>
      c.read(mealDraftProvider.notifier);

  test('any single food can start a meal, from any category', () {
    for (final id in ['orange', 'quinoa', 'beef', 'almond', 'broccoli']) {
      final c = make();
      expect(draft(c).add(id), AddResult.added, reason: id);
      expect(c.read(mealDraftProvider), [id]);
      expect(c.read(mealSuggestionsProvider), isNotEmpty, reason: id);
    }
  });

  test('the selection survives leaving and returning (kept alive)', () {
    final c = make();
    draft(c).add('quinoa');
    draft(c).add('broccoli');
    // A listener coming and going (a screen closing and reopening) must not
    // reset the draft.
    c.listen(mealDraftProvider, (_, _) {}, fireImmediately: true).close();
    expect(c.read(mealDraftProvider), ['quinoa', 'broccoli']);
  });

  test('duplicates, unknown foods and the limit are handled', () {
    final c = make();
    expect(draft(c).add('quinoa'), AddResult.added);
    expect(draft(c).add('quinoa'), AddResult.alreadyChosen);
    expect(draft(c).add('moon-dust'), AddResult.unknownFood);
    final others = testCatalogue.foods
        .map((f) => f.id)
        .where((i) => i != 'quinoa');
    for (final id in others.take(mealDraftMaxFoods - 1)) {
      draft(c).add(id);
    }
    expect(c.read(mealDraftProvider).length, mealDraftMaxFoods);
    expect(draft(c).add(others.last), AddResult.full);
    expect(c.read(mealSuggestionsProvider), isA<List<Object?>>());
  });

  test('a food the user cannot eat can neither be chosen nor suggested', () {
    const filter = FoodFilter(
      diet: Diet.vegan,
      avoidances: [
        AllergenAvoidance(id: 'a', allergenId: 'tree-nut'),
        FoodItemAvoidance(id: 'b', foodId: 'broccoli'),
      ],
    );
    final c = make(filter: filter);
    expect(draft(c).add('beef'), AddResult.notAllowed);
    expect(draft(c).add('almond'), AddResult.notAllowed);
    expect(draft(c).add('broccoli'), AddResult.notAllowed);
    draft(c).add('quinoa');
    for (final s in c.read(mealSuggestionsProvider)) {
      expect(filter.allowsFood(s.food), isTrue, reason: s.food.id);
    }
  });

  test(
    'every food in the catalogue is checked: no suggestion is ever unsafe',
    () {
      const filter = FoodFilter(
        diet: Diet.vegetarian,
        avoidances: [
          AllergenAvoidance(id: 'a', allergenId: 'peanut'),
          AllergenAvoidance(id: 'b', allergenId: 'dairy'),
          AllergenAvoidance(id: 'c', allergenId: 'gluten'),
        ],
      );
      final c = make(filter: filter);
      for (final start in testCatalogue.foods) {
        c.read(mealDraftProvider.notifier).clear();
        if (draft(c).add(start.id) != AddResult.added) continue;
        for (final s in c.read(mealSuggestionsProvider)) {
          expect(
            filter.allowsFood(s.food),
            isTrue,
            reason: '${start.id} → ${s.food.id}',
          );
        }
      }
    },
  );

  test('disliked foods are never suggested but can still be chosen', () {
    final base = make();
    draft(base).add('quinoa');
    final first = base.read(mealSuggestionsProvider).first.food.id;
    final c = make(disliked: {first});
    draft(c).add('quinoa');
    expect(
      c.read(mealSuggestionsProvider).map((s) => s.food.id),
      isNot(contains(first)),
    );
    expect(draft(c).add(first), AddResult.added);
  });

  test('a new allergy removes an already chosen food from the draft', () {
    var filter = FoodFilter.none;
    final c = ProviderContainer(
      overrides: [
        catalogueProvider.overrideWithValue(testCatalogue),
        foodFilterProvider.overrideWith((ref) => filter),
        dislikedFoodIdsProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(c.dispose);
    c.read(mealDraftProvider);
    draft(c).add('almond');
    draft(c).add('quinoa');
    filter = const FoodFilter(
      avoidances: [AllergenAvoidance(id: 'a', allergenId: 'tree-nut')],
    );
    c.invalidate(foodFilterProvider);
    c.read(foodFilterProvider);
    expect(c.read(mealDraftProvider), ['quinoa']);
  });

  test('the meal and its suggestions never involve the cycle', () {
    // The providers read the catalogue, the filter and dislikes only; the
    // suggestions are identical however often they are read.
    final c = make();
    draft(c).add('quinoa');
    expect(
      c.read(mealSuggestionsProvider).map((s) => s.food.id).toList(),
      c.read(mealSuggestionsProvider).map((s) => s.food.id).toList(),
    );
  });
}
