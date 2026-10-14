import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/foods/presentation/ingredient_sheet.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/test_catalogue.dart';

/// The "Good to know" cautions on the ingredient sheet: shown only when the
/// food has cautions, worded exactly as in the content.
void main() {
  const noteKey = ValueKey('food-cautions');

  Future<void> pumpSheet(
    WidgetTester tester,
    Food food, {
    Phase phase = Phase.follicular,
    double textScale = 1,
  }) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: IngredientSheet(food: food, phase: phase),
            ),
          ),
        ),
      ),
      dark: false,
      overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
    );
  }

  String noteText(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.descendant(of: find.byKey(noteKey), matching: find.byType(Text)),
    );
    return text.textSpan!.toPlainText();
  }

  Food catalogueFood(String id) => testCatalogue.food(id)!;

  // The approved examples: the exact wording from the content data.
  const examples = <String, List<String>>{
    'kiwi': [
      'Kiwi can cause allergic reactions; people with latex allergy may also '
          'react.',
    ],
    'oat': ['Choose certified gluten-free oats if avoiding gluten.'],
    'oat-bran': ['Choose certified gluten-free oats if avoiding gluten.'],
    'spinach': [
      'High in oxalate',
      'Very high vitamin K: keep intake consistent if taking warfarin',
    ],
    'kale': ['Very high vitamin K: keep intake consistent if taking warfarin'],
    'tempeh': ['Soy allergen', 'Check the label for gluten-containing grains'],
    'kimchi': [
      'Check the label for fish sauce or shrimp, and for vegetarian or vegan '
          'status',
      'High in salt',
    ],
    'clam': ['Cook thoroughly', 'Mollusc allergen'],
    'mussel': ['Cook thoroughly', 'Mollusc allergen'],
  };

  group('the content examples show their cautions verbatim', () {
    for (final MapEntry(key: id, value: cautions) in examples.entries) {
      testWidgets(id, (tester) async {
        final food = catalogueFood(id);
        expect(food.cautions, cautions, reason: 'content wording changed');
        await pumpSheet(tester, food);
        expect(find.byKey(noteKey), findsOneWidget);
        final bullet = cautions.length > 1 ? '• ' : '';
        expect(
          noteText(tester),
          ['Good to know', for (final c in cautions) '$bullet$c'].join('\n'),
        );
      });
    }
  });

  testWidgets('no caution section when the food has none', (tester) async {
    final food = catalogueFood('asparagus');
    expect(food.cautions, isEmpty);
    await pumpSheet(tester, food);
    expect(find.byKey(noteKey), findsNothing);
    expect(find.text('Good to know'), findsNothing);
    expect(find.textContaining('Good to know'), findsNothing);
  });

  testWidgets('the note sits between the copy and the buttons', (tester) async {
    final kiwi = catalogueFood('kiwi');
    await pumpSheet(tester, kiwi, phase: Phase.menstrual);
    final note = tester.getTopLeft(find.byKey(noteKey)).dy;
    final copy = tester.getTopLeft(find.text(kiwi.why[Phase.menstrual]!.short));
    final button = tester.getTopLeft(find.text('Add to shopping list'));
    expect(note, greaterThan(copy.dy));
    expect(note, lessThan(button.dy));
  });

  testWidgets('a long caution wraps without overflowing, even at 1.5×', (
    tester,
  ) async {
    const long =
        'This is a deliberately long caution that has to wrap across several '
        'lines on a narrow phone at a large text size without overflowing '
        'its note or the sheet, and without being cut off, truncated or '
        'ellipsised anywhere along the way.';
    const food = Food(
      id: 'test-food',
      name: 'Test food',
      aisleId: 'produce',
      categoryId: 'vegetables',
      animalSource: AnimalSource.none,
      allergenIds: {},
      cautions: [long, 'A second, shorter caution'],
    );
    await pumpSheet(tester, food, textScale: 1.5);
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byKey(noteKey));
    expect(size.width, lessThanOrEqualTo(390));
    expect(size.height, greaterThan(150)); // wrapped onto many lines
    expect(
      noteText(tester),
      'Good to know\n• $long\n• A second, shorter caution',
    );
  });

  testWidgets('semantics include the caution text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSheet(tester, catalogueFood('kimchi'));
    expect(find.bySemanticsLabel(RegExp('Good to know')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('fish sauce or shrimp')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('High in salt')), findsOneWidget);
    handle.dispose();
  });
}
