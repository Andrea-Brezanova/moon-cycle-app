import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_catalogue.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  Future<(ProviderContainer, AppDatabase)> pumpRecipes(
    WidgetTester tester, {
    Future<void> Function(PreferencesRepository prefs)? prefs,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(
      tester,
      db,
      start: sampleStart,
      more: prefs == null ? null : () => prefs(PreferencesRepository(db)),
    );
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-recipes')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    return (container, db);
  }

  testWidgets('the phase’s recipes: a feature card and a grid', (tester) async {
    await pumpRecipes(tester);
    expect(find.text('3 follicular recipes'), findsOneWidget);
    expect(find.text('Zesty Lentil & Broccoli Bowl'), findsOneWidget);
    expect(find.text('Meals · Lentils, broccoli, zucchini'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget); // the time badge
    expect(find.text('Breakfast · 10 min'), findsOneWidget);
  });

  testWidgets('meal types, and the empty Snacks tab', (tester) async {
    await pumpRecipes(tester);
    await tapText(tester, 'Breakfast');
    expect(find.text('1 follicular breakfast'), findsOneWidget);
    await tapText(tester, 'Snacks');
    expect(find.text('0 follicular snacks'), findsOneWidget);
    expect(find.text('No follicular snacks yet'), findsOneWidget);
    await tapText(tester, 'Show all meal types');
    expect(find.text('3 follicular recipes'), findsOneWidget);
  });

  testWidgets('Cook with: search, choose, then breakfast has none', (
    tester,
  ) async {
    await pumpRecipes(tester);
    await tester.tap(find.bySemanticsLabel('Cook with, choose an ingredient'));
    await tester.pumpAndSettle();
    expect(find.text('Foods for your follicular phase'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'chick');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Chicken, 1 recipe'));
    await tester.pumpAndSettle();
    expect(find.text('1 follicular recipe with chicken'), findsOneWidget);
    expect(
      find.text('Lemon Herb Chicken with Artichoke & Peas'),
      findsOneWidget,
    );

    await tapText(tester, 'Breakfast');
    expect(find.text('No breakfasts with chicken'), findsOneWidget);
    expect(
      find.text(
        'There’s a follicular recipe with chicken in another meal type.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Clear ingredient');
    expect(find.text('1 follicular breakfast'), findsOneWidget);
  });

  testWidgets('Cook with: no match, then clear the search', (tester) async {
    await pumpRecipes(tester);
    await tester.tap(find.bySemanticsLabel('Cook with, choose an ingredient'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'salmon');
    await tester.pumpAndSettle();
    expect(find.text('No follicular foods match “salmon”'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('GRAINS'), findsOneWidget);
  });

  testWidgets('another phase clears the ingredient', (tester) async {
    final (container, _) = await pumpRecipes(tester);
    await tester.tap(find.bySemanticsLabel('Cook with, choose an ingredient'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Chicken, 1 recipe'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Luteal');
    expect(find.text('3 luteal recipes'), findsOneWidget);
    expect(container, isNotNull);
  });

  testWidgets('nothing fits the preferences', (tester) async {
    await pumpRecipes(
      tester,
      prefs: (prefs) async {
        await prefs.avoidAllergen('gluten');
        await prefs.avoidFood('broccoli');
      },
    );
    expect(find.text('0 follicular recipes'), findsOneWidget);
    expect(find.text('Nothing fits your preferences'), findsOneWidget);
    expect(find.text('Review food preferences'), findsOneWidget);
  });

  testWidgets(
    'detail: add everything, then the added state; back keeps the filter',
    (tester) async {
      final (_, db) = await pumpRecipes(tester);
      await tapText(tester, 'Meals');
      await tapText(tester, 'Zesty Lentil & Broccoli Bowl');
      expect(find.byType(RecipeDetailPage), findsOneWidget);
      expect(find.text('25 min · Serves 2'), findsOneWidget);
      await tester.ensureVisible(find.text('8 items'));
      expect(find.text('150 g'), findsOneWidget);
      expect(find.text('to serve'), findsOneWidget);

      await tapText(tester, 'Add ingredients to shopping list');
      expect(find.text('Added to shopping list'), findsOneWidget);
      expect(find.text('All 8 ingredients are on your list.'), findsOneWidget);
      expect(find.text('On your list'), findsNWidgets(8));
      final items = await tester.runAsync(ShoppingRepository(db).items);
      expect(items, hasLength(8));

      // The photo's back button has scrolled away; system back works anywhere.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('2 follicular meals'), findsOneWidget);
    },
  );

  testWidgets('detail: the merge note names what’s already on the list', (
    tester,
  ) async {
    final (container, _) = await pumpRecipes(tester);
    // A list change in the test's fake time, then pump until it's done.
    final added = container
        .read(shoppingControllerProvider.notifier)
        .addFood(testCatalogue.food('lemon')!, Phase.follicular);
    await tester.pumpAndSettle();
    await added;
    await tester.pumpAndSettle();
    await tapText(tester, 'Zesty Lentil & Broccoli Bowl');
    await tester.ensureVisible(find.text('Add ingredients to shopping list'));
    expect(
      find.text(
        'Lemon is already on your list. We’ll merge it, not add it twice.',
      ),
      findsOneWidget,
    );
  });
}
