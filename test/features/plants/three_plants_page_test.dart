import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/discovery/presentation/meal_results_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';
import 'package:moon_cycle/features/plants/application/plant_providers.dart';
import 'package:moon_cycle/features/plants/presentation/three_plants_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';
import '../../helpers/test_catalogue.dart';

void main() {
  late DevMockGenerationService mock;

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 3200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    mock = DevMockGenerationService(
      catalogue: testCatalogue,
      delay: Duration.zero,
    );
    // Free tier (no Premium override). A generator exists but must stay unused.
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        debugUnlockAtStartProvider.overrideWithValue(true),
        debugPremiumPreviewProvider.overrideWith(_Off.new),
        recipeGenerationServiceProvider.overrideWithValue(mock),
      ],
    );
    c.read(appRouterProvider).go(Routes.threePlants);
    await tester.pumpAndSettle();
    return c;
  }

  Finder card(String id) => find.byKey(ValueKey('plant-$id'));

  Finder findMeal() => find.byKey(const ValueKey('find-meal'));

  String ctaLabel(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(of: findMeal(), matching: find.byType(Text)),
      )
      .data!;

  testWidgets('the page: title, subtitle, phase, three plants, instruction', (
    tester,
  ) async {
    final c = await pump(tester);
    expect(find.byType(ThreePlantsPage), findsOneWidget);
    expect(find.text('3 Plants a Day'), findsOneWidget);
    expect(find.text('A little more variety, every day.'), findsOneWidget);
    expect(find.byKey(const ValueKey('phase-info')), findsOneWidget);
    expect(find.text('YOUR FOLLICULAR PHASE'), findsOneWidget);
    final plants = c.read(threePlantsProvider);
    expect(plants, hasLength(3));
    for (final p in plants) {
      expect(card(p.id), findsOneWidget);
      expect(find.text(p.displayName), findsOneWidget);
    }
    expect(find.text('TODAY’S THREE PLANTS'), findsOneWidget);
    expect(
      find.text('Tap the plants you’d like to cook with.'),
      findsOneWidget,
    );
    expect(find.text('Find a meal with all 3'), findsOneWidget);
  });

  testWidgets('plant cards toggle and the button label updates', (
    tester,
  ) async {
    final c = await pump(tester);
    final plants = c.read(threePlantsProvider);
    expect(c.read(plantPicksProvider), isEmpty);
    // Nothing picked means all three, and the button is always available.
    expect(ctaLabel(tester), 'Find a meal with all 3');
    for (final (n, label) in [
      (1, 'Find a meal with 1 plant'),
      (2, 'Find a meal with 2 plants'),
      (3, 'Find a meal with all 3'),
    ]) {
      await tester.tap(card(plants[n - 1].id));
      await tester.pumpAndSettle();
      expect(c.read(plantPicksProvider), hasLength(n));
      expect(ctaLabel(tester), label);
      expect(
        find.bySemanticsLabel(
          '${plants[n - 1].displayName}, ${testCatalogue.categoryFor(plants[n - 1]).name.toLowerCase()}, selected',
        ),
        findsOneWidget,
      );
    }
    // Tapping a chosen card again un-picks it.
    await tester.tap(card(plants[0].id));
    await tester.pumpAndSettle();
    expect(c.read(plantPicksProvider), hasLength(2));
    expect(ctaLabel(tester), 'Find a meal with 2 plants');
    for (final p in plants.skip(1)) {
      await tester.tap(card(p.id));
      await tester.pumpAndSettle();
    }
    expect(c.read(plantPicksProvider), isEmpty);
    expect(ctaLabel(tester), 'Find a meal with all 3');
  });

  testWidgets('the same page every time it is opened on a day', (tester) async {
    final c = await pump(tester);
    final first = [for (final p in c.read(threePlantsProvider)) p.id];
    c.read(appRouterProvider).go(Routes.home);
    await tester.pumpAndSettle();
    c.read(appRouterProvider).go(Routes.threePlants);
    await tester.pumpAndSettle();
    expect([for (final p in c.read(threePlantsProvider)) p.id], first);
  });

  for (final picked in [1, 2, 3]) {
    testWidgets('$picked plant(s): Find a meal shows ranked recipes with '
        'the same search as Build a meal, free, with no generation', (
      tester,
    ) async {
      final c = await pump(tester);
      final plants = c.read(threePlantsProvider);
      for (final p in plants.take(picked)) {
        await tester.tap(card(p.id));
        await tester.pumpAndSettle();
      }
      await tester.tap(findMeal());
      await tester.pumpAndSettle();
      expect(find.byType(MealResultsPage), findsOneWidget);
      // Free: the results are not locked behind Premium.
      expect(find.textContaining('Premium'), findsNothing);
      // The chosen plants are what was searched, in the order shown.
      final names = [for (final p in plants.take(picked)) p.displayName]
          .join(' · ');
      expect(find.text(names), findsOneWidget);
      expect(find.text('3 Plants a Day'), findsOneWidget); // back label
      // Either recipes (with honest counts) or the plain empty state.
      final hasResults = find.byKey(const ValueKey('result-count'));
      if (hasResults.evaluate().isNotEmpty) {
        final uses = find.textContaining('Uses ');
        expect(uses, findsWidgets);
      } else {
        expect(find.byKey(const ValueKey('no-results')), findsOneWidget);
      }
      expect(mock.calls, 0);
      expect(find.textContaining('Create a new recipe'), findsNothing);
    });
  }

  testWidgets('Build a meal results stay Premium for a free user', (
    tester,
  ) async {
    final c = await pump(tester);
    c.read(appRouterProvider).go(Routes.mealResults(['kale']));
    await tester.pumpAndSettle();
    expect(
      find.text('Build a Meal is part of Moon Cycle Premium.'),
      findsOneWidget,
    );
  });
}

class _Off extends DebugPremiumPreview {
  @override
  bool build() => false;
}
