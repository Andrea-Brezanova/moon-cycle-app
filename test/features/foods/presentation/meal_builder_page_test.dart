import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/foods/presentation/widgets/meal_option_chip.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';

void main() {
  Future<void> pumpBuilder(
    WidgetTester tester, {
    String? foodId,
    double width = 390,
    double textScale = 1,
  }) => pumpScreen(
    tester,
    MealBuilderPage(foodId: foodId),
    dark: false,
    width: width,
    textScale: textScale,
    height: 3200,
    overrides: [
      cycleStateProvider.overrideWithValue(stateOnDay(7)), // follicular
      entitlementStateProvider.overrideWithValue(
        const EntitlementState(tier: Tier.premium),
      ),
    ],
  );

  /// A chip, found by its food name.
  Finder chip(String name) => find.widgetWithText(MealOptionChip, name);

  /// A chip that is chosen.
  Finder chosen(String name) => find.byWidgetPredicate(
    (w) => w is MealOptionChip && w.food.displayName == name && w.selected,
  );

  testWidgets('three steps, each with options', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester);
    expect(find.text('Choose a protein'), findsOneWidget);
    expect(find.text('Choose a base'), findsOneWidget);
    expect(find.textContaining('Add 2–3 plants'), findsOneWidget);
    expect(find.textContaining('0 of 3'), findsOneWidget);
    expect(find.text('Nothing chosen yet.'), findsOneWidget);
    // Featured-in-this-phase foods say so; the others are plain.
    expect(
      find.bySemanticsLabel(RegExp('featured in your follicular phase')),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('choose a protein and a base; choosing again replaces or '
      'un-chooses', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester);
    await tester.tap(chip('Chicken').first);
    await tester.pumpAndSettle();
    expect(chosen('Chicken'), findsOneWidget);
    expect(find.textContaining('Chicken'), findsWidgets);
    await tester.tap(chip('Eggs').first);
    await tester.pumpAndSettle();
    expect(chosen('Chicken'), findsNothing);
    expect(chosen('Eggs'), findsOneWidget);
    await tester.tap(chosen('Eggs'));
    await tester.pumpAndSettle();
    expect(chosen('Eggs'), findsNothing);
    handle.dispose();
  });

  testWidgets('at most three plants; the rest wait until one is removed', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester);
    final plants = ['Carrot', 'Lettuce', 'Arugula', 'Avocado'];
    for (final p in plants.take(3)) {
      await tester.tap(chip(p).first);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('3 of 3'), findsOneWidget);
    await tester.tap(chip('Avocado').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen('Avocado'), findsNothing);
    expect(find.textContaining('3 of 3'), findsOneWidget);
    await tester.tap(chosen('Carrot'));
    await tester.pumpAndSettle();
    await tester.tap(chip('Avocado').first);
    await tester.pumpAndSettle();
    expect(chosen('Avocado'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a food from another phase is never hidden: search and '
      'choose it', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester);
    // Cucumber is featured in Ovulatory; we are viewing Follicular.
    await tester.enterText(find.byType(EditableText), 'cucumber');
    await tester.pumpAndSettle();
    expect(chip('Cucumber'), findsOneWidget);
    final cucumber = tester.widget<MealOptionChip>(chip('Cucumber'));
    expect(cucumber.featured, isFalse); // general, not tinted
    await tester.tap(chip('Cucumber'));
    await tester.pumpAndSettle();
    expect(chosen('Cucumber'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('"Show all" reveals the full list', (tester) async {
    await pumpBuilder(tester);
    final before = tester.widgetList(find.byType(Wrap)).length;
    final link = find.textContaining('Show all');
    expect(link, findsWidgets);
    final plantsLink = link.last;
    await tester.ensureVisible(plantsLink);
    await tester.tap(plantsLink);
    await tester.pumpAndSettle();
    expect(find.text('Show fewer'), findsOneWidget);
    expect(tester.widgetList(find.byType(Wrap)).length, before);
  });

  testWidgets('a starting food from its page is already chosen, in its slot', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester, foodId: 'broccoli');
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of 3'), findsOneWidget);
    expect(chosen('Broccoli'), findsWidgets);
    expect(find.textContaining('Broccoli'), findsWidgets);
    // Editable: tap it to remove.
    await tester.tap(chosen('Broccoli').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('0 of 3'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a complete meal: summary, and Create is available', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester);
    expect(find.textContaining('Still to choose'), findsOneWidget);
    for (final n in ['Chicken', 'Farro', 'Carrot', 'Lettuce']) {
      await tester.tap(chip(n).first);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Still to choose'), findsNothing);
    expect(find.text('Chicken · Farro · Carrot · Lettuce'), findsOneWidget);
    // Create is available now; it opens the results (tested in
    // meal_results_page_test.dart).
    expect(find.text('Create my meal'), findsOneWidget);
    await tester.tap(find.text('Clear my choices'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing chosen yet.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('at 320 pt and 1.5× text: no overflow, tap targets fine', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester, foodId: 'broccoli', width: 320, textScale: 1.5);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
