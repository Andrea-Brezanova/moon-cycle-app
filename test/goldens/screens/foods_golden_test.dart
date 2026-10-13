@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/shopping/application/shopping_summary.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

/// The design's list: Quinoa (a grain with no follicular recipes) is on it.
const _summary = ShoppingSummary(
  toBuy: 8,
  done: 3,
  fromRecipes: 6,
  onListFoodIds: {'quinoa'},
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
        const FoodsPage(),
        dark: dark,
        height: 2380,
        overrides: base(),
      );
      await expectLater(
        find.byType(FoodsPage),
        matchesGoldenFile('goldens/$theme-foods.png'),
      );
    });

    testWidgets('foods browsing luteal, $theme', (tester) async {
      await pumpScreen(
        tester,
        const FoodsPage(),
        dark: dark,
        overrides: base(),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FoodsPage)),
      );
      container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(FoodsPage),
        matchesGoldenFile('goldens/$theme-foods-browsing.png'),
      );
    });

    testWidgets('foods sheet with cautions, $theme', (tester) async {
      await pumpScreen(
        tester,
        const FoodsPage(),
        dark: dark,
        overrides: base(),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FoodsPage)),
      );
      container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Kimchi'), 200);
      await tester.tap(find.text('Kimchi'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$theme-foods-sheet-cautions.png'),
      );
    });

    for (final (food, name) in [
      ('Chicken', 'sheet'),
      ('Quinoa', 'sheet-on-list'),
    ]) {
      testWidgets('foods $name, $theme', (tester) async {
        await pumpScreen(
          tester,
          const FoodsPage(),
          dark: dark,
          overrides: base(),
        );
        await tester.scrollUntilVisible(find.text(food), 200);
        await tester.tap(find.text(food));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$theme-foods-$name.png'),
        );
      });
    }
  }
}
