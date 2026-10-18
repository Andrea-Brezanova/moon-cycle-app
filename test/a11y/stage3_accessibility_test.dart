import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';

import '../helpers/golden_screen.dart';
import '../helpers/pump_app.dart';
import '../helpers/seed.dart';
import '../helpers/test_catalogue.dart';

/// The screens added in Stages 3–7, reached as a Premium user in a debug dev
/// build (so every one of them is on screen, not a lock message).
final _screens = <String, String>{
  'meal results (complete and partial)': Routes.mealResults([
    'quinoa',
    'orange',
    'salmon',
  ]),
  'meal results (one food)': Routes.mealResults(['garlic']),
  'meal results (no recipe)': Routes.mealResults(['kombu', 'wakame']),
  '3 plants a day': Routes.threePlants,
  'diary': Routes.diary,
  'my recipes': Routes.myRecipes,
};

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    String path, {
    Size size = const Size(390, 844),
    double textScale = 1,
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
        await DiaryRepository(db).add(
          DiaryDraft(
            date: LocalDate(2025, 10, 4),
            meal: DiaryMeal.dinner,
            kind: DiaryItemKind.food,
            itemId: 'salmon',
            title: 'Salmon',
            amount: 1,
            unit: DiaryUnit.serving,
          ),
        );
      },
    );
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        entitlementStateProvider.overrideWithValue(
          const EntitlementState(tier: Tier.premium),
        ),
        debugUnlockAtStartProvider.overrideWithValue(true),
        recipeGenerationServiceProvider.overrideWithValue(
          DevMockGenerationService(
            catalogue: testCatalogue,
            delay: Duration.zero,
          ),
        ),
        recipeImageServiceProvider.overrideWithValue(
          PlaceholderRecipeImageService(delay: Duration.zero),
        ),
      ],
    );
    container.read(appRouterProvider).go(path);
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: path) in _screens.entries) {
    testWidgets('$name meets the tap-target, label and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAt(tester, path);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('$name fits a 320 pt phone at 1.5× text', (tester) async {
      await pumpAt(tester, path, size: const Size(320, 568), textScale: 1.5);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the diary entry sheet meets the guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(tester, Routes.diary);
    await tester.tap(find.text('1 serving'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
