import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/browse_scope.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/foods/application/browse_scope.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/recipes/application/recipe_list.dart';
import 'package:moon_cycle/features/recipes/application/recipes_scope.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// One shared viewing phase: Home's moon, Foods and Recipes read and write
/// the same state, and browsing never touches the real (calculated) phase.
void main() {
  Future<void> goTo(WidgetTester tester, String tab) async {
    await tester.tap(find.byKey(ValueKey('tab-$tab')));
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpAt(WidgetTester tester, String tab) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await goTo(tester, tab);
    return container;
  }

  Future<void> pickPhase(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('starts as the actual phase', (tester) async {
    final container = await pumpAt(tester, 'home');
    expect(container.read(actualPhaseProvider), Phase.follicular);
    expect(container.read(viewingPhaseProvider), Phase.follicular);
    expect(find.text('Back to today · Day 7'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Try something new'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('YOUR FOCUS'), findsOneWidget);
    expect(find.text('TODAY’S FOOD'), findsOneWidget);
    expect(find.text('Build a meal'), findsOneWidget);
  });

  testWidgets('moving the Home moon moves Foods and Recipes', (tester) async {
    final container = await pumpAt(tester, 'home');
    // The drag handler's effect: the moon is moved to a luteal day.
    container.read(homePreviewProvider.notifier).preview(22);
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(find.text('Luteal'), findsWidgets);
    expect(find.text('Back to today · Day 7'), findsOneWidget);

    await goTo(tester, 'foods');
    expect(find.text('Browsing luteal ·'), findsOneWidget);
    expect(find.text('Inner autumn'), findsOneWidget);

    await goTo(tester, 'recipes');
    expect(container.read(recipeListProvider).phase, Phase.luteal);
    expect(find.textContaining('luteal'), findsWidgets);
  });

  testWidgets('choosing a phase on Foods moves Home and Recipes', (
    tester,
  ) async {
    final container = await pumpAt(tester, 'foods');
    await pickPhase(tester, 'Ovulatory');
    expect(container.read(viewingPhaseProvider), Phase.ovulatory);

    await goTo(tester, 'home');
    expect(find.text('Back to today · Day 7'), findsOneWidget);
    expect(container.read(homeShownDayProvider), isNotNull);
    expect(
      container
          .read(cycleStateProvider)
          .value!
          .ranges
          .forDay(container.read(homeShownDayProvider)!)
          .phase,
      Phase.ovulatory,
    );

    await goTo(tester, 'recipes');
    expect(container.read(recipeListProvider).phase, Phase.ovulatory);
  });

  testWidgets('choosing a phase on Recipes moves Foods and Home', (
    tester,
  ) async {
    final container = await pumpAt(tester, 'recipes');
    await pickPhase(tester, 'Menstrual');
    expect(container.read(viewingPhaseProvider), Phase.menstrual);

    await goTo(tester, 'foods');
    expect(find.text('Browsing menstrual ·'), findsOneWidget);

    await goTo(tester, 'home');
    expect(find.text('Back to today · Day 7'), findsOneWidget);
  });

  testWidgets('browsing never changes the real phase or cycle dates', (
    tester,
  ) async {
    final container = await pumpAt(tester, 'foods');
    final before = container.read(cycleStateProvider).value!;
    await pickPhase(tester, 'Luteal');
    container.read(homePreviewProvider.notifier).preview(3);
    await tester.pumpAndSettle();

    final after = container.read(cycleStateProvider).value!;
    expect(after.phase, before.phase);
    expect(after.cycleDay, before.cycleDay);
    expect(after.lastPeriodStart, before.lastPeriodStart);
    expect(container.read(actualPhaseProvider), Phase.follicular);
    expect(container.read(viewingPhaseProvider), Phase.menstrual);
  });

  testWidgets('Back to today on Home returns every screen', (tester) async {
    final container = await pumpAt(tester, 'foods');
    await pickPhase(tester, 'Luteal');
    await goTo(tester, 'home');
    await tester.tap(find.text('Back to today · Day 7'));
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.follicular);
    expect(container.read(homeShownDayProvider), isNull);

    await goTo(tester, 'foods');
    expect(find.text('Your current phase · day 7'), findsOneWidget);
  });

  testWidgets('Back to today on Foods returns Home', (tester) async {
    final container = await pumpAt(tester, 'foods');
    await pickPhase(tester, 'Luteal');
    await tester.tap(find.text('Back to follicular'));
    await tester.pumpAndSettle();
    await goTo(tester, 'home');
    expect(find.text('Back to today · Day 7'), findsNothing);
    expect(container.read(viewingPhaseProvider), Phase.follicular);
  });

  testWidgets('This phase | All foods and All recipes keep the phase', (
    tester,
  ) async {
    final container = await pumpAt(tester, 'foods');
    await pickPhase(tester, 'Luteal');
    await tester.tap(find.text('All foods'));
    await tester.pumpAndSettle();
    expect(container.read(foodsScopeProvider), BrowseScope.all);
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(find.text('Search foods'), findsOneWidget);

    await goTo(tester, 'recipes');
    await tester.tap(find.text('All recipes'));
    await tester.pumpAndSettle();
    expect(container.read(recipesScopeProvider), BrowseScope.all);
    final all = container.read(recipeListProvider).recipes.length;
    await tester.tap(find.text('This phase'));
    await tester.pumpAndSettle();
    expect(container.read(recipeListProvider).recipes.length, lessThan(all));
    expect(container.read(viewingPhaseProvider), Phase.luteal);
  });
}
