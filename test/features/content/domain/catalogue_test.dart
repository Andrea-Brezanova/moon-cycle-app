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
    expect(c.foodsFor(Phase.follicular).first.id, 'oat');
  });

  test('foods recommended in two phases have copy for both', () {
    final oats = c.food('oat')!;
    expect(
      oats.why.keys,
      containsAll([Phase.menstrual, Phase.follicular, Phase.luteal]),
    );
    expect(
      oats.why[Phase.luteal]!.short,
      isNot(oats.why[Phase.menstrual]!.short),
    );
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
    expect(c.recipes.where((r) => r.mealType == MealType.snacks), isEmpty);
  });

  group('quantities (spec §9)', () {
    String q(String recipeId, int line) =>
        c.recipe(recipeId)!.ingredients[line].quantityLabel;

    test(
      'amount and unit',
      () => expect(q('zesty-lentil-broccoli-bowl', 0), '150 g'),
    );
    test(
      'a piece shows the number alone',
      () => expect(q('zesty-lentil-broccoli-bowl', 2), '1'),
    );
    test('words', () => expect(q('zesty-lentil-broccoli-bowl', 7), 'to serve'));
    test('halves', () => expect(q('sweet-potato-chickpea-tray', 1), '½'));
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
