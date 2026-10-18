import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';

FoodIdeas base(Phase phase, FoodFilter filter) {
  final container = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
    ],
  );
  addTearDown(container.dispose);
  return container.read(baseIdeasProvider(phase));
}

FoodIdeas ideas(Phase phase, FoodFilter filter) {
  final container = ProviderContainer(
    overrides: [
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(filter),
    ],
  );
  addTearDown(container.dispose);
  return container.read(proteinIdeasProvider(phase));
}

String names(FoodIdeas i) =>
    'Featured: ${i.featured.map((f) => f.displayName).join(' · ')}\n'
    'Also good: ${i.general.map((f) => f.displayName).join(' · ')}';

int count(FoodIdeas i, ProteinFamily family) =>
    i.all.where((f) => proteinFamilyOf(f) == family).length;

void main() {
  const diets = Diet.values;

  test('the generated ideas (printed for owner review)', () {
    for (final phase in Phase.values) {
      for (final diet in diets) {
        // ignore: avoid_print
        print(
          '${phase.name} / ${diet.name}\n'
          'PROTEIN\n${names(ideas(phase, FoodFilter(diet: diet)))}\n'
          'BASE\n${names(base(phase, FoodFilter(diet: diet)))}\n',
        );
      }
    }
  });

  for (final phase in Phase.values) {
    for (final diet in diets) {
      test(
        '${phase.name} / ${diet.name}: a useful, balanced, diet-true set',
        () {
          final i = ideas(phase, FoodFilter(diet: diet));
          final all = i.all;
          expect(all.length, inInclusiveRange(6, 8));
          expect(all.map((f) => f.id).toSet(), hasLength(all.length));
          // Every idea is allowed by the diet.
          for (final f in all) {
            expect(FoodFilter(diet: diet).allowsFood(f), isTrue, reason: f.id);
          }
          // Diversity.
          expect(count(i, ProteinFamily.seafood), lessThanOrEqualTo(2));
          expect(count(i, ProteinFamily.nuts), lessThanOrEqualTo(2));
          expect(count(i, ProteinFamily.plant), greaterThanOrEqualTo(1));
          if (diet != Diet.vegan) {
            expect(count(i, ProteinFamily.egg), 1);
            expect(count(i, ProteinFamily.dairy), greaterThanOrEqualTo(1));
          }
          // Featured foods are featured; "Also good" ones are not.
          final featuredIds = testCatalogue.phase(phase).foodIds.toSet();
          for (final f in i.featured) {
            expect(featuredIds, contains(f.id));
          }
          for (final f in i.general) {
            expect(featuredIds, isNot(contains(f.id)));
          }
          // Soy milk is never a lead idea while anchors exist.
          final ids = all.map((f) => f.id).toList();
          if (ids.contains('soy-milk')) {
            expect(ids.indexOf('soy-milk'), greaterThan(ids.indexOf('tofu')));
          }
        },
      );
    }
  }

  test('vegan: no animal foods at all', () {
    for (final phase in Phase.values) {
      final i = ideas(phase, const FoodFilter(diet: Diet.vegan));
      expect(i.isEmpty, isFalse);
      for (final f in i.all) {
        expect(f.animalSource, AnimalSource.none, reason: f.id);
      }
      expect(count(i, ProteinFamily.egg), 0);
      expect(count(i, ProteinFamily.dairy), 0);
      expect(count(i, ProteinFamily.meat), 0);
      expect(count(i, ProteinFamily.seafood), 0);
    }
  });

  test('vegetarian: no meat or seafood; pescatarian: no meat', () {
    for (final phase in Phase.values) {
      final veg = ideas(phase, const FoodFilter(diet: Diet.vegetarian));
      expect(count(veg, ProteinFamily.meat), 0);
      expect(count(veg, ProteinFamily.seafood), 0);
      final pesc = ideas(phase, const FoodFilter(diet: Diet.pescatarian));
      expect(count(pesc, ProteinFamily.meat), 0);
      expect(count(pesc, ProteinFamily.seafood), greaterThan(0));
    }
  });

  test('a vegetarian in Ovulatory still gets plant, egg and dairy ideas', () {
    final i = ideas(Phase.ovulatory, const FoodFilter(diet: Diet.vegetarian));
    final ids = i.all.map((f) => f.id);
    expect(ids, contains('tofu')); // featured
    expect(i.featured.map((f) => f.id), contains('tofu'));
    expect(ids, contains('eggs')); // general
    expect(i.general.map((f) => f.id), contains('eggs'));
    expect(i.all.length, greaterThanOrEqualTo(6));
  });

  test('allergens and avoided foods are filtered out', () {
    const filter = FoodFilter(
      avoidances: [
        AllergenAvoidance(id: 'a', allergenId: 'soy'),
        AllergenAvoidance(id: 'b', allergenId: 'dairy'),
        AllergenAvoidance(id: 'c', allergenId: 'shellfish'),
        FoodItemAvoidance(id: 'd', foodId: 'eggs'),
      ],
    );
    final i = ideas(Phase.ovulatory, filter);
    expect(i.isEmpty, isFalse);
    for (final f in i.all) {
      expect(filter.allowsFood(f), isTrue, reason: f.id);
    }
    final ids = i.all.map((f) => f.id);
    expect(ids, isNot(contains('tofu')));
    expect(ids, isNot(contains('eggs')));
    expect(ids, isNot(contains('shrimp')));
    expect(count(i, ProteinFamily.dairy), 0);
  });

  test('the Protein category displays as Meat, eggs & plant proteins', () {
    final protein = testCatalogue.categories.firstWhere(
      (c) => c.id == 'protein',
    );
    expect(protein.name, 'Meat, eggs & plant proteins');
    expect(
      testCatalogue.categoryFor(testCatalogue.food('chicken')!).name,
      'Meat, eggs & plant proteins',
    );
  });

  test('a general suggestion has no phase rationale for the viewed phase', () {
    final i = ideas(Phase.ovulatory, const FoodFilter(diet: Diet.vegan));
    for (final f in i.general) {
      expect(f.why[Phase.ovulatory], isNull, reason: f.id);
    }
  });

  group('ranking of general suggestions', () {
    test('Duck is not an early Ovulatory fallback for an omnivore', () {
      final i = ideas(Phase.ovulatory, const FoodFilter());
      final ids = i.all.map((f) => f.id).toList();
      expect(ids, isNot(contains('duck')));
      expect(i.general.map((f) => f.id), containsAll(['eggs', 'chicken']));
    });

    test('familiar proteins come before uncommon ones', () {
      const common = [
        'eggs',
        'chicken',
        'tofu',
        'tempeh',
        'edamame',
        'green-lentil',
        'chickpea',
        'black-turtle-bean',
        'kidney-bean',
        'seitan',
      ];
      for (final phase in Phase.values) {
        for (final diet in diets) {
          final i = ideas(phase, FoodFilter(diet: diet));
          final general = i.general.map((f) => f.id).toList();
          // A rare protein is only used when every common, allowed, not yet
          // shown protein has already been used.
          for (final rare in ['duck', 'adzuki-bean', 'mung-bean', 'octopus']) {
            if (!general.contains(rare)) continue;
            final unused = [
              for (final id in common)
                if (FoodFilter(diet: diet)
                        .allowsFood(testCatalogue.food(id)!) &&
                    !i.all.any((f) => f.id == id))
                  id,
            ];
            expect(unused, isEmpty, reason: '$rare in ${phase.name}/$diet');
          }
        }
      }
    });

    test('vegan: common plant proteins before adzuki beans', () {
      for (final phase in Phase.values) {
        final i = ideas(phase, const FoodFilter(diet: Diet.vegan));
        final ids = i.all.map((f) => f.id).toList();
        expect(ids, isNot(contains('adzuki-bean')), reason: phase.name);
        expect(ids, isNot(contains('mung-bean')), reason: phase.name);
        expect(
          ids
              .where(
                const {
                  'tofu',
                  'tempeh',
                  'edamame',
                  'green-lentil',
                  'red-lentil',
                  'chickpea',
                  'black-turtle-bean',
                  'kidney-bean',
                  'seitan',
                }.contains,
              )
              .length,
          greaterThanOrEqualTo(3),
          reason: phase.name,
        );
      }
      // Ovulatory vegan leads with the familiar anchors.
      final ov = ideas(Phase.ovulatory, const FoodFilter(diet: Diet.vegan));
      expect(ov.general.map((f) => f.id).take(2), ['tempeh', 'edamame']);
    });

    test('adzuki beans return when the common ones are avoided', () {
      final avoid = FoodFilter(
        diet: Diet.vegan,
        avoidances: [
          for (final id in [
            'tofu',
            'tempeh',
            'edamame',
            'green-lentil',
            'red-lentil',
            'chickpea',
            'black-turtle-bean',
            'kidney-bean',
            'seitan',
            'pinto-beans',
            'white-beans',
            'hummus',
            'black-eyed-pea',
            'split-pea',
            'lima-bean',
            'fava-beans',
          ])
            FoodItemAvoidance(id: 'x-$id', foodId: id),
        ],
      );
      final ids = ideas(Phase.ovulatory, avoid).all.map((f) => f.id);
      expect(ids, contains('adzuki-bean'));
    });
  });

  group('base ideas', () {
    test('every phase and diet gets 4–6 practical base choices', () {
      for (final phase in Phase.values) {
        for (final diet in diets) {
          final b = base(phase, FoodFilter(diet: diet));
          expect(b.all.length, inInclusiveRange(4, 6), reason: '$phase/$diet');
          expect(b.all.map((f) => f.id).toSet(), hasLength(b.all.length));
          for (final f in b.all) {
            expect(FoodFilter(diet: diet).allowsFood(f), isTrue);
          }
        }
      }
    });

    test(
      'Ovulatory has no featured grain, yet gets grain and potato bases',
      () {
        final grainIds = {
          for (final f in testCatalogue.foodsFor(Phase.ovulatory))
            if (f.categoryId == 'grains') f.id,
        };
        expect(grainIds, isEmpty);
        final b = base(Phase.ovulatory, const FoodFilter());
        final ids = b.all.map((f) => f.id).toList();
        expect(ids, contains('brown-rice'));
        expect(ids, contains('sweet-potato'));
        expect(ids, contains('whole-grain-bread'));
        // All general: nothing here is featured in Ovulatory.
        expect(b.featured, isEmpty);
        for (final f in b.general) {
          expect(f.why[Phase.ovulatory], isNull, reason: f.id);
        }
      },
    );

    test('featured bases come first where a phase has them', () {
      final b = base(Phase.luteal, const FoodFilter());
      expect(b.featured, isNotEmpty);
      final featuredIds = testCatalogue.phase(Phase.luteal).foodIds.toSet();
      for (final f in b.featured) {
        expect(featuredIds, contains(f.id));
      }
      for (final f in b.general) {
        expect(featuredIds, isNot(contains(f.id)));
      }
    });

    test('gluten avoidance leaves out gluten bases', () {
      const filter = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'g', allergenId: 'gluten')],
      );
      for (final phase in Phase.values) {
        final b = base(phase, filter);
        expect(b.isEmpty, isFalse);
        for (final f in b.all) {
          expect(filter.allowsFood(f), isTrue, reason: f.id);
        }
      }
    });
  });

  test('meal slots: protein, base or plant', () {
    MealSlot slot(String id) => mealSlotFor(testCatalogue.food(id)!);
    expect(slot('broccoli'), MealSlot.plant);
    expect(slot('kale'), MealSlot.plant);
    expect(slot('blueberry'), MealSlot.plant);
    expect(slot('tofu'), MealSlot.protein);
    expect(slot('chicken'), MealSlot.protein);
    expect(slot('chickpea'), MealSlot.protein);
    expect(slot('brown-rice'), MealSlot.base);
    expect(slot('sweet-potato'), MealSlot.base);
  });
}
