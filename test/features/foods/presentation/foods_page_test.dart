import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/ingredient_sheet.dart';
import 'package:moon_cycle/features/foods/presentation/widgets/meal_builder_section.dart';
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

  Future<void> scrollTo(
    WidgetTester tester,
    Finder finder, {
    double step = 200,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      step,
      maxScrolls: 200,
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
        'These are suggestions, not rules. We feature different foods across '
        'your cycle to encourage variety — you can enjoy any food at any time.',
      ),
      findsOneWidget,
    );
    // The three approved points, in order.
    expect(find.text('WHAT YOUR BODY MAY NEED'), findsOneWidget);
    expect(find.text('WHY THESE FOODS'), findsOneWidget);
    expect(find.text('HOW TO EAT THIS PHASE'), findsOneWidget);
    expect(
      find.text(
        'Think fresh starts: colourful produce, nourishing whole foods and '
        'plenty of variety to build light, balanced meals.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Fresh, light and quick: salads, bowls, light steaming and quick '
        'sautés.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Tap a food to see why we feature it and find recipes.'),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Grains'));
    expect(find.text('Farro'), findsOneWidget);
    expect(find.text('Oat bran'), findsOneWidget);
    // Featured elsewhere: not on this phase's list.
    expect(find.text('Quinoa'), findsNothing);
    // Chips carry no recipe counts; those live in the sheet.
    expect(find.bySemanticsLabel('Farro'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('recipe')), findsNothing);
    // A name's parenthetical is shown in the sheet, not on the chip.
    await scrollTo(tester, find.text('Lettuce'));
    expect(find.text('Bibb, Boston, romaine'), findsNothing);
  });

  testWidgets('All foods: search, and a sheet without phase context', (
    tester,
  ) async {
    await pumpFoods(tester);
    await tester.tap(find.text('All foods'));
    await tester.pumpAndSettle();
    expect(find.text('WHAT YOUR BODY MAY NEED'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'lettuce');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lettuce'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('Bibb, Boston, romaine'), findsOneWidget);
    expect(find.text('ABOUT THIS FOOD'), findsOneWidget);
    expect(find.textContaining('Featured in the '), findsOneWidget);
    // No phase-specific rationale without phase context.
    expect(find.text('WHY THIS FOOD?'), findsNothing);
    expect(find.textContaining('Recommended for your'), findsNothing);
  });

  testWidgets('All foods: a general food on no phase list still appears', (
    tester,
  ) async {
    await pumpFoods(tester);
    await tester.tap(find.text('All foods'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'lemon');
    await tester.pumpAndSettle();
    expect(find.text('Lemon'), findsOneWidget);
    await tester.tap(find.text('Lemon'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    // Not featured in any phase: nothing phase-specific is invented.
    expect(find.text('WHY THIS FOOD?'), findsNothing);
    expect(find.textContaining('Recommended for your'), findsNothing);
    expect(find.textContaining('Featured in'), findsNothing);
  });

  testWidgets('Build a balanced meal: wording and tappable protein ideas', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    // Menstrual has featured foods and general "Also good" suggestions.
    await tester.tap(find.text('Menstrual'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Build a balanced meal'));
    expect(find.text('Build a balanced meal'), findsOneWidget);
    expect(
      find.text(
        'For a simple meal, start with a protein, add a satisfying base, '
        'then add 2–3 plants you enjoy.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Featured foods are what Moon Cycle emphasizes in this phase for '
        'nutrition fit, meal style and variety. You can enjoy any food at '
        'any time.',
      ),
      findsOneWidget,
    );
    final ideas = container.read(proteinIdeasProvider(Phase.menstrual));
    expect(ideas.featured, isNotEmpty);
    expect(ideas.general, isNotEmpty);
    await scrollTo(tester, find.text('Protein ideas'));
    await tester.tap(find.text('Protein ideas'));
    await tester.pumpAndSettle();
    expect(find.text('Featured this phase'), findsOneWidget);
    expect(find.text('Also good'), findsOneWidget);

    Finder chip(String name) => find.descendant(
      of: find.byType(MealBuilderSection),
      matching: find.text(name),
    );

    // A featured idea opens with its phase-specific "Why this food?".
    final featured = ideas.featured.first;
    await tester.tap(chip(featured.displayName));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
    expect(find.text(featured.why[Phase.menstrual]!.short), findsOneWidget);
    Navigator.of(tester.element(find.byType(IngredientSheet))).pop();
    await tester.pumpAndSettle();

    // An "Also good" idea opens without an invented phase rationale.
    final general = ideas.general.first;
    await tester.tap(chip(general.displayName));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsNothing);
    expect(find.textContaining('Recommended for your'), findsNothing);
  });

  testWidgets('Base ideas: featured and general chips open the right sheet', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    await tester.tap(find.text('Luteal'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Base ideas'));
    await tester.tap(find.text('Base ideas'));
    await tester.pumpAndSettle();
    final base = container.read(baseIdeasProvider(Phase.luteal));
    expect(base.featured, isNotEmpty);
    expect(base.general, isNotEmpty);

    Finder chip(String name) => find.descendant(
      of: find.byType(MealBuilderSection),
      matching: find.text(name),
    );

    final featured = base.featured.first;
    await tester.ensureVisible(chip(featured.displayName));
    await tester.tap(chip(featured.displayName));
    await tester.pumpAndSettle();
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
    expect(find.text(featured.why[Phase.luteal]!.short), findsOneWidget);
    Navigator.of(tester.element(find.byType(IngredientSheet))).pop();
    await tester.pumpAndSettle();

    final general = base.general.first;
    await tester.ensureVisible(chip(general.displayName));
    await tester.tap(chip(general.displayName));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsNothing);
    expect(find.textContaining('Recommended for your'), findsNothing);
  });

  testWidgets('chips wrap on a narrow phone at large text', (tester) async {
    await pumpFoods(tester);
    tester.view.physicalSize = const Size(320, 690) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    // Scroll through every category; an overflow would fail the test.
    await scrollTo(tester, find.text('Fermented'));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('All foods'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All foods'));
    await tester.pumpAndSettle();
    // The whole catalogue wraps onto many lines at this size.
    await scrollTo(tester, find.text('Other'), step: 600);
    expect(tester.takeException(), isNull);
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
        await prefs.avoidAllergen('dairy'); // feta and plain yogurt
        await prefs.avoidFood('plum');
      },
    );
    await scrollTo(tester, find.text('Vegetables'));
    await scrollTo(tester, find.text('Fruit'));
    expect(find.text('Plum'), findsNothing);
    expect(find.text('Pomegranate'), findsOneWidget);
    await scrollTo(tester, find.text('Fermented'));
    expect(find.text('Dairy & alternatives'), findsNothing);
    expect(find.text('Feta'), findsNothing);
    expect(find.text('Plain yogurt'), findsNothing);
  });

  testWidgets('the sheet: copy, add, then "On your list"', (tester) async {
    final (container, db) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Chicken'));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientSheet), findsOneWidget);
    expect(find.text('MEAT, EGGS & PLANT PROTEINS'), findsOneWidget);
    expect(find.text('Recommended for your follicular phase'), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
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
    expect(find.bySemanticsLabel('Chicken, on your list'), findsOneWidget);
    expect(container, isNotNull);
  });

  testWidgets('a food without recipes: no recipe button', (tester) async {
    await pumpFoods(tester);
    await scrollTo(tester, find.text('Turnip'));
    await tester.tap(find.text('Turnip'));
    await tester.pumpAndSettle();
    expect(find.text('No recipes with turnip yet.'), findsOneWidget);
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
