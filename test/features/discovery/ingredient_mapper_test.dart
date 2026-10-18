import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/discovery/domain/ingredient_mapper.dart';

import '../../helpers/test_catalogue.dart';

void main() {
  final m = IngredientMapper(testCatalogue);

  test('exact names, case, plurals and harmless words map', () {
    for (final (text, id) in [
      ('Garlic', 'garlic'),
      ('garlic', 'garlic'),
      ('Carrots', 'carrot'),
      ('Black Eyed Peas', 'black-eyed-pea'),
      ('minced garlic', 'garlic'),
      ('Fresh Spinach', 'spinach'),
      ('chopped Onion', 'onion'),
      ('Olive Oil', 'olive-oil'),
    ]) {
      expect(m.map(text)?.id, id, reason: text);
    }
  });

  test('near misses are left unmapped, never guessed', () {
    for (final text in [
      'chicken stock', // not chicken
      'Plain Flour',
      'Soy sauce',
      '',
      '   ',
    ]) {
      expect(m.map(text), isNull, reason: text);
    }
  });

  test('only plain water, salt, pepper and sugar are always safe', () {
    for (final t in [
      'Water',
      'salt',
      'Sea Salt',
      'Black Pepper',
      'Sugar',
      'ice',
    ]) {
      expect(IngredientMapper.isAlwaysSafe(t), isTrue, reason: t);
    }
    for (final t in [
      'Sesame oil',
      'Stock',
      'Soy sauce',
      'Worcestershire sauce',
      'Curry powder',
      'Butter',
      'Mayonnaise',
      'Peanut oil',
    ]) {
      expect(IngredientMapper.isAlwaysSafe(t), isFalse, reason: t);
    }
  });
}
