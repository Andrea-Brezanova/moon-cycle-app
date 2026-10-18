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
import 'package:moon_cycle/features/generation/domain/generation_failure.dart';
import 'package:moon_cycle/features/generation/presentation/create_recipe_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';
import '../../helpers/test_catalogue.dart';

const _bowl = ('black-turtle-bean', 'quinoa', ['yellow-bell-pepper', 'orange']);
const _unusual = ('tempeh', 'buckwheat', ['kale', 'pomegranate']);

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool generation = true,
    List<GenerationFailure> failures = const [],
    int invalid = 0,
  }) async {
    tester.view.physicalSize = const Size(390, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    return pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        entitlementStateProvider.overrideWithValue(
          const EntitlementState(tier: Tier.premium),
        ),
        debugUnlockAtStartProvider.overrideWithValue(generation),
        if (generation) ...[
          recipeGenerationServiceProvider.overrideWithValue(
            DevMockGenerationService(
              catalogue: testCatalogue,
              delay: Duration.zero,
              failures: failures,
              invalidAttempts: invalid,
            ),
          ),
          recipeImageServiceProvider.overrideWithValue(
            PlaceholderRecipeImageService(delay: Duration.zero),
          ),
        ],
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

  String results((String, String, List<String>) m) =>
      Routes.mealResults(protein: m.$1, base: m.$2, plants: m.$3);

  testWidgets('a complete library match is shown first, from the library', (
    tester,
  ) async {
    final c = await pump(tester);
    await go(tester, c, results(_bowl));
    expect(find.byType(MealResultsPage), findsOneWidget);
    expect(find.text('RECIPES WITH ALL YOUR FOODS'), findsOneWidget);
    // No generation offered when a complete recipe exists.
    expect(find.text('Create a new recipe'), findsNothing);
    expect(find.byKey(const ValueKey('no-complete-match')), findsNothing);
    // It opens in the normal recipe page.
    await tester.tap(find.textContaining('Black Bean').first);
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
  });

  testWidgets('no complete match: suggestions are labelled, and a new recipe '
      'can be created', (tester) async {
    final c = await pump(tester);
    await go(
      tester,
      c,
      results((
        'black-turtle-bean',
        'quinoa',
        ['yellow-bell-pepper', 'orange', 'kale'],
      )),
    );
    expect(find.byKey(const ValueKey('no-complete-match')), findsOneWidget);
    expect(find.text('CLOSE MATCHES'), findsOneWidget);
    expect(find.text('Without kale'), findsWidgets);
    expect(find.text('Create a new recipe'), findsOneWidget);
  });

  testWidgets('without a generation service the fallback is honest', (
    tester,
  ) async {
    final c = await pump(tester, generation: false);
    await go(tester, c, results(_unusual));
    expect(find.byKey(const ValueKey('no-complete-match')), findsOneWidget);
    expect(
      find.text('Creating a new recipe isn’t available yet.'),
      findsOneWidget,
    );
    expect(find.text('Create a new recipe'), findsNothing);
  });

  testWidgets('Create a new recipe: progress, then the saved recipe opens, '
      'labelled as a development sample', (tester) async {
    final c = await pump(tester);
    await go(tester, c, results(_unusual));
    await tester.tap(find.text('Create a new recipe'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    expect(find.byKey(const ValueKey('personal-recipe-note')), findsOneWidget);
    expect(find.textContaining('Development sample'), findsOneWidget);
    expect(find.textContaining('not by an AI'), findsOneWidget);
    // It is in My recipes, privately.
    await go(tester, c, Routes.myRecipes);
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(find.text('Tempeh & Buckwheat Bowl'), findsOneWidget);
    expect(find.text('Development sample'), findsOneWidget);
  });

  testWidgets('a failed creation says why, saves nothing, and retry works', (
    tester,
  ) async {
    final c = await pump(
      tester,
      failures: const [GenerationFailure(GenerationFailureKind.timeout)],
    );
    await go(tester, c, results(_unusual));
    await tester.tap(find.text('Create a new recipe'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateRecipePage), findsOneWidget);
    expect(find.byKey(const ValueKey('creation-failure')), findsOneWidget);
    expect(find.textContaining('Nothing was used'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
  });

  testWidgets('the same foods again offer the saved recipe instead', (
    tester,
  ) async {
    final c = await pump(tester);
    await go(tester, c, results(_unusual));
    await tester.tap(find.text('Create a new recipe'));
    await tester.pumpAndSettle();
    await go(tester, c, results(_unusual));
    await tester.tap(find.text('Create a new recipe'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('already-saved')), findsOneWidget);
    await tester.tap(find.text('Make another version'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    await go(tester, c, Routes.myRecipes);
    expect(find.text('Tempeh & Buckwheat Bowl'), findsNWidgets(2));
  });

  testWidgets('the creation page leaves a signed-out user with a clear '
      'message', (tester) async {
    final c = await pump(tester, generation: false);
    await go(
      tester,
      c,
      Routes.mealCreate(
        protein: 'tempeh',
        base: 'buckwheat',
        plants: ['kale', 'pomegranate'],
      ),
    );
    expect(find.byKey(const ValueKey('creation-failure')), findsOneWidget);
    expect(
      find.text('Creating a recipe needs an account. Browsing never does.'),
      findsOneWidget,
    );
  });

  testWidgets('a personal recipe can be deleted', (tester) async {
    final c = await pump(tester);
    await go(tester, c, results(_unusual));
    await tester.tap(find.text('Create a new recipe'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete this recipe'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete this recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await go(tester, c, Routes.myRecipes);
    expect(find.text('No recipes yet'), findsOneWidget);
  });
}
