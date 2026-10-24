import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/generation/domain/recipe_text_parser.dart';

void main() {
  test('a recipe with headings: title, serves, times, lists, notes', () {
    final r = parsePastedRecipe('''
Gran’s Lentil Soup
Serves 4
Prep time: 15 minutes
Cook time: 30 minutes

Ingredients
- 150 g green lentils
- 1 onion, chopped
• 2 tbsp olive oil
A pinch of salt

Method
1. Soften the onion in the oil.
2. Add the lentils and 600 ml water.
Step 3: Simmer for 30 minutes.

Notes
Keeps well for three days.
''');
    expect(r.title, 'Gran’s Lentil Soup');
    expect(r.serves, 4);
    expect(r.minutes, 45); // prep + cook
    expect(r.ingredients, [
      '150 g green lentils',
      '1 onion, chopped',
      '2 tbsp olive oil',
      'A pinch of salt',
    ]);
    expect(r.steps, [
      'Soften the onion in the oil.',
      'Add the lentils and 600 ml water.',
      'Simmer for 30 minutes.',
    ]);
    expect(r.notes, 'Keeps well for three days.');
  });

  test('without headings: amounts are ingredients, sentences are steps', () {
    final r = parsePastedRecipe('''
Quick Toast
2 slices bread
½ avocado
A handful of rocket
Toast the bread. Mash the avocado on top.
Add the rocket and serve.
''');
    expect(r.title, 'Quick Toast');
    expect(r.ingredients, [
      '2 slices bread',
      '½ avocado',
      'A handful of rocket',
    ]);
    expect(r.steps, [
      'Toast the bread. Mash the avocado on top.',
      'Add the rocket and serve.',
    ]);
  });

  test(
    'total time wins; hours and minutes are added; bad times are ignored',
    () {
      expect(
        parsePastedRecipe('Pie\nTotal time: 1 hour 10 minutes').minutes,
        70,
      );
      expect(
        parsePastedRecipe('Pie\nPrep 10 min\nTotal time: 50 min').minutes,
        50,
      );
      expect(parsePastedRecipe('Pie\nReady in 25 minutes').minutes, 25);
      expect(parsePastedRecipe('Pie\nCook time: soon').minutes, isNull);
      expect(parseDuration('99999 minutes'), isNull);
    },
  );

  test('servings in several shapes; none means none', () {
    expect(parsePastedRecipe('A\nServes 6').serves, 6);
    expect(parsePastedRecipe('A\nServings: 2-3').serves, 2);
    expect(parsePastedRecipe('A\nYield: 8 servings').serves, 8);
    expect(parsePastedRecipe('A\n4 servings').serves, 4);
    expect(parsePastedRecipe('A\n2 eggs').serves, isNull);
  });

  test('nothing is invented: unplaceable text lands in the notes', () {
    final r = parsePastedRecipe('Just a thought about dinner tonight.');
    expect(r.ingredients, isEmpty);
    expect(r.steps, isEmpty);
    expect(r.serves, isNull);
    expect(r.minutes, isNull);
    // It is a short line, so it is read as a title; nothing else appears.
    expect(r.title, 'Just a thought about dinner tonight.');
    final long = parsePastedRecipe('x' * 120);
    expect(long.title, isEmpty);
    expect(long.notes, 'x' * 120);
    expect(parsePastedRecipe('   \n\n ').isEmpty, isTrue);
  });

  test('a heading-only paste and CRLF line endings both work', () {
    final r = parsePastedRecipe(
      'Soup\r\nIngredients:\r\n1 cup stock\r\nDirections:\r\nHeat it.\r\n',
    );
    expect(r.title, 'Soup');
    expect(r.ingredients, ['1 cup stock']);
    expect(r.steps, ['Heat it.']);
  });

  test('pasting the same text twice gives the same draft', () {
    const text = 'Toast\n2 slices bread\nToast it.';
    final a = parsePastedRecipe(text);
    final b = parsePastedRecipe(text);
    expect(a.title, b.title);
    expect(a.ingredients, b.ingredients);
    expect(a.steps, b.steps);
  });
}
