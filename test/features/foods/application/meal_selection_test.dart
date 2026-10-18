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
    test('one protein, one base, two or three plants', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      n.toggle(MealSlot.protein, f('tofu'));
      n.toggle(MealSlot.protein, f('chicken')); // replaces
      n.toggle(MealSlot.base, f('brown-rice'));
      n.toggle(MealSlot.base, f('quinoa')); // replaces
      expect(c.read(mealSelectionProvider).proteinId, 'chicken');
      expect(c.read(mealSelectionProvider).baseId, 'quinoa');
      expect(c.read(mealSelectionProvider).isComplete, isFalse);
      n.toggle(MealSlot.plant, f('broccoli'));
      expect(c.read(mealSelectionProvider).isComplete, isFalse); // one plant
      n.toggle(MealSlot.plant, f('kale'));
      expect(c.read(mealSelectionProvider).isComplete, isTrue);
      n.toggle(MealSlot.plant, f('carrot'));
      expect(c.read(mealSelectionProvider).isComplete, isTrue); // three
      expect(n.toggle(MealSlot.plant, f('lettuce')), isFalse); // a fourth
      expect(c.read(mealSelectionProvider).plantIds, hasLength(3));
    });

    test('choosing again un-chooses', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      n.toggle(MealSlot.plant, f('kale'));
      n.toggle(MealSlot.plant, f('kale'));
      expect(c.read(mealSelectionProvider).isEmpty, isTrue);
    });

    test(
      'a food is never in the meal twice (chickpea as protein and base)',
      () {
        final c = make();
        final n = c.read(mealSelectionProvider.notifier);
        n.toggle(MealSlot.protein, f('chickpea'));
        n.toggle(MealSlot.base, f('chickpea'));
        final s = c.read(mealSelectionProvider);
        expect(s.ids.where((i) => i == 'chickpea'), hasLength(1));
        expect(s.proteinId, isNull);
        expect(s.baseId, 'chickpea');
      },
    );

    test('a starting food goes into its slot, once, and can be removed', () {
      final c = make();
      final n = c.read(mealSelectionProvider.notifier);
      n.seed(f('broccoli'));
      n.seed(f('broccoli'));
      expect(c.read(mealSelectionProvider).plantIds, ['broccoli']);
      n.seed(f('tofu'));
      expect(c.read(mealSelectionProvider).proteinId, 'tofu');
      n.seed(f('brown-rice'));
      expect(c.read(mealSelectionProvider).baseId, 'brown-rice');
      n.remove('broccoli');
      expect(c.read(mealSelectionProvider).plantIds, isEmpty);
      n.clear();
      expect(c.read(mealSelectionProvider).isEmpty, isTrue);
    });
  });

  group('options', () {
    test('every food of the right kind is offered, whatever the phase', () {
      for (final phase in Phase.values) {
        final c = make(phase: phase);
        final plants = c.read(mealOptionsProvider(MealSlot.plant)).all;
        // Foods from other phases are all there.
        for (final id in ['broccoli', 'cucumber', 'pumpkin', 'kale']) {
          expect(plants.map((x) => x.id), contains(id), reason: phase.name);
        }
        final proteins = c.read(mealOptionsProvider(MealSlot.protein)).all;
        expect(proteins.map((x) => x.id), containsAll(['tofu', 'chicken']));
      }
    });

    test('foods featured in the viewed phase come first', () {
      for (final phase in Phase.values) {
        final c = make(phase: phase);
        final featured = testCatalogue.phase(phase).foodIds.toSet();
        for (final slot in MealSlot.values) {
          final all = c.read(mealOptionsProvider(slot)).all;
          final firstGeneral = all.indexWhere((x) => !featured.contains(x.id));
          if (firstGeneral < 0) continue;
          expect(
            all.skip(firstGeneral).any((x) => featured.contains(x.id)),
            isFalse,
            reason: '${phase.name} ${slot.name}',
          );
        }
      }
    });

    test('diet and avoidances are respected in every step', () {
      const filter = FoodFilter(
        diet: Diet.vegan,
        avoidances: [AllergenAvoidance(id: 'g', allergenId: 'gluten')],
      );
      final c = make(filter: filter);
      for (final slot in MealSlot.values) {
        final options = c.read(mealOptionsProvider(slot));
        for (final x in [...options.suggested, ...options.all]) {
          expect(filter.allowsFood(x), isTrue, reason: '${slot.name} ${x.id}');
        }
      }
      final proteins = c.read(mealOptionsProvider(MealSlot.protein)).all;
      expect(proteins.map((x) => x.id), isNot(contains('chicken')));
    });

    test('the suggestions are a subset of what can be chosen', () {
      final c = make();
      for (final slot in MealSlot.values) {
        final o = c.read(mealOptionsProvider(slot));
        final all = o.all.map((x) => x.id).toSet();
        expect(o.suggested.every((x) => all.contains(x.id)), isTrue);
        expect(o.suggested, isNotEmpty);
        expect(o.all.length, greaterThanOrEqualTo(o.suggested.length));
      }
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
}
