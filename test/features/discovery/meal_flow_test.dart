import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/discovery/presentation/meal_results_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/balanced_selection.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';
import '../../helpers/test_catalogue.dart';

void main() {
  late DevMockGenerationService mock;

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 5200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    // A generation service IS available in this build; Build a Meal must not
    // use it.
    mock = DevMockGenerationService(
      catalogue: testCatalogue,
      delay: Duration.zero,
    );
    return pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        entitlementStateProvider.overrideWithValue(
          const EntitlementState(tier: Tier.premium),
        ),
        debugUnlockAtStartProvider.overrideWithValue(true),
        recipeGenerationServiceProvider.overrideWithValue(mock),
        recipeImageServiceProvider.overrideWithValue(
          PlaceholderRecipeImageService(delay: Duration.zero),
        ),
      ],
    );
  }

  Future<void> go(
    WidgetTester tester,
    ProviderContainer c,
    String location,
  ) async {
    c.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('all chosen foods in a library recipe: it leads, described '
      'honestly', (tester) async {
    final c = await pump(tester);
    await go(tester, c, Routes.mealResults(['quinoa', 'orange']));
    expect(find.byType(MealResultsPage), findsOneWidget);
    expect(find.text('USES ALL YOUR FOODS'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('uses-black-bean-quinoa-orange-bowl')),
      findsOneWidget,
    );
    expect(find.text('Uses all 2 of your foods'), findsWidgets);
    expect(find.text('Includes quinoa, orange'), findsWidgets);
    expect(find.text('Moon Cycle recipe'), findsNothing); // joined with time
    expect(find.textContaining('Moon Cycle recipe'), findsWidgets);
    // Partial matches (one of two) come after, and say so.
    expect(find.text('USES SOME OF YOUR FOODS'), findsOneWidget);
    expect(find.text('Uses 1 of your 2 foods'), findsWidgets);
    // It opens in the normal recipe page.
    await tester.tap(find.text('Black Bean, Quinoa & Orange Bowl').first);
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    expect(mock.calls, 0);
  });

  testWidgets('a partial match is never described as having every food', (
    tester,
  ) async {
    final c = await pump(tester);
    await go(tester, c, Routes.mealResults(['quinoa', 'orange', 'salmon']));
    // Nothing in the library uses all three.
    expect(find.text('USES ALL YOUR FOODS'), findsNothing);
    expect(find.text('Uses all 3 of your foods'), findsNothing);
    expect(find.text('USES MOST OF YOUR FOODS'), findsOneWidget);
    expect(find.text('Uses 2 of your 3 foods'), findsWidgets);
    expect(find.text('Includes quinoa, orange'), findsWidgets);
  });

  testWidgets('no recipe: a clear empty state, and nothing is generated', (
    tester,
  ) async {
    final c = await pump(tester);
    await go(tester, c, Routes.mealResults(['kombu', 'wakame']));
    expect(find.byKey(const ValueKey('no-results')), findsOneWidget);
    expect(find.text('No recipes use these foods yet.'), findsOneWidget);
    expect(find.text('Change my foods'), findsOneWidget);
    expect(find.textContaining('Create a new recipe'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(mock.calls, 0);
  });

  testWidgets('a useful first set, then See more', (tester) async {
    final c = await pump(tester);
    await go(tester, c, Routes.mealResults(['garlic']));
    final total = int.parse(
      RegExp(r'\d+')
          .firstMatch(
            tester
                .widget<Text>(find.byKey(const ValueKey('result-count')))
                .data!,
          )!
          .group(0)!,
    );
    expect(total, greaterThan(8));
    int cards() => find
        .byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key! as ValueKey).value}'.startsWith('uses-'),
        )
        .evaluate()
        .length;
    expect(cards(), 8);
    await tester.ensureVisible(find.text('See more recipes'));
    await tester.tap(find.text('See more recipes'));
    await tester.pumpAndSettle();
    expect(cards(), 16.clamp(0, total));
  });

  testWidgets('Build a meal never starts generation, even when it could', (
    tester,
  ) async {
    final c = await pump(tester);
    expect(c.read(generationAvailableProvider), isTrue);
    await go(tester, c, Routes.mealResults(['kale']));
    await go(tester, c, Routes.mealResults(['kombu']));
    expect(mock.calls, 0);
  });

  group('recipes made earlier are kept', () {
    testWidgets('saved recipes stay in My recipes, labelled as before', (
      tester,
    ) async {
      final c = await pump(tester);
      await tester.runAsync(
        () => c
            .read(recipeCreationProvider.notifier)
            .start(
              const BalancedSelection(
                proteinId: 'tempeh',
                baseId: 'buckwheat',
                plantIds: ['kale', 'pomegranate'],
              ),
            ),
      );
      await tester.runAsync(
        () => c.read(recipeCreationProvider.notifier).imageSettled,
      );
      await tester.pumpAndSettle();
      final saved = await tester.runAsync(
        () => c.read(personalRecipeRepositoryProvider).all('dev-local-user'),
      );
      expect(saved!, hasLength(1));
      await go(tester, c, Routes.myRecipes);
      expect(find.byType(MyRecipesPage), findsOneWidget);
      expect(find.text('Tempeh & Buckwheat Bowl'), findsOneWidget);
      await go(tester, c, Routes.recipe(saved.single.id));
      expect(find.byType(RecipeDetailPage), findsOneWidget);
      expect(find.textContaining('Development sample'), findsOneWidget);
    });
  });
}
