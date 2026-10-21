import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/widgets/moon_button.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart'
    show MealSlot;
import 'package:moon_cycle/features/foods/application/meal_selection.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/foods/presentation/widgets/food_chip.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/test_catalogue.dart';

void main() {
  Future<void> pumpBuilder(
    WidgetTester tester, {
    String? foodId,
    double width = 390,
    double textScale = 1,
    int day = 7, // follicular
  }) => pumpScreen(
    tester,
    MealBuilderPage(foodId: foodId),
    dark: false,
    width: width,
    textScale: textScale,
    height: 3600,
    overrides: [
      cycleStateProvider.overrideWithValue(stateOnDay(day)),
      entitlementStateProvider.overrideWithValue(
        const EntitlementState(tier: Tier.premium),
      ),
    ],
  );

  /// A chip, found by its food name.
  Finder chip(String name) => find.byWidgetPredicate(
    (w) => w is FoodChip && w.food.displayName == name,
  );

  /// A chip that is chosen.
  Finder chosen(String name) => find.byWidgetPredicate(
    (w) => w is FoodChip && w.food.displayName == name && w.selected,
  );

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MealBuilderPage)));

  Finder section(MealSlot s) => find.byKey(ValueKey('section-${s.name}'));

  Finder chipIn(MealSlot s, String name) =>
      find.descendant(of: section(s), matching: chip(name));

  testWidgets('new copy and three optional sections', (tester) async {
    await pumpBuilder(tester);
    expect(find.text('Build a meal'), findsOneWidget);
    expect(
      find.text(
        'Choose one or more foods you feel like eating. We’ll find recipes '
        'that bring your ingredients together.',
      ),
      findsOneWidget,
    );
    expect(find.text('Proteins'), findsOneWidget);
    expect(find.text('Bases'), findsOneWidget);
    expect(find.text('Plants'), findsOneWidget);
    // The old balanced-meal language and requirements are gone.
    expect(find.textContaining('balanced'), findsNothing);
    expect(find.textContaining('Still to choose'), findsNothing);
    expect(find.textContaining('2–3'), findsNothing);
    expect(find.text('Nothing chosen yet.'), findsOneWidget);
  });

  testWidgets('one food enables Create my meal; no category is required', (
    tester,
  ) async {
    await pumpBuilder(tester);
    expect(createEnabled(tester), isFalse);
    await tester.tap(chipIn(MealSlot.plant, 'Carrot'));
    await tester.pumpAndSettle();
    expect(createEnabled(tester), isTrue);
    expect(find.text('1 of 8 foods'), findsOneWidget);
    // Un-choosing the only food turns it off again.
    await tester.tap(chosen('Carrot'));
    await tester.pumpAndSettle();
    expect(createEnabled(tester), isFalse);
  });

  testWidgets('several foods from one category, and across categories', (
    tester,
  ) async {
    await pumpBuilder(tester);
    for (final n in ['Carrot', 'Lettuce', 'Arugula', 'Avocado']) {
      await tester.tap(chipIn(MealSlot.plant, n));
      await tester.pumpAndSettle();
    }
    await tester.tap(chipIn(MealSlot.protein, 'Chicken'));
    await tester.pumpAndSettle();
    expect(find.text('5 of 8 foods'), findsOneWidget);
    expect(container(tester).read(mealSelectionProvider).ids, hasLength(5));
  });

  testWidgets('at most eight foods; the rest wait until one is removed', (
    tester,
  ) async {
    await pumpBuilder(tester);
    final ids = [
      'Carrot', 'Lettuce', 'Arugula', 'Avocado', 'Cabbage', 'Bok choy',
      'Green pea', 'Napa cabbage', //
    ];
    for (final n in ids) {
      await tester.tap(chipIn(MealSlot.plant, n));
      await tester.pumpAndSettle();
    }
    expect(
      find.textContaining('the most foods one search can use'),
      findsOneWidget,
    );
    await tester.tap(chipIn(MealSlot.plant, 'Nectarine'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen('Nectarine'), findsNothing);
    expect(container(tester).read(mealSelectionProvider).ids, hasLength(8));
    await tester.tap(chosen('Carrot'));
    await tester.pumpAndSettle();
    await tester.tap(chipIn(MealSlot.plant, 'Nectarine'));
    await tester.pumpAndSettle();
    expect(chosen('Nectarine'), findsOneWidget);
  });

  testWidgets('each section starts with the current phase only', (
    tester,
  ) async {
    await pumpBuilder(tester); // follicular
    final featured = testCatalogue.phase(Phase.follicular).foodIds.toSet();
    for (final s in MealSlot.values) {
      final chips = tester.widgetList<FoodChip>(
        find.descendant(of: section(s), matching: find.byType(FoodChip)),
      );
      for (final c in chips) {
        expect(
          featured.contains(c.food.id),
          isTrue,
          reason: '${s.name}: ${c.food.displayName}',
        );
        expect(c.featured, isTrue);
      }
    }
    // A food of another phase is not shown by default...
    expect(chip('Cucumber'), findsNothing); // Ovulatory
    expect(find.text('From other phases'), findsNothing);
    // ...but each section offers the rest.
    expect(find.text('Show all foods'), findsNWidgets(3));
  });

  testWidgets('the real phase is used, not a browsed one', (tester) async {
    await pumpBuilder(tester, day: 22); // luteal is the real phase
    final c = container(tester);
    c.read(viewingPhaseProvider.notifier).choose(Phase.menstrual);
    await tester.pumpAndSettle();
    final luteal = testCatalogue.phase(Phase.luteal).foodIds.toSet();
    final chips = tester.widgetList<FoodChip>(
      find.descendant(
        of: section(MealSlot.plant),
        matching: find.byType(FoodChip),
      ),
    );
    expect(chips, isNotEmpty);
    expect(chips.every((x) => luteal.contains(x.food.id)), isTrue);
  });

  testWidgets('Show all foods adds other phases as their own group, and '
      'collapses again without losing choices', (tester) async {
    await pumpBuilder(tester);
    final plants = section(MealSlot.plant);
    final link = find.descendant(
      of: plants,
      matching: find.text('Show all foods'),
    );
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: plants, matching: find.text('From other phases')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: plants, matching: find.text('Show fewer foods')),
      findsOneWidget,
    );
    // Cucumber (Ovulatory) is now there, plain; the phase foods stay tinted.
    final cucumber = tester.widget<FoodChip>(
      chipIn(MealSlot.plant, 'Cucumber'),
    );
    expect(cucumber.featured, isFalse);
    expect(
      tester.widget<FoodChip>(chipIn(MealSlot.plant, 'Carrot')).featured,
      isTrue,
    );
    // Any phase can be chosen.
    await tester.ensureVisible(chipIn(MealSlot.plant, 'Cucumber'));
    await tester.tap(chipIn(MealSlot.plant, 'Cucumber'));
    await tester.pumpAndSettle();
    expect(chosen('Cucumber'), findsOneWidget);

    // Collapse: the group goes, the choice stays (shown above the list).
    final fewer = find.descendant(
      of: plants,
      matching: find.text('Show fewer foods'),
    );
    await tester.ensureVisible(fewer);
    await tester.tap(fewer);
    await tester.pumpAndSettle();
    expect(find.text('From other phases'), findsNothing);
    expect(chosen('Cucumber'), findsOneWidget);
    expect(
      container(tester).read(mealSelectionProvider).contains('cucumber'),
      isTrue,
    );
    expect(find.text('Show all foods'), findsNWidgets(3));
  });

  testWidgets('search covers every eligible food, not only the phase', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await tester.enterText(find.byType(EditableText), 'cucumber');
    await tester.pumpAndSettle();
    expect(chip('Cucumber'), findsOneWidget);
    expect(find.text('Other phases'), findsWidgets);
    await tester.tap(chip('Cucumber'));
    await tester.pumpAndSettle();
    expect(chosen('Cucumber'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches here.'), findsNWidgets(3));
    // The chosen food is still shown and removable while searching.
    expect(chosen('Cucumber'), findsOneWidget);
  });

  testWidgets('a phase with no featured base says so, and Show all foods '
      'reaches every base', (tester) async {
    await pumpBuilder(tester, day: 14); // ovulatory
    expect(
      find.textContaining('No bases are featured in your ovulatory'),
      findsOneWidget,
    );
    final link = find.descendant(
      of: section(MealSlot.base),
      matching: find.text('Show all foods'),
    );
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(chipIn(MealSlot.base, 'Brown rice'), findsOneWidget);
  });

  testWidgets('chips are the Foods page chips, wrapped with its spacing', (
    tester,
  ) async {
    await pumpBuilder(tester);
    final wrap = tester.widget<Wrap>(
      find
          .descendant(of: section(MealSlot.plant), matching: find.byType(Wrap))
          .first,
    );
    expect(wrap.spacing, wrap.runSpacing); // even gaps both ways
    expect(wrap.spacing, greaterThan(0));
    expect(chip('Carrot'), findsOneWidget);
    expect(find.byType(FoodChip), findsWidgets);
  });

  testWidgets('a starting food from its page is already chosen', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBuilder(tester, foodId: 'broccoli');
    await tester.pumpAndSettle();
    expect(find.text('1 of 8 foods'), findsOneWidget);
    expect(chosen('Broccoli'), findsWidgets);
    expect(createEnabled(tester), isTrue);
    handle.dispose();
  });

  testWidgets('chosen foods can be un-chosen and replaced freely', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await tester.tap(chipIn(MealSlot.protein, 'Eggs'));
    await tester.pumpAndSettle();
    await tester.tap(chipIn(MealSlot.protein, 'Chicken'));
    await tester.pumpAndSettle();
    expect(chosen('Eggs'), findsOneWidget);
    expect(chosen('Chicken'), findsOneWidget);
    await tester.tap(chosen('Eggs'));
    await tester.pumpAndSettle();
    expect(chosen('Eggs'), findsNothing);
    await tester.tap(find.text('Clear my choices'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing chosen yet.'), findsOneWidget);
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

/// Whether the Create my meal button is live (not the dimmed ghost).
bool createEnabled(WidgetTester tester) {
  final button = find.widgetWithText(MoonButton, 'Create my meal');
  return tester.widget<MoonButton>(button).onPressed != null;
}
