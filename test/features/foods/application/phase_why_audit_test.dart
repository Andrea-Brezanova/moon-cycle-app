import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/foods/presentation/ingredient_sheet.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/test_catalogue.dart';

/// Every phase recommendation has its own "Why this food?" copy, and the
/// ingredient sheet shows it.
void main() {
  Future<void> pumpSheet(WidgetTester tester, Food food, Phase phase) =>
      pumpScreen(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: IngredientSheet(food: food, phase: phase),
          ),
        ),
        dark: false,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );

  test('every recommended food has phase copy in every phase it is in', () {
    for (final phase in Phase.values) {
      for (final food in testCatalogue.foodsFor(phase)) {
        final why = food.why[phase];
        expect(why, isNotNull, reason: '${food.id} in ${phase.name}');
        expect(why!.short.trim(), isNotEmpty, reason: food.id);
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
        await pumpSheet(tester, food, phase);
        expect(find.text(food.why[phase]!.short), findsOneWidget);
        expect(
          find.text('Recommended for your ${phase.name} phase'),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('a food without a phase recommendation shows no rationale', (
    tester,
  ) async {
    const food = Food(
      id: 'test-food',
      name: 'Test food',
      aisleId: 'produce',
      categoryId: 'vegetables',
      animalSource: AnimalSource.none,
      allergenIds: {},
    );
    await pumpSheet(tester, food, Phase.luteal);
    expect(find.textContaining('Recommended for your'), findsNothing);
  });
}
