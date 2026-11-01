import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/domain/food_profile.dart';

import '../helpers/golden_screen.dart';
import '../helpers/pump_app.dart';
import '../helpers/seed.dart';

/// Screens the other accessibility tests do not reach: Food Detail (with a
/// reviewed profile and with cautions), Foods, Build a Meal, Eat recipes, the
/// collections, and the diary sub-pages. Each must meet the tap-target, label
/// and contrast guidelines and fit a 320 pt phone at 1.5× text.
final _screens = <String, String>{
  'food detail with a profile (spinach)': Routes.food('spinach'),
  'food detail with a profile and phase (green lentil)': Routes.food(
    'green-lentil',
  ),
  'food detail without a profile': Routes.food('cucumber'),
  'foods': Routes.eatFoods,
  'eat recipes': Routes.eatRecipes,
  'build a meal': Routes.mealBuilder(),
  'build a meal seeded from a food': Routes.mealBuilder(foodId: 'spinach'),
  'collections': Routes.collections,
  'collection workouts': Routes.collectionWorkouts,
  'collection spa': Routes.collectionSpa,
  'collection routines': Routes.collectionRoutines,
  'diary entries': Routes.diaryEntries,
  'diary activities': Routes.diaryActivities,
  'diary notes': Routes.diaryNotes,
  'add a recipe': Routes.addRecipe,
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
    await seedCycle(tester, db, start: sampleStart);
    final profiles = parseFoodProfiles(
      jsonDecode(File('assets/content/food_profiles.json').readAsStringSync())
          as Map<String, Object?>,
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
        foodProfilesProvider.overrideWithValue(profiles),
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
}
