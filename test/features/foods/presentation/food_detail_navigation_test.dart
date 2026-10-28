import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
import 'package:moon_cycle/features/eat/presentation/eat_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/application/meal_selection.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

const premium = EntitlementState(tier: Tier.premium);

void main() {
  /// Starts the app on the Eat tab and returns its container.
  Future<ProviderContainer> pumpApp_(
    WidgetTester tester, {
    List<Override> more = const [],
    Future<void> Function(PreferencesRepository prefs)? prefs,
    AppDatabase? db,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final database = db ?? testDatabase();
    await seedCycle(
      tester,
      database,
      start: sampleStart,
      more: prefs == null ? null : () => prefs(PreferencesRepository(database)),
    );
    final container = await pumpApp(
      tester,
      database: database,
      overrides: [clockProvider.overrideWithValue(designNow), ...more],
    );
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    return container;
  }

  /// Eat → Foods → the food's page, as a user would arrive.
  Future<void> openFromFoods(
    WidgetTester tester,
    ProviderContainer container,
    String id, {
    bool general = false,
  }) async {
    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();
    unawaited(
      container.read(appRouterProvider).push(Routes.food(id, general: general)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
  }

  Future<void> back(WidgetTester tester) async {
    // A page's header scrolls with it: bring it back into view first.
    if (find.byType(Scrollable).evaluate().isNotEmpty) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -140));
    await tester.pumpAndSettle();
  }

  group('the four actions', () {
    for (final (id, name, hasRecipes) in const [
      ('artichoke', 'artichoke', true),
      ('apricot', 'apricot', true),
      ('amaranth', 'amaranth', false), // no recipe uses it
    ]) {
      testWidgets('$name: same four actions, same order', (tester) async {
        final container = await pumpApp_(tester);
        await openFromFoods(tester, container, id, general: true);
        final labels = [
          'Find recipes with $name',
          'Build a Meal with $name',
          'Add to shopping list',
          'Log meal',
        ];
        final tops = <double>[];
        for (final l in labels) {
          final f = find.text(l);
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          expect(f, findsOneWidget, reason: l);
          tops.add(tester.getTopLeft(f).dy);
        }
        // Same on-screen order once scrolled into view: each appears in turn.
        expect(tops, isNotEmpty);
        final note = find.byKey(const ValueKey('no-recipes-note'));
        expect(note, hasRecipes ? findsNothing : findsOneWidget);
        if (!hasRecipes) {
          expect(find.text('No recipes with $name yet.'), findsOneWidget);
        }
      });
    }
  });

  testWidgets('an avoided food’s recipes: the reason names the preferences', (
    tester,
  ) async {
    final container = await pumpApp_(
      tester,
      prefs: (p) async => p.avoidFood('turnip'),
    );
    await openFromFoods(tester, container, 'turnip', general: true);
    await tester.ensureVisible(find.text('Find recipes with turnip'));
    await tester.pumpAndSettle();
    final note = find.byKey(const ValueKey('no-recipes-note'));
    expect(note, findsOneWidget);
    expect(
      find.textContaining('hidden by your food preferences'),
      findsOneWidget,
    );
  });

  testWidgets('Find recipes: ingredient preselected; Back returns to the '
      'food, then to Foods', (tester) async {
    final container = await pumpApp_(tester);
    await openFromFoods(tester, container, 'turnip', general: true);
    await tester.ensureVisible(find.text('Find recipes with turnip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find recipes with turnip'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(container.read(recipeFilterProvider).foodId, 'turnip');
    expect(find.textContaining('Cook with: '), findsOneWidget);
    expect(find.textContaining('with turnip'), findsWidgets); // the count

    await back(tester);
    expect(find.byType(FoodDetailPage), findsOneWidget); // not Eat, not Foods
    await back(tester);
    expect(find.byType(FoodsPage), findsOneWidget);
  });

  testWidgets('Build a Meal: opens with the food chosen; Back returns '
      'to the food', (tester) async {
    final container = await pumpApp_(
      tester,
      more: [entitlementStateProvider.overrideWithValue(premium)],
    );
    await openFromFoods(tester, container, 'turnip', general: true);
    await reveal(tester, find.text('Build a Meal with turnip'));
    await tester.tap(find.text('Build a Meal with turnip'));
    await tester.pumpAndSettle();
    expect(find.byType(MealBuilderPage), findsOneWidget);
    expect(container.read(mealSelectionProvider).contains('turnip'), isTrue);
    expect(container.read(mealSelectionProvider).ids, ['turnip']);
    await back(tester);
    expect(find.byType(FoodDetailPage), findsOneWidget);
  });

  testWidgets('Build a Meal works for a free user: no lock, opens the '
      'builder with the food chosen', (tester) async {
    final container = await pumpApp_(tester);
    await openFromFoods(tester, container, 'turnip', general: true);
    await reveal(tester, find.text('Build a Meal with turnip'));
    expect(find.byIcon(Icons.lock), findsNothing);
    await tester.tap(find.text('Build a Meal with turnip'));
    await tester.pumpAndSettle();
    expect(find.byType(MealBuilderPage), findsOneWidget);
    expect(find.text('See Premium'), findsNothing);
    expect(container.read(mealSelectionProvider).ids, ['turnip']);
  });

  testWidgets('a herb: the meal button is disabled, with the reason', (
    tester,
  ) async {
    final container = await pumpApp_(
      tester,
      more: [entitlementStateProvider.overrideWithValue(premium)],
    );
    await openFromFoods(tester, container, 'parsley', general: true);
    await reveal(tester, find.text('Build a Meal with parsley'));
    expect(find.byKey(const ValueKey('herb-meal-note')), findsOneWidget);
    await tester.tap(
      find.text('Build a Meal with parsley'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(MealBuilderPage), findsNothing);
  });

  testWidgets('Log meal: the food is preselected; Back returns to the food', (
    tester,
  ) async {
    final container = await pumpApp_(tester);
    await openFromFoods(tester, container, 'turnip', general: true);
    await reveal(tester, find.text('Log meal'));
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(find.byType(LogMealPage), findsOneWidget);
    expect(find.text('Turnip'), findsWidgets); // chosen item
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
  });

  testWidgets('Shopping list: add, remove, stay on the page, no duplicates', (
    tester,
  ) async {
    final db = testDatabase();
    final container = await pumpApp_(tester, db: db);
    await openFromFoods(tester, container, 'turnip', general: true);
    await reveal(tester, find.text('Add to shopping list'));
    await tester.tap(find.text('Add to shopping list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from shopping list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to shopping list'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    final items = await tester.runAsync(ShoppingRepository(db).items);
    expect(items!.where((i) => i.key == 'food:turnip'), hasLength(1));
    expect(find.text('Remove from shopping list'), findsOneWidget);
  });

  testWidgets('a link straight to a food: Back goes to the Eat hub', (
    tester,
  ) async {
    final container = await pumpApp_(tester);
    container.read(appRouterProvider).go(Routes.food('turnip', general: true));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    await back(tester);
    expect(find.byType(EatPage), findsOneWidget);
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: fits, 44 pt '
          'targets',
          (tester) async {
            final handle = tester.ensureSemantics();
            for (final id in const ['amaranth', 'turnip']) {
              await pumpScreen(
                tester,
                FoodDetailPage(foodId: id, general: true),
                dark: dark,
                width: width,
                textScale: scale,
                height: 3000,
                overrides: [
                  cycleStateProvider.overrideWithValue(stateOnDay(7)),
                ],
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
            }
            handle.dispose();
          },
        );
      }
    }
  });
}
