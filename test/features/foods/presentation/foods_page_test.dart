import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/ingredient_sheet.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
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
    expect(find.text('Fresh, light and energising'), findsOneWidget);
    expect(find.text('Tap a food to cook with it'), findsOneWidget);
    await scrollTo(tester, find.text('Grains'));
    expect(find.text('4'), findsOneWidget); // Barley, Oat, Rye, Wheat
    expect(find.bySemanticsLabel('Barley, 1 recipe'), findsOneWidget);
    expect(find.bySemanticsLabel('Rye'), findsOneWidget);
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
        await prefs.avoidAllergen('gluten'); // every follicular grain
        await prefs.avoidFood('lemon');
      },
    );
    await scrollTo(tester, find.text('Vegetables'));
    expect(find.text('Grains'), findsNothing);
    await scrollTo(tester, find.text('Fruit'));
    expect(find.text('Lemon'), findsNothing);
    expect(find.text('Lime'), findsOneWidget);
  });

  testWidgets('the sheet: copy, add, then "On your list"', (tester) async {
    final (container, db) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Chicken'));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('MEAT'), findsOneWidget);
    expect(find.text('Recommended for your follicular phase'), findsOneWidget);
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
    await scrollTo(tester, find.text('Rye'));
    await tester.tap(find.text('Rye'));
    await tester.pumpAndSettle();
    expect(find.text('No recipes with rye yet.'), findsOneWidget);
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
    expect(
      find.text('Placeholder. The real screen arrives in Milestone 11.'),
      findsOneWidget,
    );
    expect(container.read(recipeFilterProvider).foodId, 'chicken');
  });
}
