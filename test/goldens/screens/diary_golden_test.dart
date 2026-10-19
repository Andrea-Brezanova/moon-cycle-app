@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/data/symptom_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/domain/symptoms.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
import 'package:moon_cycle/features/diary/presentation/log_symptoms_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import '../../helpers/pump_app.dart';
import 'home_golden_test.dart' show stateOnDay;

/// My Diary and its two forms, populated and empty, in light and dark. Day 7
/// of the cycle (follicular) on Saturday 4 October 2025, the design's sample
/// day. Premium, so the screens are open.
void main() {
  setUpAll(loadMoonFonts);

  final today = LocalDate(2025, 10, 4);
  final overrides = [
    cycleStateProvider.overrideWithValue(stateOnDay(7)),
    entitlementStateProvider.overrideWithValue(
      const EntitlementState(tier: Tier.premium),
    ),
  ];

  Future<AppDatabase> populated(WidgetTester tester) async {
    final db = testDatabase();
    await tester.runAsync<void>(() async {
      final meals = DiaryRepository(db);
      Future<void> add(
        String id,
        String title,
        DiaryMeal m,
        DiaryItemKind k, {
        String? note,
      }) => meals.add(
        DiaryDraft(
          date: today,
          meal: m,
          kind: k,
          itemId: id,
          title: title,
          amount: 1,
          unit: DiaryUnit.serving,
          note: note,
        ),
      );
      await add('oat', 'Oats', DiaryMeal.breakfast, DiaryItemKind.food);
      await add(
        'lentil-spinach-tomato-stew',
        'Lentil, Spinach & Tomato Stew',
        DiaryMeal.dinner,
        DiaryItemKind.recipe,
      );
      await add(
        '',
        'Grandma’s soup',
        DiaryMeal.dinner,
        DiaryItemKind.custom,
        note: 'With bread',
      );
      final symptoms = SymptomRepository(db);
      await symptoms.saveDay(
        SymptomDay(
          date: today,
          energy: EnergyLevel.good,
          sleep: SleepQuality.okay,
          moods: {Mood.calm, Mood.motivated},
          body: {BodySymptom.bloating: Strength.mild, BodySymptom.cramps: null},
          note: 'Felt lighter after a walk.',
        ),
      );
      await symptoms.saveDay(
        SymptomDay(
          date: today.addDays(-1),
          energy: EnergyLevel.low,
          body: {BodySymptom.cramps: Strength.mild},
          sleep: SleepQuality.restless,
        ),
      );
    });
    return db;
  }

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testWidgets('diary meals, populated, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryPage(),
        dark: dark,
        height: 1300,
        database: await populated(tester),
        overrides: overrides,
      );
      await expectLater(
        find.byType(DiaryPage),
        matchesGoldenFile('goldens/$theme-diary-meals-populated.png'),
      );
    });

    testWidgets('diary meals, empty, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryPage(),
        dark: dark,
        overrides: overrides,
      );
      await expectLater(
        find.byType(DiaryPage),
        matchesGoldenFile('goldens/$theme-diary-meals-empty.png'),
      );
    });

    testWidgets('diary symptoms, populated, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryPage(initialSymptoms: true),
        dark: dark,
        height: 1300,
        database: await populated(tester),
        overrides: overrides,
      );
      await expectLater(
        find.byType(DiaryPage),
        matchesGoldenFile('goldens/$theme-diary-symptoms-populated.png'),
      );
    });

    testWidgets('diary symptoms, empty, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryPage(initialSymptoms: true),
        dark: dark,
        overrides: overrides,
      );
      await expectLater(
        find.byType(DiaryPage),
        matchesGoldenFile('goldens/$theme-diary-symptoms-empty.png'),
      );
    });

    testWidgets('log a meal, $theme', (tester) async {
      await pumpScreen(
        tester,
        const LogMealPage(
          kind: DiaryItemKind.recipe,
          itemId: 'lentil-spinach-tomato-stew',
          title: 'Lentil, Spinach & Tomato Stew',
          from: 'recipe',
        ),
        dark: dark,
        overrides: overrides,
      );
      await expectLater(
        find.byType(LogMealPage),
        matchesGoldenFile('goldens/$theme-log-meal.png'),
      );
    });

    testWidgets('log symptoms, with strength panels, $theme', (tester) async {
      await pumpScreen(
        tester,
        const LogSymptomsPage(),
        dark: dark,
        height: 1700,
        overrides: overrides,
      );
      for (final l in ['Calm', 'Motivated', 'Bleeding', 'Bloating']) {
        await tester.tap(find.text(l));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(LogSymptomsPage),
        matchesGoldenFile('goldens/$theme-log-symptoms.png'),
      );
    });
  }

  testWidgets('log symptoms, 320 pt at 1.5× text, light', (tester) async {
    await pumpScreen(
      tester,
      const LogSymptomsPage(),
      dark: false,
      width: 320,
      height: 1800,
      textScale: 1.5,
      overrides: overrides,
    );
    await tester.tap(find.text('Bloating'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LogSymptomsPage),
      matchesGoldenFile('goldens/light-log-symptoms-narrow-large-text.png'),
    );
  });
}
