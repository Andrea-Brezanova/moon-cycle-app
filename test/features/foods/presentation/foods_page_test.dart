import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
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
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);
    return (container, db);
  }

  /// Chooses a row in "Browse by phase".
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

  /// Opens the "Food type" sheet and returns the rows' semantic labels.
  Future<void> openTypeSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('type-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Food type'), findsOneWidget);
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

  /// The page's back chevron.
  Future<void> goBack(WidgetTester tester) async {
    // The header scrolls with the page.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
  }

  testWidgets('Today’s food, then the phase’s food library', (tester) async {
    final (container, _) = await pumpFoods(tester);
    expect(find.text('Follicular'), findsWidgets); // the phase pill
    // The explanation lives on Learn more, the meal builder on its own page.
    expect(find.text('WHAT YOUR BODY MAY NEED'), findsNothing);
    expect(find.text('Build a balanced meal'), findsNothing);
    expect(find.text('TODAY’S FOOD'), findsOneWidget);
    final todays = container.read(todaysFoodProvider)!;
    expect(find.text(todays.why[Phase.follicular]!.short), findsOneWidget);
    expect(find.text('All foods'), findsOneWidget); // the type control
    expect(find.textContaining(RegExp(r'^\d+ foods$')), findsOneWidget);
    await scrollTo(tester, find.text('Farro'));
    expect(find.text('Oat bran'), findsOneWidget);
    expect(find.text('Quinoa'), findsNothing); // featured elsewhere
    expect(find.bySemanticsLabel('Farro, Grains'), findsOneWidget);
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
    await browse(tester, 'Luteal');
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(container.read(todaysFoodProvider)!.id, todays.id);
    expect(find.text('TODAY’S FOOD'), findsOneWidget);
  });

  testWidgets('Today’s food opens its page with the real phase’s reason', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    final todays = container.read(todaysFoodProvider)!;
    await tester.tap(find.text('TODAY’S FOOD'));
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
    await browse(tester, 'All phases');
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
    await browse(tester, 'All phases');
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

  testWidgets(
    'the filter bar and type sheet fit a narrow phone at large text',
    (tester) async {
      await pumpFoods(tester);
      tester.view.physicalSize = const Size(320, 690) * 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await openTypeSheet(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel(RegExp(r'^All foods, \d+$')),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Grains, \d+$')));
      await tester.pumpAndSettle();
      expect(find.text('Grains'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the type sheet filters the list and the count updates', (
    tester,
  ) async {
    await pumpFoods(tester);
    String count() =>
        tester.widget<Text>(find.textContaining(RegExp(r'^\d+ foods?$'))).data!;
    final all = count();
    await openTypeSheet(tester);
    // Every row carries its count; the chosen one is marked.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Grains, \d+$')));
    await tester.pumpAndSettle();
    expect(find.text('Food type'), findsNothing); // the sheet closed
    final grains = count();
    expect(grains, isNot(all));
    expect(
      int.parse(grains.split(' ').first),
      lessThan(int.parse(all.split(' ').first)),
    );
    // The featured card hides while filtered; the list holds only grains.
    expect(find.text('TODAY’S FOOD'), findsNothing);
    await scrollTo(tester, find.text('Farro'));
    expect(find.text('Lettuce'), findsNothing);
    // Back to everything.
    await openTypeSheet(tester);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^All foods, \d+$')));
    await tester.pumpAndSettle();
    expect(count(), all);
  });

  testWidgets('another phase: the pill follows and the way back', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    await browse(tester, 'Luteal');
    expect(find.text('Luteal'), findsWidgets); // the pill follows
    await browse(tester, 'Follicular');
    expect(container.read(viewingPhaseProvider), Phase.follicular);
  });

  testWidgets('avoided foods and empty categories are hidden', (tester) async {
    await pumpFoods(
      tester,
      prefs: (prefs) async {
        await prefs.avoidAllergen('dairy'); // feta and plain yogurt
        await prefs.avoidFood('plum');
      },
    );
    await scrollTo(tester, find.text('Pomegranate'));
    expect(find.text('Plum'), findsNothing);
    // A category with nothing left is not in the type sheet.
    await openTypeSheet(tester);
    expect(find.text('Dairy & alternatives'), findsNothing);
    await tester.tapAt(const Offset(10, 10)); // dismiss
    expect(find.text('Feta'), findsNothing);
    expect(find.text('Plain yogurt'), findsNothing);
  });

  testWidgets('a food’s page: copy, then Add to shopping list; Back keeps '
      'the Foods filter', (tester) async {
    final (container, db) = await pumpFoods(tester);
    await browse(tester, 'Luteal');
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
    expect(find.text('Remove from shopping list'), findsOneWidget);
    expect(find.text('Add to shopping list'), findsNothing);
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
      find.bySemanticsLabel('Remove Salmon from shopping list'),
      findsOneWidget,
    );
  });

  testWidgets('the search icon opens a search that filters the list', (
    tester,
  ) async {
    await pumpFoods(tester);
    expect(find.text('Search foods'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('foods-search')));
    await tester.pumpAndSettle();
    expect(find.text('Search foods'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'farro');
    await tester.pumpAndSettle();
    expect(find.text('1 food'), findsOneWidget);
    expect(find.text('TODAY’S FOOD'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('foods-search')));
    await tester.pumpAndSettle();
    expect(find.text('Search foods'), findsNothing);
    expect(find.text('TODAY’S FOOD'), findsOneWidget);
  });

  testWidgets('the + button adds a food to the shopping list and persists; '
      'the check removes it', (tester) async {
    final (_, db) = await pumpFoods(tester);
    await scrollTo(tester, find.text('Farro'));
    await tester.tap(find.bySemanticsLabel('Add Farro to shopping list'));
    await tester.pumpAndSettle();
    var items = await tester.runAsync(ShoppingRepository(db).items);
    expect(items!.single.key, 'food:farro');
    expect(find.byType(FoodDetailPage), findsNothing); // the row didn't open
    expect(
      find.bySemanticsLabel('Remove Farro from shopping list'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Remove Farro from shopping list'));
    await tester.pumpAndSettle();
    items = await tester.runAsync(ShoppingRepository(db).items);
    expect(items, isEmpty);
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

  testWidgets('a food without recipes: a disabled button and the reason', (
    tester,
  ) async {
    final (container, _) = await pumpFoods(tester);
    // Every featured food now has a recipe; a general food may not.
    final counts = container.read(allRecipeCountsProvider);
    final none = testCatalogue.foods.firstWhere(
      (f) => (counts[f.id] ?? 0) == 0,
    );
    await browse(tester, 'All phases');
    await tester.enterText(find.byType(EditableText), none.displayName);
    await tester.pumpAndSettle();
    // The chip, not the search field's own text.
    await tester.tap(find.text(none.displayName).last);
    await tester.pumpAndSettle();
    expect(
      find.text('No recipes with ${none.displayName.toLowerCase()} yet.'),
      findsOneWidget,
    );
    // The same four actions in the same order, with Find recipes disabled.
    final find_ = find.text(
      'Find recipes with ${none.displayName.toLowerCase()}',
    );
    expect(find_, findsOneWidget);
    await tester.tap(find_, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget); // nothing opened
    expect(find.byType(RecipesPage), findsNothing);
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
    expect(find.text('3 recipes with turnip'), findsOneWidget);
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
    expect(find.text('3 recipes with chicken'), findsOneWidget);
  });

  group('the four actions are free', () {
    Future<void> openChicken(WidgetTester tester) async {
      await scrollTo(tester, find.text('Chicken'));
      await tester.tap(find.text('Chicken'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Log meal'));
    }

    testWidgets('free: the meal builder opens (no Subscription page)', (
      tester,
    ) async {
      await pumpFoods(tester);
      await openChicken(tester);
      await tester.tap(find.text('Build a Meal with chicken'));
      await tester.pumpAndSettle();
      expect(find.byType(MealBuilderPage), findsOneWidget);
      expect(find.byType(SubscriptionPage), findsNothing);
    });

    testWidgets('free: Log meal is free and opens the form', (tester) async {
      await pumpFoods(tester);
      await openChicken(tester);
      await tester.tap(find.text('Log meal'));
      await tester.pumpAndSettle();
      expect(find.byType(LogMealPage), findsOneWidget);
      expect(find.byType(SubscriptionPage), findsNothing);
    });

    testWidgets('Premium: the meal builder opens; Log meal opens the form', (
      tester,
    ) async {
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
      await tester.tap(find.byKey(const ValueKey('tab-eat')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Foods'));
      await tester.pumpAndSettle();
      await openChicken(tester);
      await tester.tap(find.text('Log meal'));
      await tester.pumpAndSettle();
      expect(find.byType(LogMealPage), findsOneWidget);
      expect(find.text('Food · added from the food page'), findsOneWidget);
      await tester.tap(find.text('Cancel')); // back to the food, unsaved
      await tester.pumpAndSettle();
      expect(find.byType(FoodDetailPage), findsOneWidget);
      await tester.tap(find.text('Build a Meal with chicken'));
      await tester.pumpAndSettle();
      expect(find.byType(MealBuilderPage), findsOneWidget);
      expect(find.text('Proteins'), findsOneWidget);
    });
  });
}
