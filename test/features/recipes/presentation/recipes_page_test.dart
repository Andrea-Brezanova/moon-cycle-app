import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_catalogue.dart';

/// Chooses a row in "Browse by phase" ("All phases", "Luteal", ...).
Future<void> browse(WidgetTester tester, String row) async {
  await tester.tap(find.byKey(const ValueKey('phase-pill')));
  await tester.pumpAndSettle();
  final target = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text(row),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

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
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    return (container, db);
  }

  testWidgets('the phase’s recipes as cards with a heart', (tester) async {
    await pumpRecipes(tester);
    expect(find.text('29 follicular recipes'), findsOneWidget);
    expect(find.text('Zucchini & Feta Herb Frittata'), findsOneWidget);
    expect(find.text('Meals · 25 min'), findsWidgets); // the card's meta
  });

  testWidgets('meal tabs: the types the phase has recipes for', (tester) async {
    final (container, _) = await pumpRecipes(tester);
    // Follicular has breakfasts, meals and snacks.
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    await tapText(tester, 'Breakfast');
    expect(find.text('9 follicular breakfasts'), findsOneWidget);
    await tapText(tester, 'Meals');
    expect(find.text('18 follicular meals'), findsOneWidget);
    await tapText(tester, 'Snacks');
    expect(find.text('2 follicular snacks'), findsOneWidget);

    // Another phase keeps the selected tab and shows its own count.
    container.read(viewingPhaseProvider.notifier).choose(Phase.menstrual);
    await tester.pumpAndSettle();
    expect(find.text('3 menstrual snacks'), findsOneWidget);
    container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
    await tester.pumpAndSettle();
    expect(find.text('1 luteal snack'), findsOneWidget);
    container.read(viewingPhaseProvider.notifier).choose(Phase.follicular);
    await tester.pumpAndSettle();
    expect(find.text('2 follicular snacks'), findsOneWidget);
  });

  testWidgets('All recipes: every meal type, all 112 recipes', (tester) async {
    await pumpRecipes(tester);
    await browse(tester, 'All phases');
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('112 recipes'), findsOneWidget);
    await tapText(tester, 'Snacks');
    expect(find.text('11 snacks'), findsOneWidget);
    await browse(tester, 'Follicular');
    expect(find.text('2 follicular snacks'), findsOneWidget);
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
    await tester.tap(find.bySemanticsLabel('Chicken, 3 recipes'));
    await tester.pumpAndSettle();
    expect(find.text('3 follicular recipes with chicken'), findsOneWidget);
    expect(find.text('Lemon Chicken & Green Bean Tray Bake'), findsOneWidget);

    await tapText(tester, 'Breakfast');
    expect(find.text('No breakfasts with chicken'), findsOneWidget);
    expect(
      find.text(
        'There are 3 follicular recipes with chicken in other meal types.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Clear ingredient');
    expect(find.text('9 follicular breakfasts'), findsOneWidget);
  });

  testWidgets('Cook with: no match, then clear the search', (tester) async {
    await pumpRecipes(tester);
    await tester.tap(find.bySemanticsLabel('Cook with, choose an ingredient'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'banana');
    await tester.pumpAndSettle();
    expect(find.text('No follicular foods match “banana”'), findsOneWidget);
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
    await tester.tap(find.bySemanticsLabel('Chicken, 3 recipes'));
    await tester.pumpAndSettle();
    await browse(tester, 'Luteal');
    expect(find.text('30 luteal recipes'), findsOneWidget);
    expect(container, isNotNull);
  });

  testWidgets('All recipes: no phase-derived Cook with…', (tester) async {
    await pumpRecipes(tester);
    expect(
      find.bySemanticsLabel('Cook with, choose an ingredient'),
      findsOneWidget,
    );
    await browse(tester, 'All phases');
    expect(
      find.bySemanticsLabel('Cook with, choose an ingredient'),
      findsNothing,
    );
    await browse(tester, 'Follicular');
    expect(
      find.bySemanticsLabel('Cook with, choose an ingredient'),
      findsOneWidget,
    );
  });

  testWidgets('nothing fits the preferences', (tester) async {
    // Avoid one key food of every follicular recipe.
    final avoided = {
      for (final r in testCatalogue.recipesFor(Phase.follicular))
        r.ingredients.firstWhere((l) => l.foodId != null).foodId!,
    };
    await pumpRecipes(
      tester,
      prefs: (prefs) async {
        for (final id in avoided) {
          await prefs.avoidFood(id);
        }
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
      await tapText(tester, 'Zucchini & Feta Herb Frittata');
      expect(find.byType(RecipeDetailPage), findsOneWidget);
      expect(find.text('25 min · Serves 4'), findsOneWidget);
      expect(find.text('Why this recipe?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recipe-why-this-phase')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('6 items'));
      expect(find.text('4 oz (100 g)'), findsOneWidget); // US + metric

      await tapText(tester, 'Add ingredients to shopping list');
      expect(find.text('Added to shopping list'), findsOneWidget);
      expect(find.text('All 6 ingredients are on your list.'), findsOneWidget);
      expect(find.text('On your list'), findsNWidgets(6));
      final items = await tester.runAsync(ShoppingRepository(db).items);
      expect(items, hasLength(6));

      // The photo's back button has scrolled away; system back works anywhere.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // The list is where it was left; scroll up to the count.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('18 follicular meals'), findsOneWidget);
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
    await tapText(tester, 'Lemon Chicken & Green Bean Tray Bake');
    await tester.ensureVisible(find.text('Add ingredients to shopping list'));
    expect(
      find.text(
        'Lemon is already on your list. We’ll merge it, not add it twice.',
      ),
      findsOneWidget,
    );
  });
}
