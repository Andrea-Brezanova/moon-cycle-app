import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/eat/presentation/eat_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/plants/presentation/three_plants_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

const premium = EntitlementState(tier: Tier.premium);

/// The Android back button.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  Future<ProviderContainer> pumpEat(
    WidgetTester tester, {
    List<Override> more = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow), ...more],
    );
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
  }

  testWidgets('Eat opens the hub: heading, search, photo, intro, three cards', (
    tester,
  ) async {
    await pumpEat(tester);
    expect(find.byType(EatPage), findsOneWidget);
    expect(find.text('Eat'), findsWidgets);
    expect(find.byKey(const ValueKey('eat-search')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Nourish your cycle'), findsOneWidget);
    expect(
      find.text(
        'Seasonal foods, simple recipes and meal ideas to support your '
        'current phase.',
      ),
      findsOneWidget,
    );
    for (final t in [
      'Foods',
      'Browse foods by phase and benefit.',
      'Recipes',
      'Find nourishing recipes for every phase.',
      'Meal builder',
      'Create a balanced meal with foods or recipes.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // The old segmented Foods / Recipes view is gone from the hub.
    expect(find.byType(FoodsPage), findsNothing);
    expect(find.byType(RecipesPage), findsNothing);
  });

  testWidgets('Foods card opens Foods; Back returns to the hub', (
    tester,
  ) async {
    await pumpEat(tester);
    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);
    expect(find.byKey(const ValueKey('phase-pill')), findsOneWidget);
    await back(tester);
    expect(find.byType(EatPage), findsOneWidget);
    expect(find.byType(FoodsPage), findsNothing);
  });

  testWidgets('a food opens its detail page; Back keeps the Foods page', (
    tester,
  ) async {
    await pumpEat(tester);
    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Farro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Farro'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);
    await back(tester);
    expect(find.byType(EatPage), findsOneWidget);
  });

  testWidgets('Recipes card opens Recipes; a recipe and My recipes open', (
    tester,
  ) async {
    final container = await pumpEat(tester);
    await tester.ensureVisible(find.text('Recipes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);

    // My recipes is reached from the Recipes page (its link shows once there
    // are saved recipes), so open it the way that link does.
    unawaited(container.read(appRouterProvider).push(Routes.myRecipes));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);

    final recipe = find.text('Zucchini & Feta Herb Frittata');
    await tester.ensureVisible(recipe);
    await tester.pumpAndSettle();
    await tester.tap(recipe);
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    await systemBack(tester);
    expect(find.byType(RecipesPage), findsOneWidget);
    await back(tester);
    expect(find.byType(EatPage), findsOneWidget);
  });

  testWidgets('the search icon opens the foods search', (tester) async {
    await pumpEat(tester);
    await tester.tap(find.byKey(const ValueKey('eat-search')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);
    expect(find.text('Search foods'), findsOneWidget);
    await back(tester);
    expect(find.byType(EatPage), findsOneWidget);
  });

  group('Meal builder card', () {
    testWidgets('a free user (normal release setup) opens the builder: no '
        'lock, no Premium prompt', (tester) async {
      await pumpEat(tester);
      await tester.ensureVisible(find.text('Meal builder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meal builder'));
      await tester.pumpAndSettle();
      expect(find.byType(MealBuilderPage), findsOneWidget);
      expect(find.text('Proteins'), findsOneWidget);
      expect(find.text('See Premium'), findsNothing);
      expect(find.textContaining('Premium'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(EatPage), findsOneWidget);
    });

    testWidgets('a Premium user gets the same builder', (tester) async {
      await pumpEat(
        tester,
        more: [entitlementStateProvider.overrideWithValue(premium)],
      );
      await tester.ensureVisible(find.text('Meal builder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meal builder'));
      await tester.pumpAndSettle();
      expect(find.byType(MealBuilderPage), findsOneWidget);
      expect(find.text('Proteins'), findsOneWidget);
    });
  });

  testWidgets('Home’s 3 plants shortcut still opens 3 Plants a Day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    expect(find.byType(HomePage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3 plants'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('3 plants'));
    await tester.pumpAndSettle();
    expect(find.byType(ThreePlantsPage), findsOneWidget);
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [
        (390.0, 1.0),
        (320.0, 1.0),
        (320.0, 1.5),
        (390.0, 2.0),
      ]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: no overflow, '
          'targets and labels are fine',
          (tester) async {
            final handle = tester.ensureSemantics();
            await pumpScreen(
              tester,
              const EatPage(),
              dark: dark,
              width: width,
              textScale: scale,
              height: 2400,
              overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Meal builder'), findsOneWidget);
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            handle.dispose();
          },
        );
      }
    }
  });
}
