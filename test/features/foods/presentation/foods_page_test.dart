import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/ingredient_sheet.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

void main() {
  Future<(ProviderContainer, AppDatabase)> pumpFoods(
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
    await tester.tap(find.byKey(const ValueKey('tab-foods')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);
    return (container, db);
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

  testWidgets('the current phase, its intro and its categories', (
    tester,
  ) async {
    await pumpFoods(tester);
    expect(find.text('Your current phase · day 7'), findsOneWidget);
    expect(find.text('Inner spring'), findsOneWidget);
    expect(find.text('Fresh, light and quick'), findsOneWidget);
    // The universal note sits directly below the phase intro.
    expect(
      find.text(
        'These are suggestions, not rules — any food can be enjoyed in any '
        'phase.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tap a food to cook with it'), findsOneWidget);
    await scrollTo(tester, find.text('Grains'));
    expect(find.text('Oat'), findsOneWidget);
    expect(find.text('Barley'), findsOneWidget);
    expect(find.text('Quinoa'), findsOneWidget);
    expect(find.bySemanticsLabel('Barley, 1 recipe'), findsOneWidget);
    expect(find.bySemanticsLabel('Quinoa'), findsOneWidget);
    await scrollTo(tester, find.text('Bibb, Boston, romaine'));
    expect(find.text('Lettuce'), findsOneWidget);
  });

  testWidgets('another phase: browsing line and the way back', (tester) async {
    await pumpFoods(tester);
    await tester.tap(find.text('Luteal'));
    await tester.pumpAndSettle();
    expect(find.text('Browsing luteal ·'), findsOneWidget);
    expect(find.text('Inner autumn'), findsOneWidget);
    await tester.tap(find.text('Back to follicular'));
    await tester.pumpAndSettle();
    expect(find.text('Your current phase · day 7'), findsOneWidget);
  });

  testWidgets('avoided foods and empty categories are hidden', (tester) async {
    await pumpFoods(
      tester,
      prefs: (prefs) async {
        await prefs.avoidAllergen('dairy'); // the only dairy food: Greek yogurt
        await prefs.avoidFood('orange');
      },
    );
    await scrollTo(tester, find.text('Vegetables'));
    await scrollTo(tester, find.text('Fruit'));
    expect(find.text('Orange'), findsNothing);
    expect(find.text('Apple'), findsOneWidget);
    await scrollTo(tester, find.text('Fermented'));
    expect(find.text('Dairy & alternatives'), findsNothing);
    expect(find.text('Greek yogurt'), findsNothing);
  });

  testWidgets('the sheet: copy, add, then "On your list"', (tester) async {
    final (container, db) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Chicken'));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('Recommended for your follicular phase'), findsOneWidget);
    // The phase-specific "why this food?" copy.
    expect(
      find.text(
        'Chicken is a quick-cooking protein for stir-fries, salads and '
        'sheet-pan meals.',
      ),
      findsOneWidget,
    );
    expect(find.text('See 1 recipe with chicken'), findsOneWidget);

    await tester.tap(find.text('Add to shopping list'));
    await tester.pumpAndSettle();
    expect(find.text('On your list'), findsOneWidget); // the sheet stays open
    final items = await tester.runAsync(ShoppingRepository(db).items);
    expect(items!.single.key, 'food:chicken');

    Navigator.of(tester.element(find.byType(IngredientSheet))).pop();
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Chicken, 1 recipe, on your list'),
      findsOneWidget,
    );
    expect(container, isNotNull);
  });

  testWidgets('a food without recipes: no recipe button', (tester) async {
    await pumpFoods(tester);
    await scrollTo(tester, find.text('Tofu'));
    await tester.tap(find.text('Tofu'));
    await tester.pumpAndSettle();
    expect(find.text('No recipes with tofu yet.'), findsOneWidget);
    expect(find.textContaining('See '), findsNothing);
  });

  testWidgets('"See N recipes" opens Recipes filtered by the food', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Chicken'));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See 1 recipe with chicken'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsNothing);
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(container.read(recipeFilterProvider).foodId, 'chicken');
    expect(find.text('1 follicular recipe with chicken'), findsOneWidget);
  });
}
