import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  final c = testCatalogue;
  bool food(FoodFilter f, String id) => f.allowsFood(c.food(id)!);
  bool recipe(FoodFilter f, String id) => f.allowsRecipe(c.recipe(id)!, c);

  group('diet', () {
    test('omnivore keeps everything', () {
      expect(c.foods.every(FoodFilter.none.allowsFood), isTrue);
      expect(
        c.recipes.every((r) => FoodFilter.none.allowsRecipe(r, c)),
        isTrue,
      );
    });

    test('pescatarian: no meat, but fish and eggs', () {
      const f = FoodFilter(diet: Diet.pescatarian);
      expect(food(f, 'chicken'), isFalse);
      expect(food(f, 'salmon'), isTrue);
      expect(food(f, 'eggs'), isTrue);
      expect(recipe(f, 'lemon-herb-chicken-artichoke'), isFalse);
      expect(recipe(f, 'quinoa-salmon-bowl'), isTrue);
    });

    test('vegetarian: no meat or seafood', () {
      const f = FoodFilter(diet: Diet.vegetarian);
      expect(food(f, 'salmon'), isFalse);
      expect(food(f, 'shrimp'), isFalse);
      expect(food(f, 'eggs'), isTrue);
      expect(recipe(f, 'quinoa-salmon-bowl'), isFalse);
    });

    test('vegan: no animal foods (chocolate counted as dairy)', () {
      const f = FoodFilter(diet: Diet.vegan);
      expect(food(f, 'eggs'), isFalse);
      expect(food(f, 'chocolate'), isFalse);
      expect(food(f, 'kale'), isTrue);
      expect(recipe(f, 'berry-coconut-amaranth'), isFalse);
      expect(recipe(f, 'zesty-lentil-broccoli-bowl'), isTrue);
    });
  });

  group('avoidances', () {
    test('an allergen excludes the foods and recipes that carry it', () {
      const f = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'sesame')],
      );
      expect(food(f, 'sesame-seeds'), isFalse);
      expect(food(f, 'sunflower-seeds'), isTrue);
      // Tahini is linked to sesame seeds.
      expect(recipe(f, 'sweet-potato-chickpea-tray'), isFalse);
    });

    test('shellfish covers crustaceans and molluscs', () {
      const f = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'shellfish')],
      );
      expect(food(f, 'shrimp'), isFalse);
      expect(food(f, 'mussel'), isFalse);
      expect(food(f, 'salmon'), isTrue);
    });

    test('a recipe line can carry an allergen its food does not', () {
      const f = FoodFilter(
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'gluten')],
      );
      expect(food(f, 'buckwheat'), isTrue);
      // ...but its buckwheat noodles may contain wheat.
      expect(recipe(f, 'miso-mushroom-kale-soup'), isFalse);
      final lines = f.avoidedLines(c.recipe('miso-mushroom-kale-soup')!, c);
      expect(lines.map((l) => l.label), containsAll(['Buckwheat noodles']));
    });

    test('an avoided food excludes it and its recipes', () {
      const f = FoodFilter(
        avoidances: [FoodItemAvoidance(id: 'a', foodId: 'mushrooms')],
      );
      expect(food(f, 'mushrooms'), isFalse);
      expect(recipe(f, 'miso-mushroom-kale-soup'), isFalse);
      expect(recipe(f, 'beet-adzuki-wild-rice-bowl'), isTrue);
    });

    test('a typed avoidance matches names, plurals and synonyms', () {
      const f = FoodFilter(
        avoidances: [
          CustomAvoidance(id: 'a', label: 'Courgette'),
          CustomAvoidance(id: 'b', label: 'olive oil'),
        ],
      );
      expect(food(f, 'zucchini'), isFalse); // synonym
      expect(recipe(f, 'zesty-lentil-broccoli-bowl'), isFalse);
      // "olive oil" is a non-catalogue line in the chicken recipe.
      expect(recipe(f, 'lemon-herb-chicken-artichoke'), isFalse);
      expect(food(f, 'olives'), isTrue); // "olive oil" isn't "olives"
    });

    test('whole words only: "pea" does not exclude peach', () {
      const f = FoodFilter(
        avoidances: [CustomAvoidance(id: 'a', label: 'pea')],
      );
      expect(food(f, 'peach'), isTrue);
      expect(food(f, 'green-pea'), isFalse);
    });
  });

  test('each phase keeps some foods for every diet', () {
    for (final diet in Diet.values) {
      final f = FoodFilter(diet: diet);
      for (final phase in Phase.values) {
        expect(
          c.foodsFor(phase).where(f.allowsFood),
          isNotEmpty,
          reason: '$diet $phase',
        );
      }
    }
  });
}
