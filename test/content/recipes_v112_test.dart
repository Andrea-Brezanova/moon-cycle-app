import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../helpers/test_catalogue.dart';

/// The expanded Recipes v2 contract (112 recipes), checked with the app's own
/// parser and filters.
void main() {
  final recipes = testCatalogue.recipes;

  FoodFilter filterOf({
    Diet diet = Diet.omnivore,
    List<String> avoid = const [],
  }) => FoodFilter(
    diet: diet,
    avoidances: [
      for (final a in avoid) AllergenAvoidance(id: 'a-$a', allergenId: a),
    ],
  );

  List<Recipe> allowed(FoodFilter f, [Phase? phase]) => [
    for (final r in recipes)
      if ((phase == null || r.phase == phase) &&
          f.allowsRecipe(r, testCatalogue))
        r,
  ];

  Map<MealType, int> slots(FoodFilter f, Phase phase) {
    final list = allowed(f, phase);
    return {
      for (final m in MealType.values)
        m: list.where((r) => r.mealType == m).length,
    };
  }

  test('catalogue sizes', () {
    expect(testCatalogue.foods.length, 254);
    expect(recipes, hasLength(112));
    expect(recipes.map((r) => r.id).toSet(), hasLength(112));
    final featured = {
      for (final p in Phase.values) ...testCatalogue.phase(p).foodIds,
    };
    expect(featured, hasLength(142));
    expect(
      {for (final p in Phase.values) p: testCatalogue.phase(p).foodIds.length},
      {
        Phase.menstrual: 35,
        Phase.follicular: 32,
        Phase.ovulatory: 31,
        Phase.luteal: 44,
      },
    );
  });

  test('recipes per phase and meal type', () {
    expect(
      {for (final p in Phase.values) p: testCatalogue.recipesFor(p).length},
      {
        Phase.menstrual: 27,
        Phase.follicular: 29,
        Phase.ovulatory: 26,
        Phase.luteal: 30,
      },
    );
    int category(RecipeCategory c) =>
        recipes.where((r) => r.category == c).length;
    expect(category(RecipeCategory.breakfast), 30);
    expect(category(RecipeCategory.lunch), 28);
    expect(category(RecipeCategory.dinner), 43);
    expect(category(RecipeCategory.snack), 11);
  });

  test('diet derivation with the app filter: 44 / 28 / 29 / 11', () {
    // Research counts 44 vegan, 29 vegetarian, 28 pescatarian, 11
    // omnivore. The app's conservative rule (a recipe with kimchi, which
    // may contain fish, is not offered as vegetarian) moves the kimchi egg
    // rice bowl from vegetarian to pescatarian.
    final vegan = allowed(filterOf(diet: Diet.vegan)).map((r) => r.id).toSet();
    final veg = allowed(filterOf(diet: Diet.vegetarian))
        .map((r) => r.id)
        .toSet();
    final pesc = allowed(filterOf(diet: Diet.pescatarian))
        .map((r) => r.id)
        .toSet();
    expect(vegan, hasLength(44));
    expect(veg.difference(vegan), hasLength(28));
    expect(pesc.difference(veg), hasLength(29));
    expect(pesc.difference(veg), contains('kimchi-egg-brown-rice-bowl'));
    expect(recipes.length - pesc.length, 11);
  });

  test('the ten gap-fill recipes are vegan, gluten-free and dairy-free', () {
    const titles = [
      'Nectarine & Pecan Chia Pudding',
      'Black-Eyed Pea, Avocado & Sauerkraut Breakfast Bowl',
      'Quinoa, Hummus & Pomegranate Bowl',
      'Bok Choy, Turnip & Tofu Rice Bowl',
      'Stone Fruit & Brazil Nut Snack Plate',
      'Mango & Raspberry Chia Pudding',
      'Peach, Raspberry & Hazelnut Breakfast Quinoa',
      'Lime-Ginger Tofu & Pineapple Rice Bowl',
      'Banana & Buckwheat Porridge with Soy Milk',
      'Split Pea & Parsnip Soup',
    ];
    final filter = filterOf(diet: Diet.vegan, avoid: ['gluten', 'dairy']);
    expect(recipes.skip(102).map((r) => r.title), titles);
    for (final r in recipes.skip(102)) {
      expect(filter.allowsRecipe(r, testCatalogue), isTrue, reason: r.title);
    }
  });

  test(
    'the first 102 recipes keep their order (and the first 40 their ids)',
    () {
      expect(recipes.first.id, 'lentil-spinach-tomato-stew');
      expect(recipes[39].id, 'lamb-split-pea-one-pot');
    },
  );

  test('targeted filter slots (real filter code)', () {
    Map<MealType, int> s(FoodFilter f, Phase p) => slots(f, p);
    Map<MealType, int> want(int b, int m, int sn) => {
      MealType.breakfast: b,
      MealType.meals: m,
      MealType.snacks: sn,
    };
    expect(s(filterOf(diet: Diet.vegan), Phase.follicular), want(2, 5, 2));
    expect(
      s(filterOf(diet: Diet.vegan, avoid: ['gluten']), Phase.follicular),
      want(2, 3, 1),
    );
    expect(s(filterOf(avoid: ['dairy']), Phase.ovulatory), want(3, 10, 2));
    expect(s(filterOf(avoid: ['gluten']), Phase.follicular), want(5, 8, 1));
    expect(
      s(filterOf(diet: Diet.vegan, avoid: ['gluten']), Phase.ovulatory),
      want(3, 2, 2),
    );
    expect(
      s(filterOf(diet: Diet.vegan, avoid: ['gluten']), Phase.luteal),
      want(1, 3, 1),
    );
  });

  test('featured-food recipe coverage: none uncovered, 22 with one', () {
    final counts = <String, int>{};
    for (final r in recipes) {
      for (final id in {
        ...r.keyFoodIds,
        ...r.ingredients.map((l) => l.foodId).nonNulls,
      }) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    final featured = {
      for (final p in Phase.values) ...testCatalogue.phase(p).foodIds,
    };
    final zero = featured.where((id) => (counts[id] ?? 0) == 0);
    final one = featured.where((id) => counts[id] == 1);
    final many = featured.where((id) => (counts[id] ?? 0) >= 2);
    expect(zero, isEmpty);
    expect(one, hasLength(22));
    expect(many, hasLength(120));
  });

  test('butter and honey', () {
    final butter = testCatalogue.food('butter')!;
    expect(butter.animalSource.name, 'dairy');
    expect(butter.allergenIds, contains('dairy'));
    expect(filterOf(diet: Diet.vegan).allowsFood(butter), isFalse);
    expect(filterOf(diet: Diet.vegetarian).allowsFood(butter), isTrue);
    expect(filterOf(avoid: ['dairy']).allowsFood(butter), isFalse);
    final honey = testCatalogue.food('honey')!;
    expect(honey.animalSource.name, 'honey');
    expect(filterOf(diet: Diet.vegan).allowsFood(honey), isFalse);
    expect(filterOf(diet: Diet.vegetarian).allowsFood(honey), isTrue);
    expect(filterOf(diet: Diet.pescatarian).allowsFood(honey), isTrue);
  });

  test('mushroom aliases resolve to mushrooms', () {
    for (final name in [
      'portobello',
      'portobello mushroom',
      'cremini',
      'cremini mushroom',
      'baby bella',
      'baby bella mushroom',
      'button mushroom',
      'white mushroom',
    ]) {
      expect(testCatalogue.foodNamed(name)?.id, 'mushrooms', reason: name);
    }
  });

  test('new general foods exist and are not featured', () {
    final featured = {
      for (final p in Phase.values) ...testCatalogue.phase(p).foodIds,
    };
    for (final id in [
      'basil',
      'cilantro',
      'dill',
      'heavy-cream',
      'tomato-paste',
    ]) {
      expect(testCatalogue.food(id), isNotNull, reason: id);
      expect(featured, isNot(contains(id)));
    }
    expect(testCatalogue.foodNamed('coriander')?.id, 'cilantro');
  });

  test('every dairy food is on the dairy aisle; kefir stays fermented', () {
    for (final f in testCatalogue.foods) {
      // Chocolate and naan are pantry/bakery items that are marked dairy (so
      // vegans never see them); everything else dairy lives on the dairy
      // aisle (kefir is fermented).
      if (f.animalSource.name == 'dairy' &&
          !{'chocolate', 'naan'}.contains(f.id)) {
        expect(
          f.aisleId,
          anyOf('dairy-alternatives', 'fermented'),
          reason: f.id,
        );
        expect(f.aisleId, isNot('other'), reason: f.id);
      }
    }
    expect(testCatalogue.food('kefir')!.aisleId, 'fermented');
    for (final id in [
      'cheddar',
      'feta',
      'milk',
      'greek-yogurt',
      'ricotta',
      'butter',
    ]) {
      expect(testCatalogue.food(id)!.aisleId, 'dairy-alternatives', reason: id);
    }
    expect(
      testCatalogue.foods.where((f) => f.aisleId == 'other').map((f) => f.id),
      isNot(contains('milk')),
    );
  });
}
