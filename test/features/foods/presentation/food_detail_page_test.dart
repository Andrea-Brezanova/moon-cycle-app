import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/test_catalogue.dart';

/// The one dynamic page every food opens: its copy, cautions and four actions.
void main() {
  const noteKey = ValueKey('food-cautions');

  Future<void> pumpDetail(
    WidgetTester tester,
    String id, {
    Phase? phase = Phase.follicular,
    bool general = false,
    double width = 390,
    double textScale = 1,
  }) => pumpScreen(
    tester,
    FoodDetailPage(foodId: id, phase: phase, general: general),
    dark: false,
    width: width,
    textScale: textScale,
    height: 1800,
    overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
  );

  String noteText(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.descendant(of: find.byKey(noteKey), matching: find.byType(Text)),
    );
    return text.textSpan!.toPlainText();
  }

  // The approved examples: the exact wording from the content data.
  const examples = <String, List<String>>{
    'kiwi': [
      'Kiwi can cause allergic reactions; people with latex allergy may also '
          'react.',
    ],
    'oat': ['Choose certified gluten-free oats if avoiding gluten.'],
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
  };

  group('Good to know shows the content’s cautions verbatim', () {
    for (final MapEntry(key: id, value: cautions) in examples.entries) {
      testWidgets(id, (tester) async {
        final food = testCatalogue.food(id)!;
        expect(food.cautions, cautions, reason: 'content wording changed');
        await pumpDetail(tester, id, phase: food.why.keys.first);
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
    expect(testCatalogue.food('asparagus')!.cautions, isEmpty);
    await pumpDetail(tester, 'asparagus', phase: Phase.ovulatory);
    expect(find.byKey(noteKey), findsNothing);
    expect(find.textContaining('Good to know'), findsNothing);
  });

  testWidgets('the note sits between the reason and the actions', (
    tester,
  ) async {
    await pumpDetail(tester, 'kiwi', phase: Phase.menstrual);
    final kiwi = testCatalogue.food('kiwi')!;
    final note = tester.getTopLeft(find.byKey(noteKey)).dy;
    final reason = tester.getTopLeft(
      find.text(kiwi.why[Phase.menstrual]!.short),
    );
    final button = tester.getTopLeft(find.text('Add to shopping list'));
    expect(note, greaterThan(reason.dy));
    expect(note, lessThan(button.dy));
  });

  testWidgets('long cautions wrap on a small phone at 1.5× text', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      'kimchi',
      phase: Phase.luteal,
      width: 320,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(noteKey), findsOneWidget);
  });

  // Every phase recommendation has its own "Why this food?", shown on the page.
  test('every featured food has copy for its featured phase', () {
    for (final phase in Phase.values) {
      for (final food in testCatalogue.foodsFor(phase)) {
        final why = food.why[phase];
        expect(why, isNotNull, reason: '${food.id} in ${phase.name}');
        expect(why!.short.trim(), isNotEmpty, reason: food.id);
        expect(food.why.keys, [phase], reason: food.id);
      }
    }
  });

  for (final phase in Phase.values) {
    final foods = testCatalogue.foodsFor(phase);
    final picks = {
      foods.first,
      foods[foods.length ~/ 2],
      foods.last,
      if (phase == Phase.ovulatory) testCatalogue.food('cucumber')!,
    };
    for (final food in picks) {
      testWidgets('${phase.name}: ${food.id} shows its phase copy', (
        tester,
      ) async {
        await pumpDetail(tester, food.id, phase: phase);
        expect(find.text(food.why[phase]!.short), findsOneWidget);
        expect(find.text('WHY THIS FOOD?'), findsOneWidget);
        expect(
          find.text('Recommended for your ${phase.name} phase'),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('without phase context there is no invented reason', (
    tester,
  ) async {
    await pumpDetail(tester, 'cucumber', phase: Phase.luteal, general: true);
    expect(find.text('WHY THIS FOOD?'), findsNothing);
    expect(find.textContaining('Recommended for your'), findsNothing);
    expect(find.text('ABOUT THIS FOOD'), findsOneWidget);
  });

  testWidgets('a food featured elsewhere shows no reason for this phase', (
    tester,
  ) async {
    // Cucumber is featured in Ovulatory only; opened from Luteal.
    await pumpDetail(tester, 'cucumber', phase: Phase.luteal);
    expect(find.text('WHY THIS FOOD?'), findsNothing);
  });

  testWidgets('the four actions, in order', (tester) async {
    await pumpDetail(tester, 'broccoli', phase: Phase.menstrual);
    final tops = [
      for (final t in [
        'Find recipes with broccoli',
        'Make your own meal with broccoli',
        'Add to shopping list',
        'Add to logged meals · Coming soon',
      ])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(tops.toSet(), hasLength(4));
  });

  testWidgets('every food has a page: any id, no hard-coded pages', (
    tester,
  ) async {
    for (final id in ['broccoli', 'lemon', 'kombu', 'heavy-cream', 'tofu']) {
      await pumpDetail(tester, id, phase: Phase.follicular, general: true);
      expect(find.text(testCatalogue.food(id)!.displayName), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('an unknown id shows a clear message', (tester) async {
    await pumpDetail(tester, 'not-a-food');
    expect(find.text('We couldn’t find that food.'), findsOneWidget);
  });

  testWidgets('the page does not overflow at 320 pt and 1.5× text', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      'broccoli',
      phase: Phase.menstrual,
      width: 320,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
  });
}
