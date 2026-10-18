import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/domain/try_new_search.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';
import 'package:moon_cycle/features/generation/domain/generation_failure.dart';
import 'package:moon_cycle/features/home/presentation/try_new_results_page.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';
import '../../helpers/test_catalogue.dart';

/// No bundled recipe uses all three.
const _unusual = ['kale', 'pomegranate', 'tempeh'];

void main() {
  group('recipesUsingAll', () {
    test('finds recipes that use every food, and only those', () {
      final recipe = testCatalogue.recipe('black-bean-quinoa-orange-bowl')!;
      final ids = [for (final l in recipe.ingredients.take(3)) l.foodId!];
      final found = recipesUsingAll(testCatalogue, FoodFilter.none, ids);
      expect(found.map((r) => r.id), contains(recipe.id));
      for (final r in found) {
        final present = {for (final l in r.ingredients) ?l.foodId};
        expect(ids.every(present.contains), isTrue, reason: r.id);
      }
      expect(
        recipesUsingAll(testCatalogue, FoodFilter.none, _unusual),
        isEmpty,
      );
    });

    test('respects the diet', () {
      final ids = ['sardine', 'spinach', 'lemon'];
      expect(
        recipesUsingAll(testCatalogue, FoodFilter.none, ids).map((r) => r.id),
        contains('sardine-spinach-lemon-toast'),
      );
      expect(
        recipesUsingAll(testCatalogue, const FoodFilter(diet: Diet.vegan), ids),
        isEmpty,
      );
    });

    test('at most three, and a phase puts its own recipes first', () {
      final found = recipesUsingAll(testCatalogue, FoodFilter.none, [
        'olive-oil',
      ], phase: Phase.luteal);
      expect(found.length, 3);
      expect(found.first.phase, Phase.luteal);
    });
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool generation = true,
    bool premium = true,
    DevMockGenerationService? mock,
  }) async {
    tester.view.physicalSize = const Size(390, 3000) * 3;
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
          EntitlementState(tier: premium ? Tier.premium : Tier.free),
        ),
        debugUnlockAtStartProvider.overrideWithValue(generation),
        if (generation) ...[
          recipeGenerationServiceProvider.overrideWithValue(
            mock ??
                DevMockGenerationService(
                  catalogue: testCatalogue,
                  delay: Duration.zero,
                ),
          ),
          recipeImageServiceProvider.overrideWithValue(
            PlaceholderRecipeImageService(delay: Duration.zero),
          ),
        ],
      ],
    );
  }

  Future<void> open(WidgetTester tester, ProviderContainer c) async {
    c.read(appRouterProvider).go(Routes.tryNew(_unusual));
    await tester.pumpAndSettle();
  }

  testWidgets('three foods with no library recipe: three different recipes '
      'are made, each using all three', (tester) async {
    final c = await pump(tester);
    await open(tester, c);
    expect(find.byType(TryNewResultsPage), findsOneWidget);
    expect(find.text('Kale, Pomegranate & Tempeh Skillet'), findsOneWidget);
    expect(find.text('Kale, Pomegranate & Tempeh Soup'), findsOneWidget);
    expect(find.text('Kale, Pomegranate & Tempeh Bake'), findsOneWidget);
    expect(
      find.text('Development sample · not made by an AI'),
      findsNWidgets(3),
    );
    expect(find.byKey(const ValueKey('trio-failure')), findsNothing);
    // Each opens in the normal recipe page.
    await tester.tap(find.text('Kale, Pomegranate & Tempeh Soup'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
  });

  testWidgets('opening it again retrieves the saved recipes instead of '
      'making new ones', (tester) async {
    final mock = DevMockGenerationService(
      catalogue: testCatalogue,
      delay: Duration.zero,
    );
    final c = await pump(tester, mock: mock);
    await open(tester, c);
    expect(mock.calls, 3);
    c.read(appRouterProvider).go(Routes.home);
    await tester.pumpAndSettle();
    await open(tester, c);
    expect(find.text('Kale, Pomegranate & Tempeh Bake'), findsOneWidget);
    expect(mock.calls, 3);
  });

  testWidgets('a failure part-way keeps what was made, explains, and Try '
      'again finishes without duplicates', (tester) async {
    final mock = DevMockGenerationService(
      catalogue: testCatalogue,
      delay: Duration.zero,
      failOnCall: const {2: GenerationFailure(GenerationFailureKind.timeout)},
    );
    final c = await pump(tester, mock: mock);
    await open(tester, c);
    expect(find.text('Kale, Pomegranate & Tempeh Skillet'), findsOneWidget);
    expect(find.text('Kale, Pomegranate & Tempeh Soup'), findsNothing);
    expect(find.byKey(const ValueKey('trio-failure')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Kale, Pomegranate & Tempeh Skillet'), findsOneWidget);
    expect(find.text('Kale, Pomegranate & Tempeh Soup'), findsOneWidget);
    expect(find.text('Kale, Pomegranate & Tempeh Bake'), findsOneWidget);
    expect(find.byKey(const ValueKey('trio-failure')), findsNothing);
  });

  testWidgets('without a generation service: what exists is shown, with an '
      'honest note', (tester) async {
    final c = await pump(tester, generation: false);
    await open(tester, c);
    expect(find.byKey(const ValueKey('trio-none')), findsOneWidget);
    expect(find.byKey(const ValueKey('trio-unavailable')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('without Premium nothing is generated', (tester) async {
    final mock = DevMockGenerationService(
      catalogue: testCatalogue,
      delay: Duration.zero,
    );
    final c = await pump(tester, premium: false, mock: mock);
    await open(tester, c);
    expect(find.byKey(const ValueKey('trio-premium')), findsOneWidget);
    expect(mock.calls, 0);
  });
}
