import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/foods/presentation/ingredient_sheet.dart';
import 'package:moon_cycle/features/home/application/home_discovery.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_sections.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_catalogue.dart';

void main() {
  Future<ProviderContainer> pumpHome(WidgetTester tester) async {
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
    expect(find.byType(HomePage), findsOneWidget);
    return container;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

  testWidgets('hierarchy: hero, focus, today’s food, then the two actions', (
    tester,
  ) async {
    await pumpHome(tester);
    // A tall viewport, so every section is built and measurable.
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    final hero = find.text('Follicular');
    // Scrolled: the hero is above the viewport but still ordered first.
    final focus = find.text('YOUR FOCUS');
    final todays = find.text('TODAY’S FOOD');
    final build = find.text('Build a meal');
    final tryNew = find.text('Try something new');
    expect(hero, findsOneWidget);
    expect(top(tester, hero), lessThan(top(tester, focus)));
    expect(top(tester, focus), lessThan(top(tester, todays)));
    expect(top(tester, todays), lessThan(top(tester, build)));
    // Stacked, Build a meal first.
    expect(top(tester, build), lessThan(top(tester, tryNew)));
    // The phase description, not food guidance, sits under the name.
    expect(find.text('Learn more →'), findsOneWidget);
  });

  testWidgets('the old Home sections are gone', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Try something new'));
    for (final gone in [
      'Foods for this phase',
      'Recipes for this phase',
      'All foods',
      'All recipes',
      'Your shopping list',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    // Nothing on Home duplicates a tab as a button.
    expect(find.text('Browse Foods'), findsNothing);
    expect(find.text('Browse Recipes'), findsNothing);
  });

  testWidgets('previewing a phase moves Your focus, not Today’s food', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    await scrollTo(tester, find.text('Try something new'));
    final todays = container.read(todaysFoodProvider(Phase.follicular))!;
    expect(find.text('Fresh variety'), findsOneWidget);
    expect(find.text(todays.displayName), findsOneWidget);

    container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Try something new'));
    // The focus follows the viewing phase…
    expect(find.text('Protein + fibre'), findsOneWidget);
    expect(find.text('Fresh variety'), findsNothing);
    // …Today's food stays tied to the real phase and date.
    expect(find.text(todays.displayName), findsOneWidget);
    expect(
      find.bySemanticsLabel('Today’s food: ${todays.displayName}'),
      findsOneWidget,
    );
    expect(testCatalogue.phase(Phase.follicular).foodIds, contains(todays.id));
    expect(container.read(actualPhaseProvider), Phase.follicular);

    // Back to today: the phase view returns, the food never changed.
    container.read(viewingPhaseProvider.notifier).showActual();
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Try something new'));
    expect(find.text('Fresh variety'), findsOneWidget);
    expect(find.text(todays.displayName), findsOneWidget);
  });

  testWidgets(
    'Why this food? and Recipes use the real phase while previewing',
    (tester) async {
      final container = await pumpHome(tester);
      final todays = container.read(todaysFoodProvider(Phase.follicular))!;
      container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Why this food?'));
      await tester.tap(find.text('Why this food?'));
      await tester.pumpAndSettle();
      expect(
        find.text('Recommended for your follicular phase'),
        findsOneWidget,
      );
      expect(find.text(todays.why[Phase.follicular]!.short), findsOneWidget);
      Navigator.of(tester.element(find.byType(IngredientSheet))).pop();
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(TodaysFoodSection),
          matching: find.text('Recipes'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RecipesPage), findsOneWidget);
      expect(container.read(viewingPhaseProvider), Phase.follicular);
      expect(container.read(recipeFilterProvider).foodId, todays.id);
    },
  );

  testWidgets('when the real phase changes, the daily pool changes with it', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    final follicular = container.read(todaysFoodProvider(Phase.follicular))!;
    final luteal = container.read(todaysFoodProvider(Phase.luteal))!;
    expect(
      testCatalogue.phase(Phase.follicular).foodIds,
      contains(follicular.id),
    );
    expect(testCatalogue.phase(Phase.luteal).foodIds, contains(luteal.id));
    expect(follicular.id, isNot(luteal.id));
  });

  testWidgets('Today’s food is the same after a rebuild', (tester) async {
    final container = await pumpHome(tester);
    final first = container.read(todaysFoodProvider(Phase.follicular))!.id;
    await tester.tap(find.byKey(const ValueKey('tab-foods')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    expect(container.read(todaysFoodProvider(Phase.follicular))!.id, first);
  });

  testWidgets('Why this food? opens the sheet with the phase’s reason', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    await scrollTo(tester, find.text('Why this food?'));
    final food = container.read(todaysFoodProvider(Phase.follicular))!;
    await tester.tap(find.text('Why this food?'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
    expect(find.text('Recommended for your follicular phase'), findsOneWidget);
    expect(find.text(food.why[Phase.follicular]!.short), findsOneWidget);
  });

  testWidgets('Recipes goes to the recipes with that food', (tester) async {
    final container = await pumpHome(tester);
    await scrollTo(
      tester,
      find.descendant(
        of: find.byType(TodaysFoodSection),
        matching: find.text('Recipes'),
      ),
    );
    final food = container.read(todaysFoodProvider(Phase.follicular))!;
    await tester.tap(
      find.descendant(
        of: find.byType(TodaysFoodSection),
        matching: find.text('Recipes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(container.read(recipeFilterProvider).foodId, food.id);
    expect(container.read(viewingPhaseProvider), Phase.follicular);
    expect(
      find.textContaining('with ${food.displayName.toLowerCase()}'),
      findsOneWidget,
    );
  });

  testWidgets('Build a meal opens the meal-builder guidance', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Build a meal'));
    await tester.tap(find.text('Build a meal'));
    await tester.pumpAndSettle();
    expect(find.text('Build a balanced meal'), findsOneWidget);
    expect(find.text('Choose a protein'), findsOneWidget);
    expect(find.text('Choose a base'), findsOneWidget);
    expect(find.text('Add 2–3 plants'), findsOneWidget);
  });

  testWidgets('Try something new: three phase foods, then 3 more', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    await scrollTo(tester, find.text('Try something new'));
    final todays = container.read(todaysFoodProvider(Phase.follicular))!;
    final pages = container.read(tryNewPagesProvider(Phase.follicular));
    await tester.tap(find.text('Try something new'));
    await tester.pumpAndSettle();
    expect(find.text('Three foods from this phase.'), findsOneWidget);
    // Only look inside the sheet: Home's own Today's food sits behind it.
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );
    final featured = testCatalogue.phase(Phase.follicular).foodIds.toSet();
    for (final f in pages[0]) {
      expect(featured, contains(f.id));
      expect(f.id, isNot(todays.id));
      expect(inSheet(f.displayName), findsOneWidget);
    }
    expect(inSheet(todays.displayName), findsNothing);

    await tester.tap(find.text('Show me 3 more'));
    await tester.pumpAndSettle();
    for (final f in pages[1]) {
      expect(inSheet(f.displayName), findsOneWidget);
    }
    for (final f in pages[0]) {
      expect(inSheet(f.displayName), findsNothing);
    }

    // A discovery food opens its sheet with the phase reason.
    await tester.tap(inSheet(pages[1].first.displayName));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
  });

  testWidgets('browsing leaves the real cycle alone; Back to today works', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    final before = container.read(cycleStateProvider).value!;
    container.read(homePreviewProvider.notifier).preview(22);
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(find.text('Back to today · Day 7'), findsOneWidget);
    final after = container.read(cycleStateProvider).value!;
    expect(after.lastPeriodStart, before.lastPeriodStart);
    expect(after.phase, before.phase);
    expect(after.cycleDay, before.cycleDay);

    await tester.tap(find.text('Back to today · Day 7'));
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.follicular);
    await scrollTo(tester, find.text('Try something new'));
    expect(find.text('Fresh variety'), findsOneWidget);
  });

  group('small phone, large text', () {
    for (final phase in [Phase.menstrual, Phase.luteal]) {
      testWidgets('${phase.name}: 320 pt at 1.5× has no overflow', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final day = switch (phase) {
          Phase.menstrual => 2,
          _ => 21,
        };
        await pumpScreen(
          tester,
          const HomePage(),
          dark: false,
          width: 320,
          textScale: 1.5,
          height: 4200,
          overrides: [cycleStateProvider.overrideWithValue(stateOnDay(day))],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Build a meal'), findsOneWidget);
        expect(find.text('Try something new'), findsOneWidget);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}
