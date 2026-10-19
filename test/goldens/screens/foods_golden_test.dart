@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/browse_scope.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/eat/presentation/eat_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/application/browse_scope.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';
import 'package:moon_cycle/features/foods/presentation/learn_more_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/shopping/application/shopping_summary.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

/// The design's list: Quinoa (a grain with no follicular recipes) is on it.
const _summary = ShoppingSummary(
  toBuy: 8,
  done: 3,
  fromRecipes: 6,
  onListFoodIds: {'farro'},
);

void main() {
  setUpAll(loadMoonFonts);

  List<Override> base() => [
    cycleStateProvider.overrideWithValue(stateOnDay(7)),
    shoppingSummaryProvider.overrideWithValue(_summary),
  ];

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    testWidgets('foods, $theme', (tester) async {
      await pumpScreen(
        tester,
        const EatPage(),
        dark: dark,
        height: 2380,
        overrides: base(),
      );
      await expectLater(
        find.byType(EatPage),
        matchesGoldenFile('goldens/$theme-foods.png'),
      );
    });

    testWidgets('foods browsing luteal, $theme', (tester) async {
      await pumpScreen(tester, const EatPage(), dark: dark, overrides: base());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EatPage)),
      );
      container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EatPage),
        matchesGoldenFile('goldens/$theme-foods-browsing.png'),
      );
    });

    testWidgets('foods all, $theme', (tester) async {
      await pumpScreen(
        tester,
        const EatPage(),
        dark: dark,
        height: 2600,
        overrides: base(),
      );
      ProviderScope.containerOf(tester.element(find.byType(EatPage)))
          .read(foodsScopeProvider.notifier)
          .set(BrowseScope.all);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EatPage),
        matchesGoldenFile('goldens/$theme-foods-all.png'),
      );
    });

    for (final (name, id, phase, general) in [
      ('detail', 'broccoli', Phase.menstrual, false),
      ('detail-on-list', 'farro', Phase.follicular, false),
      ('detail-cautions', 'kimchi', Phase.luteal, false),
      ('detail-general', 'lettuce', Phase.follicular, true),
    ]) {
      testWidgets('food $name, $theme', (tester) async {
        await pumpScreen(
          tester,
          FoodDetailPage(foodId: id, phase: phase, general: general),
          dark: dark,
          height: 1100,
          overrides: base(),
        );
        await expectLater(
          find.byType(FoodDetailPage),
          matchesGoldenFile('goldens/$theme-food-$name.png'),
        );
      });
    }

    testWidgets('build a meal (Premium), $theme', (tester) async {
      await pumpScreen(
        tester,
        const MealBuilderPage(foodId: 'broccoli'),
        dark: dark,
        height: 1700,
        overrides: [
          ...base(),
          entitlementStateProvider.overrideWithValue(
            const EntitlementState(tier: Tier.premium),
          ),
        ],
      );
      await expectLater(
        find.byType(MealBuilderPage),
        matchesGoldenFile('goldens/$theme-build-a-meal.png'),
      );
    });

    testWidgets('learn more, $theme', (tester) async {
      await pumpScreen(
        tester,
        const LearnMorePage(),
        dark: dark,
        overrides: base(),
      );
      await expectLater(
        find.byType(LearnMorePage),
        matchesGoldenFile('goldens/$theme-learn-more.png'),
      );
    });
  }

  testWidgets('food detail and build a meal, 320 pt at 1.5× text', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const FoodDetailPage(foodId: 'broccoli', phase: Phase.menstrual),
      dark: false,
      width: 320,
      height: 1500,
      textScale: 1.5,
      overrides: base(),
    );
    await expectLater(
      find.byType(FoodDetailPage),
      matchesGoldenFile('goldens/light-food-detail-narrow-large-text.png'),
    );
  });

  testWidgets('build a meal (Premium), 320 pt at 1.5× text', (tester) async {
    await pumpScreen(
      tester,
      const MealBuilderPage(foodId: 'broccoli'),
      dark: false,
      width: 320,
      height: 3800,
      textScale: 1.5,
      overrides: [
        ...base(),
        entitlementStateProvider.overrideWithValue(
          const EntitlementState(tier: Tier.premium),
        ),
      ],
    );
    await expectLater(
      find.byType(MealBuilderPage),
      matchesGoldenFile('goldens/light-build-a-meal-narrow-large-text.png'),
    );
  });

  testWidgets('foods, 320 pt at 1.5× text', (tester) async {
    await pumpScreen(
      tester,
      const EatPage(),
      dark: false,
      width: 320,
      height: 3600,
      textScale: 1.5,
      overrides: base(),
    );
    await expectLater(
      find.byType(EatPage),
      matchesGoldenFile('goldens/light-foods-narrow-large-text.png'),
    );
  });
}
