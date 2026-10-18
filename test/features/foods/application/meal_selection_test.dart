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

Food f(String id) => testCatalogue.food(id)!;

ProviderContainer make({
  Phase phase = Phase.follicular,
  FoodFilter filter = FoodFilter.none,
}) {
  final c = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
      actualPhaseProvider.overrideWithValue(phase),
    ],
  );
  addTearDown(c.dispose);
  c.listen(mealSelectionProvider, (_, _) {});
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('selection', () {
    test('one food is enough; no category is required', () {
      final c = make();
      expect(c.read(mealSelectionProvider).canCreate, isFalse);
      c.read(mealSelectionProvider.notifier).toggle(f('kale'));
      expect(c.read(mealSelectionProvider).canCreate, isTrue);
      c.read(mealSelectionProvider.notifier).toggle(f('chicken'));
      c.read(mealSelectionProvider.notifier).toggle(f('kale'));
      // Any single food, from any category, is a valid selection.
      for (final id in ['chicken', 'quinoa', 'kale']) {
        c.read(mealSelectionProvider.notifier).clear();
        c.read(mealSelectionProvider.notifier).toggle(f(id));
        expect(c.read(mealSelectionProvider).canCreate, isTrue, reason: id);
      }
    });

    test('several foods from the same category', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      for (final id in ['kale', 'carrot', 'broccoli', 'lettuce', 'spinach']) {
        n.toggle(f(id));
      }
      expect(c.read(mealSelectionProvider).ids, hasLength(5));
    });

    test('free to choose, un-choose and replace', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      n.toggle(f('tofu'));
      n.toggle(f('chicken'));
      n.toggle(f('tofu')); // un-choose
      expect(c.read(mealSelectionProvider).ids, ['chicken']);
      n.remove('chicken');
      expect(c.read(mealSelectionProvider).isEmpty, isTrue);
    });

    test('the same food is never chosen twice', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      n.toggle(f('chickpea'));
      n.seed(f('chickpea'));
      expect(c.read(mealSelectionProvider).ids, ['chickpea']);
    });

    test('the limit comes from one central setting and is enforced', () {
      expect(MealBuilderConfig.maxIngredients, 8);
      expect(MealBuilderConfig.minIngredients, 1);
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      final ids = [
        'kale', 'carrot', 'broccoli', 'lettuce', 'spinach', 'tofu', 'quinoa',
        'chicken', //
      ];
      for (final id in ids) {
        expect(n.toggle(f(id)), isTrue);
      }
      expect(c.read(mealSelectionProvider).isFull, isTrue);
      expect(n.toggle(f('eggs')), isFalse); // a ninth
      expect(c.read(mealSelectionProvider).ids, ids);
      // Freeing a place lets another food in.
      n.toggle(f('kale'));
      expect(n.toggle(f('eggs')), isTrue);
    });

    test('a starting food from its page is added once and can be removed', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      n.seed(f('broccoli'));
      n.seed(f('broccoli'));
      expect(c.read(mealSelectionProvider).ids, ['broccoli']);
      n.seed(f('tofu'));
      n.seed(f('brown-rice'));
      expect(c.read(mealSelectionProvider).ids, [
        'broccoli',
        'tofu',
        'brown-rice',
      ]);
      n.remove('broccoli');
      expect(c.read(mealSelectionProvider).contains('broccoli'), isFalse);
      n.clear();
      expect(c.read(mealSelectionProvider).isEmpty, isTrue);
    });
  });

  group('options', () {
    test(
      'the current phase comes first and on its own; the rest is separate',
      () {
        for (final phase in Phase.values) {
          final c = make(phase: phase);
          final featured = testCatalogue.phase(phase).foodIds.toSet();
          for (final slot in MealSlot.values) {
            final o = c.read(mealOptionsProvider(slot));
            expect(
              o.phaseFoods.every((x) => featured.contains(x.id)),
              isTrue,
              reason: '${phase.name} ${slot.name}',
            );
            expect(
              o.otherFoods.any((x) => featured.contains(x.id)),
              isFalse,
              reason: '${phase.name} ${slot.name}',
            );
            // A phase can feature no base at all (Ovulatory): the section then
            // says so and "Show all foods" still reaches every base.
            if (slot != MealSlot.base) {
              expect(
                o.phaseFoods,
                isNotEmpty,
                reason: '${phase.name} ${slot.name}',
              );
            }
            expect(o.all, isNotEmpty, reason: '${phase.name} ${slot.name}');
          }
        }
      },
    );

    test('"current" means the real phase, not a browsed one', () {
      // actualPhaseProvider is the user's calculated phase; the builder does
      // not read viewingPhaseProvider.
      final c = make(phase: Phase.luteal);
      final luteal = testCatalogue.phase(Phase.luteal).foodIds.toSet();
      expect(
        c
            .read(mealOptionsProvider(MealSlot.plant))
            .phaseFoods
            .every((x) => luteal.contains(x.id)),
        isTrue,
      );
    });

    test('every eligible food is still available once expanded', () {
      for (final phase in Phase.values) {
        final c = make(phase: phase);
        final plants = c.read(mealOptionsProvider(MealSlot.plant)).all;
        for (final id in ['broccoli', 'cucumber', 'pumpkin', 'kale']) {
          expect(plants.map((x) => x.id), contains(id), reason: phase.name);
        }
        final proteins = c.read(mealOptionsProvider(MealSlot.protein)).all;
        expect(proteins.map((x) => x.id), containsAll(['tofu', 'chicken']));
      }
    });

    test('diet and avoidances are respected in every section', () {
      const filter = FoodFilter(
        diet: Diet.vegan,
        avoidances: [AllergenAvoidance(id: 'g', allergenId: 'gluten')],
      );
      final c = make(filter: filter);
      for (final slot in MealSlot.values) {
        for (final x in c.read(mealOptionsProvider(slot)).all) {
          expect(filter.allowsFood(x), isTrue, reason: '${slot.name} ${x.id}');
        }
      }
      final proteins = c.read(mealOptionsProvider(MealSlot.protein)).all;
      expect(proteins.map((x) => x.id), isNot(contains('chicken')));
    });

    test('plants are vegetables and fruit; bases and proteins stay apart', () {
      final c = make();
      for (final x in c.read(mealOptionsProvider(MealSlot.plant)).all) {
        expect({'vegetables', 'fruit'}, contains(x.categoryId));
        expect(mealSlotFor(x), MealSlot.plant);
      }
      final bases = c.read(mealOptionsProvider(MealSlot.base)).all;
      expect(
        bases.map((x) => x.id),
        containsAll(['brown-rice', 'sweet-potato']),
      );
    });
  });

  group('what counts as a plant', () {
    test('herbs are never offered as plants', () {
      final c = make();
      final plants = c.read(mealOptionsProvider(MealSlot.plant)).all;
      for (final herb in [
        'parsley',
        'mint',
        'peppermint',
        'basil',
        'cilantro',
        'dill',
      ]) {
        expect(isHerb(f(herb)), isTrue);
        expect(isMealPlant(f(herb)), isFalse);
        expect(plants.map((x) => x.id), isNot(contains(herb)));
      }
      // A herb started from its page is not added to the meal.
      final n = c.read(mealSelectionProvider.notifier);
      n.seed(f('basil'));
      expect(c.read(mealSelectionProvider).isEmpty, isTrue);
    });

    test('culinary vegetables sold as pantry foods are plants', () {
      final c = make();
      final plants = c.read(mealOptionsProvider(MealSlot.plant)).all;
      for (final id in ['olives', 'kombu', 'wakame', 'canned-tomatoes']) {
        expect(f(id).categoryId, anyOf('vegetables', 'fruit'), reason: id);
        expect(plants.map((x) => x.id), contains(id), reason: id);
      }
    });

    test('pastes, dips and salsa are not plants', () {
      final c = make();
      final plants = c.read(mealOptionsProvider(MealSlot.plant)).all;
      for (final id in ['tomato-paste', 'salsa', 'guacamole']) {
        expect(plants.map((x) => x.id), isNot(contains(id)), reason: id);
      }
    });

    test('the food library and phase lists are untouched', () {
      expect(testCatalogue.foods.length, 254);
      expect(
        {
          for (final p in Phase.values)
            p: testCatalogue.phase(p).foodIds.length,
        },
        {
          Phase.menstrual: 35,
          Phase.follicular: 32,
          Phase.ovulatory: 31,
          Phase.luteal: 44,
        },
      );
    });
  });
}
