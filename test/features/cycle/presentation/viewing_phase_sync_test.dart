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
  /// 'home', or Eat's 'foods' / 'recipes' half.
  Future<void> goTo(WidgetTester tester, String tab) async {
    final eat = tab == 'foods' || tab == 'recipes';
    await tester.tap(find.byKey(ValueKey('tab-${eat ? 'eat' : tab}')));
    await tester.pumpAndSettle();
    if (eat) {
      // A tab keeps its stack: come back to the Eat hub first.
      if (find.text('Nourish your cycle').evaluate().isEmpty) {
        await tester.tap(find.byKey(const ValueKey('tab-eat')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(tab == 'foods' ? 'Foods' : 'Recipes'));
      await tester.pumpAndSettle();
    }
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
    await tester.tap(find.byKey(const ValueKey('phase-pill')));
    await tester.pumpAndSettle();
    final target = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(label),
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('starts as the actual phase', (tester) async {
    final container = await pumpAt(tester, 'home');
    expect(container.read(actualPhaseProvider), Phase.follicular);
    expect(container.read(viewingPhaseProvider), Phase.follicular);
    expect(find.text('Back to today · Day 7'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('YOUR SPACE'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('YOUR SPACE'), findsOneWidget);
    expect(find.text('My Diary'), findsOneWidget);
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
    expect(container.read(viewingPhaseProvider), Phase.luteal);

    await goTo(tester, 'recipes');
    expect(container.read(recipeListProvider).phase, Phase.luteal);
    expect(find.text('Luteal'), findsWidgets);
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
    expect(container.read(viewingPhaseProvider), Phase.menstrual);

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
    expect(container.read(viewingPhaseProvider), Phase.follicular);
  });

  testWidgets('Choosing your phase again on Eat returns Home', (tester) async {
    final container = await pumpAt(tester, 'foods');
    await pickPhase(tester, 'Luteal');
    await pickPhase(tester, 'Follicular');
    await goTo(tester, 'home');
    expect(find.text('Back to today · Day 7'), findsNothing);
    expect(container.read(viewingPhaseProvider), Phase.follicular);
  });

  testWidgets('Browse by phase: All phases keeps the phase for the way back', (
    tester,
  ) async {
    final container = await pumpAt(tester, 'foods');
    await pickPhase(tester, 'Luteal');
    await pickPhase(tester, 'All phases');
    expect(container.read(foodsScopeProvider), BrowseScope.all);
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(find.text('Search foods'), findsOneWidget);

    await goTo(tester, 'recipes');
    expect(container.read(recipesScopeProvider), BrowseScope.all);
    final all = container.read(recipeListProvider).recipes.length;
    await pickPhase(tester, 'Luteal');
    expect(container.read(recipeListProvider).recipes.length, lessThan(all));
    expect(container.read(viewingPhaseProvider), Phase.luteal);
  });
}
