@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/eat/application/eat_segment.dart';
import 'package:moon_cycle/features/eat/presentation/eat_browse_page.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/shopping/application/shopping_summary.dart';
import 'package:moon_cycle/features/shopping/domain/item_key.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import '../../helpers/test_catalogue.dart';
import 'home_golden_test.dart' show stateOnDay;

class _Filter extends RecipeFilterController {
  _Filter(this.initial);

  final RecipeFilter initial;

  @override
  RecipeFilter build() => initial;
}

ShoppingSummary onList(Iterable<String> keys) => ShoppingSummary(
  toBuy: keys.length,
  done: 0,
  fromRecipes: 0,
  onListFoodIds: {for (final k in keys) k.substring(5)},
  onListKeys: keys.toSet(),
);

void main() {
  setUpAll(loadMoonFonts);

  List<Override> base([RecipeFilter filter = const RecipeFilter()]) => [
    cycleStateProvider.overrideWithValue(stateOnDay(7)),
    recipeFilterProvider.overrideWith(() => _Filter(filter)),
  ];

  final zesty = testCatalogue.recipe('zucchini-feta-herb-frittata')!;
  final lists = <String, List<Override>>{
    'recipes': base(),
    'filtered': base(const RecipeFilter(foodId: 'chicken')),
    // A meal type the phase has, but none of its recipes fit the preferences.
    'empty-meal-type': [
      ...base(const RecipeFilter(mealType: MealType.breakfast)),
      foodFilterProvider.overrideWithValue(
        const FoodFilter(
          avoidances: [
            AllergenAvoidance(id: 'a', allergenId: 'egg'),
            AllergenAvoidance(id: 'b', allergenId: 'dairy'),
          ],
        ),
      ),
    ],
    'empty-ingredient': base(
      const RecipeFilter(mealType: MealType.breakfast, foodId: 'chicken'),
    ),
    'empty-preferences': [
      ...base(),
      foodFilterProvider.overrideWithValue(
        const FoodFilter(
          avoidances: [
            AllergenAvoidance(id: 'a', allergenId: 'gluten'),
            AllergenAvoidance(id: 'c', allergenId: 'dairy'),
            AllergenAvoidance(id: 'd', allergenId: 'fish'),
            FoodItemAvoidance(id: 'b', foodId: 'chicken'),
          ],
        ),
      ),
    ],
  };

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    for (final MapEntry(key: name, value: overrides) in lists.entries) {
      testWidgets('$name, $theme', (tester) async {
        await pumpScreen(
          tester,
          const EatBrowsePage(segment: EatSegment.recipes),
          dark: dark,
          height: 1060,
          overrides: overrides,
        );
        await expectLater(
          find.byType(EatBrowsePage),
          matchesGoldenFile('goldens/$theme-recipes-$name.png'),
        );
      });
    }

    for (final (name, query) in [
      ('cook-with', ''),
      ('cook-with-no-results', 'quinoa'),
    ]) {
      testWidgets('$name, $theme', (tester) async {
        await pumpScreen(
          tester,
          const EatBrowsePage(segment: EatSegment.recipes),
          dark: dark,
          overrides: base(),
        );
        await tester.tap(
          find.bySemanticsLabel('Cook with, choose an ingredient'),
        );
        await tester.pumpAndSettle();
        if (query.isNotEmpty) {
          await tester.enterText(find.byType(TextField), query);
          await tester.pumpAndSettle();
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$theme-recipes-$name.png'),
        );
      });
    }

    for (final (name, keys) in [
      ('detail', ['food:broccoli', 'food:lemon', 'food:sauerkraut']),
      (
        'detail-added',
        [for (final l in zesty.ingredients) lineKey(l, testCatalogue)],
      ),
    ]) {
      testWidgets('$name, $theme', (tester) async {
        await pumpScreen(
          tester,
          RecipeDetailPage(recipeId: zesty.id),
          dark: dark,
          height: 1740,
          overrides: [shoppingSummaryProvider.overrideWithValue(onList(keys))],
        );
        await expectLater(
          find.byType(RecipeDetailPage),
          matchesGoldenFile('goldens/$theme-recipes-$name.png'),
        );
      });
    }
  }
}
