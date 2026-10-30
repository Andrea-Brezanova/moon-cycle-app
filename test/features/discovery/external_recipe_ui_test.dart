import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/discovery/presentation/meal_results_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/generation/data/saved_recipe_repository.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../helpers/fake_provider_http.dart';
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  late FakeNetwork net;

  Future<ProviderContainer> pump(WidgetTester tester, {bool dev = true}) async {
    tester.view.physicalSize = const Size(390, 5200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    net = mealDbNetwork();
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        entitlementStateProvider.overrideWithValue(
          const EntitlementState(tier: Tier.premium),
        ),
        debugUnlockAtStartProvider.overrideWithValue(dev),
      ],
      providerHttp: net.get,
    );
    return c;
  }

  Future<void> go(WidgetTester tester, ProviderContainer c, String path) async {
    c.read(appRouterProvider).go(path);
    await tester.pumpAndSettle();
  }

  Finder externalCards() => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey &&
        '${(w.key! as ValueKey).value}'.startsWith('uses-x-themealdb-'),
  );

  testWidgets('results mix the library and TheMealDB, each with its source', (
    tester,
  ) async {
    final c = await pump(tester);
    await go(tester, c, Routes.mealResults(['garlic']));
    expect(find.byType(MealResultsPage), findsOneWidget);
    // The library leads: its recipes fill the first page...
    expect(externalCards(), findsNothing);
    // ...and TheMealDB's follow on "See more".
    for (var i = 0; i < 4; i++) {
      final more = find.text('See more recipes');
      if (more.evaluate().isEmpty) break;
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
    }
    expect(externalCards(), findsWidgets);
    expect(find.textContaining('Moon Cycle recipe'), findsWidgets);
    expect(find.textContaining('Recipe from TheMealDB'), findsWidgets);
    // Honest counts: a one-food search says "Uses your food".
    expect(find.text('Uses your food'), findsWidgets);
  });

  testWidgets('without the provider the same page shows only the library', (
    tester,
  ) async {
    final c = await pump(tester, dev: false);
    await go(tester, c, Routes.mealResults(['garlic']));
    expect(externalCards(), findsNothing);
    expect(net.calls, isEmpty);
    expect(find.textContaining('Recipe from TheMealDB'), findsNothing);
  });

  testWidgets('an external recipe opens in Moon Cycle with its full method '
      'and credit, but no shopping list and no invented times', (tester) async {
    final c = await pump(tester);
    await go(tester, c, Routes.recipe('x-themealdb-90001'));
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    expect(find.text('Synthetic Carrot Side'), findsWidgets);
    expect(find.byKey(const ValueKey('external-attribution')), findsOneWidget);
    expect(find.textContaining('Recipe from TheMealDB'), findsOneWidget);
    expect(find.text('View the original recipe'), findsOneWidget);
    // Ingredients and method are there.
    expect(find.text('Carrots'), findsWidgets);
    expect(find.text('Method'), findsOneWidget);
    // No times, no phase claim, no "Why this recipe?", no shopping button.
    expect(find.textContaining(RegExp(r'^\d+ min')), findsNothing);
    expect(find.textContaining('Serves'), findsNothing);
    expect(find.text('Why this recipe?'), findsNothing);
    expect(find.text('Add ingredients to shopping list'), findsNothing);
    expect(find.byKey(const ValueKey('no-shopping-external')), findsOneWidget);
  });

  testWidgets('an unavailable external recipe says so', (tester) async {
    final c = await pump(tester, dev: false);
    await go(tester, c, Routes.recipe('x-themealdb-90001'));
    expect(find.text('This recipe isn’t available'), findsOneWidget);
  });

  testWidgets('saving keeps only a reference, listed in My recipes, and '
      'reopens from the provider', (tester) async {
    final c = await pump(tester);
    await go(tester, c, Routes.recipe('x-themealdb-90001'));
    await tester.tap(find.text('Save to My recipes'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to My recipes · Remove'), findsOneWidget);
    final refs = await tester.runAsync(
      () => c.read(savedRecipeRepositoryProvider).all(),
    );
    final ref = refs!.single;
    expect(ref.providerId, 'themealdb');
    expect(ref.refId, 'x-themealdb-90001');
    expect(ref.externalId, '90001');
    expect(ref.title, 'Synthetic Carrot Side');
    expect(ref.sourceUrl, isNotNull);

    await go(tester, c, Routes.myRecipes);
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('saved-x-themealdb-90001')),
      findsOneWidget,
    );
    expect(find.text('TheMealDB'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saved-x-themealdb-90001')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);

    // Remove it again.
    await tester.tap(find.text('Saved to My recipes · Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Save to My recipes'), findsOneWidget);
  });

  testWidgets('a library recipe is saved as a plain reference', (tester) async {
    final c = await pump(tester);
    await go(tester, c, Routes.recipe('lentil-spinach-tomato-stew'));
    await tester.tap(find.text('Save to My recipes'));
    await tester.pumpAndSettle();
    final refs = await tester.runAsync(
      () => c.read(savedRecipeRepositoryProvider).all(),
    );
    expect(refs!.single.providerId, 'moon-cycle');
    expect(refs.single.isExternal, isFalse);
    expect(refs.single.refId, 'lentil-spinach-tomato-stew');
  });

  testWidgets('a library recipe still has its shopping button and phase', (
    tester,
  ) async {
    final c = await pump(tester);
    await go(tester, c, Routes.recipe('lentil-spinach-tomato-stew'));
    expect(find.text('Add ingredients to shopping list'), findsOneWidget);
    expect(find.text('Why this recipe?'), findsOneWidget);
  });
}
