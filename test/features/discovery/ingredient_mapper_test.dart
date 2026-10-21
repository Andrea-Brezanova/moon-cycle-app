import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/content/domain/text_match.dart';
import 'package:moon_cycle/features/discovery/data/providers/ingredient_lines.dart';
import 'package:moon_cycle/features/discovery/data/providers/themealdb_client.dart';
import 'package:moon_cycle/features/discovery/domain/ingredient_mapper.dart';
import 'package:moon_cycle/features/discovery/domain/ingredient_vocabulary.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/fake_provider_http.dart';
import '../../helpers/test_catalogue.dart';

void main() {
  final m = IngredientMapper(testCatalogue);
  IngredientKind kind(String t) => m.classify(t).kind;

  group('the vocabulary is consistent', () {
    test('every alias points at a real food', () {
      for (final e in IngredientVocabulary.aliases.entries) {
        expect(testCatalogue.food(e.value), isNotNull, reason: e.key);
      }
    });

    test('keys are normalised, and no entry is in two classes', () {
      final all = <String, String>{};
      void add(String cls, Iterable<String> keys) {
        for (final k in keys) {
          expect(normaliseName(k), k, reason: '$cls: "$k" is not normalised');
          expect(
            all.containsKey(k),
            isFalse,
            reason: '"$k" in $cls and ${all[k]}',
          );
          all[k] = cls;
        }
      }

      add('alias', IngredientVocabulary.aliases.keys);
      add('pantry', IngredientVocabulary.pantrySafe);
      add('derived', IngredientVocabulary.derived.keys);
      add('ambiguous', IngredientVocabulary.ambiguous);
    });

    test('an alias never changes allergens or animal source', () {
      // An alias must be the same kind of thing: check against the food's data.
      const mustBeAnimal = {
        'prawns': AnimalSource.seafood,
        'ground pork': AnimalSource.meat,
        'sirloin steak': AnimalSource.meat,
        'unsalted butter': AnimalSource.dairy,
        'lamb mince': AnimalSource.meat,
      };
      for (final e in mustBeAnimal.entries) {
        final id =
            IngredientVocabulary.aliases[normaliseName(e.key)] ??
            IngredientVocabulary.aliases['raw ${e.key}']!;
        expect(testCatalogue.food(id)!.animalSource, e.value, reason: e.key);
      }
      expect(testCatalogue.food('pasta')!.allergenIds, contains('gluten'));
    });

    test('derived entries have consistent data', () {
      for (final e in IngredientVocabulary.derived.entries) {
        if (e.value.animal == AnimalSource.dairy) {
          expect(e.value.allergens, contains('dairy'), reason: e.key);
        }
        if (e.value.animal == AnimalSource.seafood) {
          expect(
            e.value.allergens.any((a) => a == 'fish' || a == 'shellfish'),
            isTrue,
            reason: e.key,
          );
        }
      }
    });
  });

  group('classes', () {
    test('foods under other names, spellings and varieties', () {
      for (final (text, id) in [
        ('Garlic', 'garlic'),
        ('minced garlic', 'garlic'),
        ('Garlic Clove', 'garlic'),
        ('Carrots', 'carrot'),
        ('Black Eyed Peas', 'black-eyed-pea'),
        ('Red Onions', 'onion'),
        ('Potatoes', 'white-potato'),
        ('plum tomatoes', 'tomato'),
        ('Tinned Tomatos', 'canned-tomatoes'),
        ('Egg Plants', 'eggplant'),
        ('free-range egg, beaten', 'eggs'),
        ('Basil Leaves', 'basil'),
        ('Green Pepper', 'green-bell-pepper'),
        ('Extra Virgin Olive Oil', 'olive-oil'),
        ('Raw King Prawns', 'shrimp'),
        ('Lemon juice', 'lemon'),
        ('Ground Pork', 'pork'),
        ('Plain Flour', 'wheat-flour'),
        ('Unsalted Butter', 'butter'),
        ('Cannellini Beans', 'white-beans'),
        ('Chicken Legs', 'chicken'),
        ('Egg Yolks', 'eggs'),
        ('Red Potatoes', 'white-potato'),
      ]) {
        final c = m.classify(text);
        expect(c.kind, IngredientKind.food, reason: text);
        expect(c.food!.id, id, reason: text);
      }
    });

    test('plain pantry items', () {
      for (final t in [
        'Water',
        'Sea Salt',
        'Black Pepper',
        'Brown Sugar',
        'Ground Cumin',
        'Paprika',
        'Thyme',
        'Bay Leaf',
        'Chilli Flakes',
        'Cornstarch',
        'Rice Vinegar',
        'Sunflower Oil',
      ]) {
        expect(kind(t), IngredientKind.pantrySafe, reason: t);
      }
    });

    test('known allergens and animal sources', () {
      expect(m.classify('Soy Sauce').derived!.allergens, {'soy', 'gluten'});
      expect(m.classify('Chicken Stock').derived!.animal, AnimalSource.meat);
      expect(
        m.classify('Oyster Sauce').derived!.allergens,
        containsAll(['shellfish', 'soy']),
      );
      expect(m.classify('Chicken broth').derived!.animal, AnimalSource.meat);
      expect(m.classify('Fine sea salt').kind, IngredientKind.pantrySafe);
      expect(m.classify('Mascarpone').derived!.allergens, {'dairy'});
      expect(m.classify('Semolina').derived!.allergens, {'gluten'});
    });

    test('cream, mayonnaise and mustards keep their allergens and class', () {
      final cream = m.classify('Cream').derived!;
      expect(cream.allergens, {'dairy'});
      expect(cream.animal, AnimalSource.dairy);
      // Heavy and whipping cream are the catalogue's own food, with its data.
      for (final t in ['Heavy Cream', 'Whipping Cream']) {
        final f = m.classify(t).food!;
        expect(f.id, 'heavy-cream', reason: t);
        expect(f.allergenIds, contains('dairy'), reason: t);
      }
      final mayo = m.classify('Mayonnaise').derived!;
      expect(mayo.allergens, {'egg'});
      expect(mayo.animal, AnimalSource.egg);
      for (final t in ['Dijon Mustard', 'Mustard', 'English Mustard']) {
        expect(kind(t), IngredientKind.ambiguous, reason: t);
      }
      // Cream is not milk, and mayonnaise is not an egg food.
      expect(m.map('Cream'), isNull);
      expect(m.map('Mayonnaise'), isNull);
    });

    test('ambiguous ones are named, never assumed safe', () {
      for (final t in [
        'Vegetable Oil',
        'Oil',
        'White Wine',
        'Curry Powder',
        'Harissa Spice',
        'Worcestershire Sauce',
        'Capers',
        'Baking Powder',
      ]) {
        expect(kind(t), IngredientKind.ambiguous, reason: t);
        expect(m.classify(t).isIdentified, isFalse, reason: t);
      }
    });

    test('related but different ingredients are not the same food', () {
      for (final t in [
        'Chicken Stock', // not chicken
        'Tomato Sauce', // not tomato
        'Beef Stock', // not beef
        'Sesame Oil', // not sesame
        'Corn Tortillas', // not wheat tortillas
        'Pork Sausage',
      ]) {
        final c = m.classify(t);
        expect(c.kind, isNot(IngredientKind.food), reason: t);
      }
    });

    test('genuinely unknown', () {
      for (final t in [
        'Callaloo',
        'Egg Roll Wrappers',
        'Duck Fat Crisps',
        '',
        '  ',
      ]) {
        expect(kind(t), IngredientKind.unknown, reason: t);
      }
    });
  });

  group('conservative filtering is unchanged', () {
    RecipeIngredient line(String t) => ingredientLine(m, t, quantity: '1');
    Recipe recipe(List<String> items) => Recipe(
      id: 'x',
      title: 'X',
      phase: testCatalogue.recipes.first.phase,
      category: RecipeCategory.dinner,
      minutes: 0,
      serves: 0,
      intro: '',
      whyThisPhase: '',
      keyFoodIds: const [],
      ingredients: [for (final t in items) line(t)],
      steps: const ['a', 'b', 'c'],
    );

    test('a vegan loses a recipe with a meat stock, a vegetarian too', () {
      final r = recipe(['Carrots', 'Chicken Stock']);
      expect(
        const FoodFilter(diet: Diet.vegan).allowsRecipe(r, testCatalogue),
        isFalse,
      );
      expect(
        const FoodFilter(diet: Diet.vegetarian).allowsRecipe(r, testCatalogue),
        isFalse,
      );
      expect(
        const FoodFilter(diet: Diet.pescatarian).allowsRecipe(r, testCatalogue),
        isFalse,
      );
      expect(FoodFilter.none.allowsRecipe(r, testCatalogue), isTrue);
    });

    test('a vegan loses dairy, a pescatarian keeps fish sauce', () {
      expect(
        const FoodFilter(diet: Diet.vegan)
            .allowsRecipe(recipe(['Carrots', 'Mascarpone']), testCatalogue),
        isFalse,
      );
      expect(
        const FoodFilter(diet: Diet.pescatarian)
            .allowsRecipe(recipe(['Carrots', 'Fish Sauce']), testCatalogue),
        isTrue,
      );
      expect(
        const FoodFilter(diet: Diet.vegetarian)
            .allowsRecipe(recipe(['Carrots', 'Fish Sauce']), testCatalogue),
        isFalse,
      );
    });

    test('allergens on derived lines are enforced', () {
      for (final (allergen, item) in [
        ('soy', 'Soy Sauce'),
        ('gluten', 'Soy Sauce'),
        ('gluten', 'Semolina'),
        ('shellfish', 'Oyster Sauce'),
        ('dairy', 'Mascarpone'),
        ('fish', 'Fish Sauce'),
      ]) {
        final f = FoodFilter(
          avoidances: [AllergenAvoidance(id: 'a', allergenId: allergen)],
        );
        expect(
          f.allowsRecipe(recipe(['Carrots', item]), testCatalogue),
          isFalse,
          reason: '$allergen / $item',
        );
      }
    });

    test(
      'wheat flour carries gluten in the dataset and for external lines',
      () {
        expect(
          testCatalogue.food('wheat-flour')!.allergenIds,
          contains('gluten'),
        );
        const f = FoodFilter(
          avoidances: [AllergenAvoidance(id: 'a', allergenId: 'gluten')],
        );
        for (final t in ['Plain Flour', 'Wheat Flour', 'All Purpose Flour']) {
          expect(
            f.allowsRecipe(recipe(['Carrots', t]), testCatalogue),
            isFalse,
            reason: t,
          );
        }
      },
    );

    test('every wheat, rye, barley, flour, pasta or bread food has gluten', () {
      final words = RegExp(
        r'\b(wheat|rye|barley|flour|pasta|couscous|bread)\b',
      );
      for (final food in testCatalogue.foods) {
        final text = '${food.id} ${food.displayName}'.toLowerCase().replaceAll(
          '-',
          ' ',
        );
        if (words.hasMatch(text)) {
          expect(food.allergenIds, contains('gluten'), reason: food.id);
        }
      }
    });

    test('mayonnaise and cream still block vegans and egg/dairy avoiders', () {
      final mayo = recipe(['Carrots', 'Mayonnaise']);
      final cream = recipe(['Carrots', 'Cream']);
      expect(
        const FoodFilter(diet: Diet.vegan).allowsRecipe(mayo, testCatalogue),
        isFalse,
      );
      expect(
        const FoodFilter(diet: Diet.vegan).allowsRecipe(cream, testCatalogue),
        isFalse,
      );
      for (final (allergen, r) in [('egg', mayo), ('dairy', cream)]) {
        final f = FoodFilter(
          avoidances: [AllergenAvoidance(id: 'a', allergenId: allergen)],
        );
        expect(f.allowsRecipe(r, testCatalogue), isFalse, reason: allergen);
      }
      // A chicken leg is still meat, egg yolk still egg.
      expect(
        const FoodFilter(diet: Diet.vegetarian)
            .allowsRecipe(recipe(['Chicken Legs']), testCatalogue),
        isFalse,
      );
      expect(
        const FoodFilter(
          avoidances: [AllergenAvoidance(id: 'a', allergenId: 'egg')],
        ).allowsRecipe(recipe(['Egg Yolks']), testCatalogue),
        isFalse,
      );
    });

    test('peanut butter keeps the dataset flags', () {
      expect(
        m.map('Peanut Butter')!.allergenIds,
        containsAll(['peanut', 'tree-nut']),
      );
      const f = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'peanut')],
      );
      expect(
        f.allowsRecipe(recipe(['Carrots', 'Peanut Butter']), testCatalogue),
        isFalse,
      );
    });

    test('a typed avoidance still catches a pantry line by name', () {
      const f = FoodFilter(
        avoidances: [CustomAvoidance(id: 'c', label: 'cumin')],
      );
      expect(
        f.allowsRecipe(recipe(['Carrots', 'Ground Cumin']), testCatalogue),
        isFalse,
      );
    });
  });

  test('statistics on 80 real TheMealDB recipes, before and after', () {
    final lookups =
        readFixture('themealdb_lookups.json') as Map<String, Object?>;
    var lines = 0,
        food = 0,
        pantry = 0,
        derived = 0,
        ambiguous = 0,
        unknown = 0;
    var recipes = 0, usableWhenRestricted = 0;
    for (final v in lookups.values) {
      final meal = ((v as Map)['meals'] as List).first as Map;
      var ok = true;
      recipes++;
      for (var n = 1; n <= 20; n++) {
        final i = (meal['strIngredient$n'] as String?)?.trim();
        if (i == null || i.isEmpty) continue;
        lines++;
        final c = m.classify(i);
        switch (c.kind) {
          case IngredientKind.food:
            food++;
          case IngredientKind.pantrySafe:
            pantry++;
          case IngredientKind.derived:
            derived++;
          case IngredientKind.ambiguous:
            ambiguous++;
            ok = false;
          case IngredientKind.unknown:
            unknown++;
            ok = false;
        }
      }
      if (ok) usableWhenRestricted++;
    }
    // Before this vocabulary: 428 of 874 lines mapped to a food (49%), 97 more
    // were plain salt/water/pepper/sugar, and 1 of 80 recipes could be shown to
    // a user with any restriction.
    // ignore: avoid_print
    print(
      'MAPPING recipes=$recipes lines=$lines food=$food pantry=$pantry '
      'derived=$derived ambiguous=$ambiguous unknown=$unknown '
      'identified=${food + pantry + derived} '
      '(${(100 * (food + pantry + derived) / lines).round()}%) '
      'recipesUsableWhenRestricted=$usableWhenRestricted',
    );
    expect(lines, greaterThan(800));
    expect(food + pantry + derived, greaterThan(428 + 97));
    expect(usableWhenRestricted, greaterThan(1));
    expect(TheMealDbClient.id, 'themealdb');
  });
}
