@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/discovery/presentation/meal_results_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';
import 'package:moon_cycle/features/generation/domain/balanced_selection.dart';
import 'package:moon_cycle/features/generation/presentation/create_recipe_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/plants/presentation/three_plants_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_catalogue.dart';
import 'home_golden_test.dart' show stateOnDay;

final _complete = MealChoice(['quinoa', 'orange']);
final _mixed = MealChoice(['quinoa', 'orange', 'salmon']);
final _empty = MealChoice(['kombu', 'wakame']);
const _balanced = BalancedSelection(
  proteinId: 'black-turtle-bean',
  baseId: 'quinoa',
  plantIds: ['yellow-bell-pepper', 'orange', 'kale'],
);

void main() {
  setUpAll(loadMoonFonts);

  final overrides = [
    cycleStateProvider.overrideWithValue(stateOnDay(7)),
    entitlementStateProvider.overrideWithValue(
      const EntitlementState(tier: Tier.premium),
    ),
    debugUnlockAtStartProvider.overrideWithValue(true),
    recipeGenerationServiceProvider.overrideWithValue(
      DevMockGenerationService(catalogue: testCatalogue, delay: Duration.zero),
    ),
    recipeImageServiceProvider.overrideWithValue(
      PlaceholderRecipeImageService(delay: Duration.zero),
    ),
  ];

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    testWidgets('meal results: complete and partial matches, $theme', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MealResultsPage(choice: _complete),
        dark: dark,
        height: 1500,
        overrides: overrides,
      );
      await expectLater(
        find.byType(MealResultsPage),
        matchesGoldenFile('goldens/$theme-meal-results-complete.png'),
      );
    });

    testWidgets('meal results: good and partial matches, $theme', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MealResultsPage(choice: _mixed),
        dark: dark,
        height: 1700,
        overrides: overrides,
      );
      await expectLater(
        find.byType(MealResultsPage),
        matchesGoldenFile('goldens/$theme-meal-results-fallback.png'),
      );
    });

    testWidgets('meal results: no recipe, $theme', (tester) async {
      await pumpScreen(
        tester,
        MealResultsPage(choice: _empty),
        dark: dark,
        overrides: overrides,
      );
      await expectLater(
        find.byType(MealResultsPage),
        matchesGoldenFile('goldens/$theme-meal-results-empty.png'),
      );
    });

    testWidgets('create a recipe: not available here, $theme', (tester) async {
      await pumpScreen(
        tester,
        const CreateRecipePage(choice: _balanced),
        dark: dark,
        overrides: [
          cycleStateProvider.overrideWithValue(stateOnDay(7)),
          entitlementStateProvider.overrideWithValue(
            const EntitlementState(tier: Tier.premium),
          ),
        ],
      );
      await expectLater(
        find.byType(CreateRecipePage),
        matchesGoldenFile('goldens/$theme-create-recipe-failure.png'),
      );
    });

    testWidgets('3 plants a day, $theme', (tester) async {
      await pumpScreen(
        tester,
        const ThreePlantsPage(),
        dark: dark,
        height: 1500,
        overrides: overrides,
      );
      await tester.tap(
        find
            .byWidgetPredicate((w) => w.key.toString().contains("'plant-"))
            .first,
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ThreePlantsPage),
        matchesGoldenFile('goldens/$theme-three-plants.png'),
      );
    });

    testWidgets('diary with entries, $theme', (tester) async {
      final db = testDatabase();
      await tester.runAsync(() async {
        final repo = DiaryRepository(db);
        final today = LocalDate(2025, 10, 4);
        Future<void> add(String id, String title, DiaryMeal m, double a) =>
            repo.add(
              DiaryDraft(
                date: today,
                meal: m,
                kind: DiaryItemKind.food,
                itemId: id,
                title: title,
                amount: a,
                unit: DiaryUnit.serving,
              ),
            );
        await add('oat', 'Oats', DiaryMeal.breakfast, 1);
        await add('salmon', 'Salmon', DiaryMeal.dinner, 1.5);
        await add('spinach', 'Spinach', DiaryMeal.dinner, 1);
        await repo.add(
          DiaryDraft(
            date: today.addDays(-1),
            meal: DiaryMeal.lunch,
            kind: DiaryItemKind.recipe,
            itemId: 'lentil-spinach-tomato-stew',
            title: 'Lentil, Spinach & Tomato Stew',
            amount: 1,
            unit: DiaryUnit.serving,
          ),
        );
      });
      await pumpScreen(
        tester,
        const DiaryPage(),
        dark: dark,
        height: 1300,
        database: db,
        overrides: overrides,
      );
      await expectLater(
        find.byType(DiaryPage),
        matchesGoldenFile('goldens/$theme-diary.png'),
      );
    });

    testWidgets('my recipes, empty, $theme', (tester) async {
      await pumpScreen(
        tester,
        const MyRecipesPage(),
        dark: dark,
        overrides: overrides,
      );
      await expectLater(
        find.byType(MyRecipesPage),
        matchesGoldenFile('goldens/$theme-my-recipes-empty.png'),
      );
    });
  }

  testWidgets('narrow phone at large text: results, diary, try new', (
    tester,
  ) async {
    for (final (name, page, h) in [
      ('meal-results', MealResultsPage(choice: _mixed), 2600.0),
      ('diary', const DiaryPage(), 1400.0),
      ('three-plants', const ThreePlantsPage(), 1800.0),
    ]) {
      await pumpScreen(
        tester,
        page,
        dark: false,
        width: 320,
        textScale: 1.5,
        height: h,
        overrides: overrides,
      );
      expect(tester.takeException(), isNull, reason: name);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/light-$name-narrow-large-text.png'),
      );
    }
  });
}
