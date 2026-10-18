import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/design/widgets/moon_list.dart';
import 'package:moon_cycle/core/design/widgets/pressable.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/application/todays_food.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/foods/presentation/widgets/todays_food_card.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/settings/presentation/subscription_page.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_catalogue.dart';

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

  /// Scrolls [finder] clear of the tab bar that overlays a page's bottom.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
  }

  /// The page's "‹ Foods" back control.
  Future<void> goBack(WidgetTester tester) async {
    // The header scrolls with the page.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SubScreenHeader),
        matching: find.byType(Pressable),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Today’s food, then the phase’s food library', (tester) async {
    final (container, _) = await pumpFoods(tester);
    expect(find.text('Your current phase · day 7'), findsOneWidget);
    // The explanation lives on Learn more, the meal builder on its own page.
    expect(find.text('WHAT YOUR BODY MAY NEED'), findsNothing);
    expect(find.text('Build a balanced meal'), findsNothing);
    expect(find.text('TODAY’S FOOD'), findsOneWidget);
    final todays = container.read(todaysFoodProvider)!;
    expect(
      find.text('See ${todays.displayName.toLowerCase()} →'),
      findsOneWidget,
    );
    expect(find.text(todays.why[Phase.follicular]!.short), findsOneWidget);
    expect(find.text('YOUR FOODS FOR THIS PHASE'), findsOneWidget);
    expect(
      find.text('Tap a food to see why we feature it and find recipes.'),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Grains'));
    expect(find.text('Farro'), findsOneWidget);
    expect(find.text('Oat bran'), findsOneWidget);
    expect(find.text('Quinoa'), findsNothing); // featured elsewhere
    expect(find.bySemanticsLabel('Farro'), findsOneWidget);
    await scrollTo(tester, find.text('Lettuce'));
    expect(find.text('Bibb, Boston, romaine'), findsNothing);
  });

  testWidgets('Today’s food: a playful headline, stable, and always the real '
      'phase’s', (tester) async {
    final (container, _) = await pumpFoods(tester);
    final todays = container.read(todaysFoodProvider)!;
    final headlines = {
      for (final t in todaysFoodHeadlines)
        todaysFoodHeadline(t, todays.displayName).replaceAll('*', ''),
    };
    final shown = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .where(headlines.contains);
    expect(shown, isNotEmpty);

    // Browsing another phase changes the library, not Today's food.
    await tester.tap(find.text('Luteal'));
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(container.read(todaysFoodProvider)!.id, todays.id);
    expect(find.text('TODAY’S FOOD'), findsOneWidget);
    expect(
      find.text('See ${todays.displayName.toLowerCase()} →'),
      findsOneWidget,
    );
  });

  testWidgets('Today’s food opens its page with the real phase’s reason', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    final todays = container.read(todaysFoodProvider)!;
    await tester.tap(find.text('See ${todays.displayName.toLowerCase()} →'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
    expect(find.text('Recommended for your follicular phase'), findsOneWidget);
    expect(find.text(todays.why[Phase.follicular]!.short), findsWidgets);
  });

  testWidgets('All foods: search, and a page without phase context', (
    tester,
  ) async {
    await pumpFoods(tester);
    await tester.tap(find.text('All foods'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY’S FOOD'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'lettuce');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lettuce').last);
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
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
    expect(find.text('Lemon'), findsWidgets);
    await tester.tap(find.text('Lemon').last);
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsNothing);
    expect(find.textContaining('Recommended for your'), findsNothing);
    expect(find.textContaining('Featured in'), findsNothing);
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

  testWidgets('a food’s page: copy, then Add to shopping list; Back keeps '
      'the Foods filter', (tester) async {
    final (container, db) = await pumpFoods(tester);
    await tester.tap(find.text('Luteal'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Salmon'));
    await tester.tap(find.text('Salmon'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    expect(find.text('SEAFOOD'), findsOneWidget);
    expect(find.text('Recommended for your luteal phase'), findsOneWidget);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
    final salmon = testCatalogue.food('salmon')!;
    expect(find.text(salmon.why[Phase.luteal]!.short), findsOneWidget);

    await reveal(tester, find.text('Add to shopping list'));
    await tester.tap(find.text('Add to shopping list'));
    await tester.pumpAndSettle();
    expect(find.text('On your shopping list'), findsOneWidget);
    final items = await tester.runAsync(ShoppingRepository(db).items);
    expect(items!.single.key, 'food:salmon');

    await goBack(tester);
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsNothing);
    // Still the phase and the library the user was in.
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    // The list is where the user left it (scrolled to Salmon), now marked.
    expect(find.text('Salmon'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Salmon, on your shopping list'),
      findsOneWidget,
    );
  });

  testWidgets('the shopping control is independent of opening a food', (
    tester,
  ) async {
    final (_, db) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Chicken'));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    await goBack(tester);
    await tester.pumpAndSettle();
    final items = await tester.runAsync(ShoppingRepository(db).items);
    expect(items, isEmpty); // opening a food never adds it
  });

  testWidgets('a food without recipes: no recipe button', (tester) async {
    final (container, _) = await pumpFoods(tester);
    // Every featured food now has a recipe; a general food may not.
    final counts = container.read(allRecipeCountsProvider);
    final none = testCatalogue.foods.firstWhere(
      (f) => (counts[f.id] ?? 0) == 0,
    );
    await tester.tap(find.text('All foods'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), none.displayName);
    await tester.pumpAndSettle();
    // The chip, not the search field's own text.
    await tester.tap(find.text(none.displayName).last);
    await tester.pumpAndSettle();
    expect(
      find.text('No recipes with ${none.displayName.toLowerCase()} yet.'),
      findsOneWidget,
    );
    expect(find.textContaining('Find recipes'), findsNothing);
  });

  testWidgets('a featured food shows its recipe count', (tester) async {
    await pumpFoods(tester);
    await scrollTo(tester, find.text('Turnip'));
    await tester.tap(find.text('Turnip'));
    await tester.pumpAndSettle();
    // Turnip had no recipe before; three follicular recipes now use it.
    expect(find.text('Find recipes with turnip'), findsOneWidget);
    await tester.tap(find.text('Find recipes with turnip'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(find.text('3 follicular recipes with turnip'), findsOneWidget);
  });

  testWidgets('"Find recipes" opens Recipes filtered by the food', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Chicken'));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find recipes with chicken'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsNothing);
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(container.read(recipeFilterProvider).foodId, 'chicken');
    expect(find.text('3 follicular recipes with chicken'), findsOneWidget);
  });

  group('the four actions and Premium', () {
    Future<void> openChicken(WidgetTester tester) async {
      await scrollTo(tester, find.text('Chicken'));
      await tester.tap(find.text('Chicken'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Add to logged meals'));
    }

    testWidgets('free: the meal builder is locked', (tester) async {
      await pumpFoods(tester);
      await openChicken(tester);
      await tester.tap(find.text('Make your own meal with chicken'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionPage), findsOneWidget);
    });

    testWidgets('free: logged meals is Premium and goes to Subscription', (
      tester,
    ) async {
      await pumpFoods(tester);
      await openChicken(tester);
      await tester.tap(find.text('Add to logged meals'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionPage), findsOneWidget);
    });

    testWidgets(
      'Premium: the meal builder opens; logged meals opens the diary sheet',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final db = testDatabase();
        await seedCycle(tester, db, start: sampleStart);
        await pumpApp(
          tester,
          database: db,
          overrides: [
            clockProvider.overrideWithValue(designNow),
            entitlementStateProvider.overrideWithValue(
              const EntitlementState(tier: Tier.premium),
            ),
          ],
        );
        await tester.tap(find.byKey(const ValueKey('tab-foods')));
        await tester.pumpAndSettle();
        await openChicken(tester);
        await tester.tap(find.text('Add to logged meals'));
        await tester.pumpAndSettle();
        expect(find.text('Add to your diary'), findsOneWidget);
        await tester.tapAt(const Offset(195, 60)); // dismiss the sheet
        await tester.pumpAndSettle();
        expect(find.byType(FoodDetailPage), findsOneWidget);
        await tester.tap(find.text('Make your own meal with chicken'));
        await tester.pumpAndSettle();
        expect(find.byType(MealBuilderPage), findsOneWidget);
        expect(find.text('Choose a protein'), findsOneWidget);
      },
    );
  });
}
