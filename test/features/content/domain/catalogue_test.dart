import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/content/domain/text_match.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  final c = testCatalogue;

  test('a parenthetical becomes the qualifier', () {
    final lettuce = c.food('lettuce')!;
    expect(lettuce.displayName, 'Lettuce');
    expect(lettuce.qualifier, 'Bibb, Boston, romaine');
    expect(c.food('kale')!.qualifier, isNull);
  });

  test('foods for a phase follow the stored category order', () {
    final follicular = c.phase(Phase.follicular);
    expect(follicular.categories.first.category.name, 'Grains');
    expect(c.foodsFor(Phase.follicular).first.id, 'farro');
  });

  test('each highlighted food has copy for its one featured phase only', () {
    final oat = c.food('oat')!;
    expect(oat.why.keys, [Phase.luteal]);
    expect(oat.why[Phase.luteal]!.short, isNotEmpty);
    for (final phase in Phase.values) {
      for (final food in c.foodsFor(phase)) {
        expect(food.why.keys, [phase], reason: food.id);
      }
    }
  });

  test('typed names find foods by name or synonym, never by plural guess', () {
    expect(c.foodNamed('  courgette ')!.id, 'zucchini');
    expect(c.foodNamed('Spring onion')!.id, 'scallion');
    expect(c.foodNamed('Lettuce')!.id, 'lettuce');
    expect(c.foodNamed('Buckwheat (kasha)')!.id, 'buckwheat');
    expect(c.foodNamed('oat milk')!.id, 'oat-milk');
    expect(c.foodNamed('strawberries'), isNull); // no plural guessing
    expect(c.foodNamed(''), isNull);
  });

  test('lunch and dinner show as Meals', () {
    expect(RecipeCategory.lunch.mealType, MealType.meals);
    expect(RecipeCategory.dinner.mealType, MealType.meals);
    expect(RecipeCategory.breakfast.mealType, MealType.breakfast);
    expect(c.recipes.where((r) => r.mealType == MealType.snacks), hasLength(4));
  });

  group('quantities (spec §9)', () {
    String q(String recipeId, int line) =>
        c.recipe(recipeId)!.ingredients[line].quantityLabel;

    test(
      'cup with a metric companion, singular at one',
      () => expect(q('lentil-spinach-tomato-stew', 0), '1 cup (200 g)'),
    );
    test(
      'US weight with metric',
      () => expect(q('lentil-spinach-tomato-stew', 1), '7 oz (200 g)'),
    );
    test(
      'a can with its size',
      () => expect(q('lentil-spinach-tomato-stew', 2), '1 can (14 oz / 400 g)'),
    );
    test(
      'a piece shows the number alone',
      () => expect(q('lentil-spinach-tomato-stew', 3), '1'),
    );
    test(
      'plural cups and ml',
      () => expect(q('chard-white-bean-potato-soup', 6), '4 cups (1000 ml)'),
    );
    test(
      'plural cans',
      () => expect(
        q('sardine-spinach-lemon-toast', 0),
        '2 cans (4 oz / 120 g each)',
      ),
    );
    test(
      'tbsp stays abbreviated',
      () => expect(q('lentil-spinach-tomato-stew', 6), '1 tbsp'),
    );
    test('halves', () => expect(q('papaya-kiwi-orange-bowl', 0), '½'));
    test('words', () {
      const line = RecipeIngredient(
        label: 'Blueberries',
        qtyText: 'to serve',
        aisleId: 'produce',
      );
      expect(line.quantityLabel, 'to serve');
    });
    test('formatAmount', () {
      expect(formatAmount(1.5), '1½');
      expect(formatAmount(0.25), '¼');
      expect(formatAmount(2), '2');
      expect(formatAmount(1.2), '1.2');
    });
  });

  test('normaliseName and containsPhrase', () {
    expect(normaliseName('  Spring-Onions! '), 'spring onions');
    expect(containsPhrase('Shiitake mushrooms', 'mushroom'), isTrue);
    expect(containsPhrase('Peach', 'pea'), isFalse);
    expect(containsPhrase('Tomatoes', 'tomato'), isTrue);
  });
}
