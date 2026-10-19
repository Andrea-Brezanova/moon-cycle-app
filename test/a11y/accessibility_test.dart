import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_item.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_merger.dart';

import '../helpers/golden_screen.dart';
import '../helpers/pump_app.dart';
import '../helpers/seed.dart';

/// Every screen a user can reach, as a route.
final screens = <String, String>{
  'home': AppTab.home.path,
  'eat': AppTab.eat.path,
  'move': AppTab.move.path,
  'relax': AppTab.relax.path,
  'credits': Routes.credits,
  'diary': Routes.diary,
  'recipe detail': Routes.recipe('zucchini-feta-herb-frittata'),
  'shop': Routes.shopping,
  'more': AppTab.more.path,
  for (final page in SettingsPage.values) page.segment: Routes.settings(page),
};

/// Onboarding before the reveal (the reveal needs saved answers).
final onboarding = <String, String>{
  'welcome': Routes.onboarding,
  'last period': Routes.onboardingLastPeriod,
  'cycle length': Routes.onboardingCycleLength,
  'food preferences': Routes.onboardingFoodPreferences,
};

void main() {
  Future<GoRouter> pumpAt(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool onboarded = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase();
    await seedCycle(
      tester,
      db,
      start: sampleStart,
      more: () async {
        await ShoppingRepository(db).add(
          const AddRequest(
            key: 'text:oat milk',
            name: 'Oat milk',
            aisleId: 'other',
            source: ShoppingSource(id: 's', type: SourceType.manual),
          ),
        );
      },
    );
    final container = await pumpApp(
      tester,
      onboarded: onboarded,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    return container.read(appRouterProvider);
  }

  for (final MapEntry(key: name, value: path) in {
    ...screens,
    ...onboarding,
  }.entries) {
    final onboarded = !onboarding.containsKey(name);
    testWidgets('$name meets the tap-target, label and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = await pumpAt(tester, onboarded: onboarded);
      router.go(path);
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('$name fits a 320 pt phone at 1.5× text', (tester) async {
      final router = await pumpAt(
        tester,
        size: const Size(320, 568),
        textScale: 1.5,
        onboarded: onboarded,
      );
      router.go(path);
      await tester.pumpAndSettle();
      // An overflow would have failed the test with a layout error.
      // An overflow fails the test with the widget that overflowed.
    });
  }
}
