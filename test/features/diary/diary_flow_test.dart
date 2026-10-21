import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
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
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool premium = true,
  }) async {
    tester.view.physicalSize = const Size(390, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow), // 4 Oct 2025, 09:00
        if (premium)
          entitlementStateProvider.overrideWithValue(
            const EntitlementState(tier: Tier.premium),
          ),
      ],
    );
    c.read(appRouterProvider).go(Routes.diary);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).last;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('the basic diary is free: a free user can open and log', (
    tester,
  ) async {
    final c = await pump(tester, premium: false);
    expect(find.text('Log Diary is part of Moon Cycle Premium.'), findsNothing);
    expect(find.text('+ Log a meal'), findsOneWidget);
    await tapText(tester, '+ Log a meal');
    expect(find.byType(LogMealPage), findsOneWidget);
    await tapText(tester, 'Cancel');
    await tapText(tester, 'Symptoms');
    await tapText(tester, '+ Log symptoms');
    expect(find.byType(LogSymptomsPage), findsOneWidget);
    expect(c, isNotNull);
  });

  testWidgets('an empty day offers Log a meal; saving lands on the diary '
      'with the entry shown', (tester) async {
    final c = await pump(tester);
    expect(find.byType(DiaryPage), findsOneWidget);
    expect(find.text('My Diary'), findsOneWidget);
    expect(find.byKey(const ValueKey('diary-empty')), findsOneWidget);

    await tapText(tester, '+ Log a meal');
    expect(find.byType(LogMealPage), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, 'Salm');
    await tester.pumpAndSettle();
    await tapText(tester, 'Salmon');
    await tapText(tester, 'Dinner');
    await tapText(tester, 'Save to diary');

    // Back on My Diary, refreshed, with confirmation. Not stuck on the form.
    expect(find.byType(LogMealPage), findsNothing);
    expect(find.byType(DiaryPage), findsOneWidget);
    expect(find.text('Added to your diary'), findsOneWidget);
    expect(find.byKey(const ValueKey('diary-empty')), findsNothing);
    expect(find.text('Salmon'), findsOneWidget);
    final all = await c.read(diaryRepositoryProvider).all();
    expect(all.single.meal, DiaryMeal.dinner);
    expect(all.single.itemId, 'salmon');
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Cancel closes without saving', (tester) async {
    final c = await pump(tester);
    await tapText(tester, '+ Log a meal');
    await tester.enterText(find.byType(EditableText).first, 'Salm');
    await tester.pumpAndSettle();
    await tapText(tester, 'Salmon');
    await tapText(tester, 'Cancel');
    expect(find.byType(DiaryPage), findsOneWidget);
    expect(await c.read(diaryRepositoryProvider).all(), isEmpty);
  });

  testWidgets('your own meal: no food id, a note, never merged', (
    tester,
  ) async {
    final c = await pump(tester);
    await tapText(tester, '+ Log a meal');
    await tester.enterText(find.byType(EditableText).first, 'Grandma soup');
    await tester.pumpAndSettle();
    await tapText(tester, 'Or add “Grandma soup” as your own meal');
    expect(find.text('Your own meal'), findsWidgets);
    await tester.enterText(find.byType(EditableText).last, 'With bread');
    await tester.pumpAndSettle();
    await tapText(tester, 'Save to diary');
    final e = (await c.read(diaryRepositoryProvider).all()).single;
    expect(e.kind, DiaryItemKind.custom);
    expect(e.title, 'Grandma soup');
    expect(e.note, 'With bread');
    expect(find.text('Your own meal'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('edit an entry (meal and note), then delete with confirmation', (
    tester,
  ) async {
    final c = await pump(tester);
    await tester.runAsync(
      () => c
          .read(diaryRepositoryProvider)
          .add(
            DiaryDraft(
              date: c.read(todayProvider),
              meal: DiaryMeal.breakfast,
              kind: DiaryItemKind.food,
              itemId: 'apple',
              title: 'Apple',
              amount: 1.5,
              unit: DiaryUnit.cup,
            ),
          ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Apple');
    expect(find.text('Edit meal'), findsOneWidget);
    await tapText(tester, 'Lunch');
    await tester.enterText(find.byType(EditableText).last, 'Crisp');
    await tester.pumpAndSettle();
    await tapText(tester, 'Save changes');
    final e = (await c.read(diaryRepositoryProvider).all()).single;
    expect(e.meal, DiaryMeal.lunch);
    expect(e.note, 'Crisp');
    // Amount and unit are kept as stored.
    expect(e.amount, 1.5);
    expect(e.unit, DiaryUnit.cup);
    await tester.pump(const Duration(seconds: 6));

    await tapText(tester, 'Apple');
    await tapText(tester, 'Delete entry');
    expect(find.text('Delete this entry?'), findsOneWidget);
    await tapText(tester, 'Keep entry');
    expect(await c.read(diaryRepositoryProvider).all(), hasLength(1));
    await tapText(tester, 'Delete entry');
    await tapText(tester, 'Delete entry');
    expect(await c.read(diaryRepositoryProvider).all(), isEmpty);
    expect(find.byKey(const ValueKey('diary-empty')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Food detail "Log meal" opens the form with the food added; '
      'saving returns to the food', (tester) async {
    final c = await pump(tester);
    c.read(appRouterProvider).go(Routes.food('broccoli'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Log meal');
    expect(find.byType(LogMealPage), findsOneWidget);
    expect(find.text('Food · added from the food page'), findsOneWidget);
    await tapText(tester, 'Save to diary');
    expect(find.byType(LogMealPage), findsNothing);
    expect(find.text('Added to your diary'), findsOneWidget);
    final entries = await c.read(diaryRepositoryProvider).all();
    expect(entries.single.itemId, 'broccoli');
    expect(entries.single.kind, DiaryItemKind.food);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets(
    'the toast\'s View opens My Diary on the saved day with the entry',
    (tester) async {
      final c = await pump(tester);
      c.read(appRouterProvider).go(Routes.food('broccoli'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Log meal');
      await tapText(tester, 'Save to diary');
      expect(find.text('Added to your diary'), findsOneWidget);
      await tapText(tester, 'View');
      expect(find.byType(DiaryPage), findsOneWidget);
      expect(find.text('Broccoli'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets('Recipe detail "Log meal" opens the form with the recipe', (
    tester,
  ) async {
    final c = await pump(tester);
    c.read(appRouterProvider).go(Routes.recipe('lentil-spinach-tomato-stew'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Log meal');
    expect(find.text('Recipe · added from the recipe page'), findsOneWidget);
    await tapText(tester, 'Save to diary');
    final all = await c.read(diaryRepositoryProvider).all();
    expect(all.single.kind, DiaryItemKind.recipe);
    expect(all.single.itemId, 'lentil-spinach-tomato-stew');
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('history: another day shows its own entries, Next is off today', (
    tester,
  ) async {
    final c = await pump(tester);
    final yesterday = c.read(todayProvider).addDays(-1);
    await tester.runAsync(
      () => c
          .read(diaryRepositoryProvider)
          .add(
            DiaryDraft(
              date: yesterday,
              meal: DiaryMeal.lunch,
              kind: DiaryItemKind.food,
              itemId: 'lentils',
              title: 'Lentils',
              amount: 2,
              unit: DiaryUnit.serving,
            ),
          ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lentils'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Previous day').first);
    await tester.pumpAndSettle();
    expect(find.text('Lentils'), findsOneWidget);
    expect(find.textContaining('Today ·'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Next day').first);
    await tester.pumpAndSettle();
    expect(find.text('Lentils'), findsNothing);
    expect(find.textContaining('Today ·'), findsOneWidget);
  });

  testWidgets('choice options stay the same height when one label wraps', (
    tester,
  ) async {
    final c = await pump(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    unawaited(c.read(appRouterProvider).push(Routes.logSymptoms()));
    await tester.pumpAndSettle();
    final heights = {
      for (final l in ['Very low', 'Low', 'Okay', 'Good', 'High'])
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text(l).first,
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .height,
    };
    expect(heights, hasLength(1));
    await tester.pump(const Duration(seconds: 6));
  });

  group('symptoms', () {
    testWidgets('empty state, then save a check-in and see it', (tester) async {
      final c = await pump(tester);
      await tapText(tester, 'Symptoms');
      expect(find.byKey(const ValueKey('symptoms-empty')), findsOneWidget);
      await tapText(tester, '+ Log symptoms');
      expect(find.byType(LogSymptomsPage), findsOneWidget);
      await tapText(tester, 'High'); // energy (only Energy has "High")
      await tapText(tester, 'Calm');
      await tapText(tester, 'Great'); // sleep (only Sleep has "Great")
      await tapText(tester, 'Save');
      expect(find.byType(LogSymptomsPage), findsNothing);
      expect(find.text('Check-in saved'), findsOneWidget);
      expect(find.text('Today’s check-in'), findsOneWidget);
      final d = (await c
          .read(symptomRepositoryProvider)
          .day(c.read(todayProvider)))!;
      expect(d.energy, EnergyLevel.high);
      expect(d.sleep, SleepQuality.great);
      expect(d.moods, {Mood.calm});
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a strength panel exists only while its symptom is chosen', (
      tester,
    ) async {
      await pump(tester);
      await tapText(tester, 'Symptoms');
      await tapText(tester, '+ Log symptoms');
      final bloating = find.byKey(const ValueKey('strength-bloating'));
      final bleeding = find.byKey(const ValueKey('strength-bleeding'));
      expect(bloating, findsNothing);

      await tapText(tester, 'Bloating');
      expect(bloating, findsOneWidget);
      expect(find.text('Bloating · how strong?'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);

      await tapText(tester, 'Bleeding');
      expect(bleeding, findsOneWidget);
      expect(find.text('Bleeding · how heavy?'), findsOneWidget);
      for (final l in ['Spotting', 'Light', 'Medium', 'Heavy']) {
        expect(find.text(l), findsWidgets);
      }
      // Panels follow the chip order (Bleeding before Bloating).
      expect(
        tester.getTopLeft(bleeding).dy,
        lessThan(tester.getTopLeft(bloating).dy),
      );

      await tapText(tester, 'Bloating'); // deselect: its panel goes
      expect(bloating, findsNothing);
      expect(bleeding, findsOneWidget);
    });

    testWidgets('strength is optional, can be set, changed and cleared, and a '
        'deselected symptom loses its value', (tester) async {
      final c = await pump(tester);
      await tapText(tester, 'Symptoms');
      await tapText(tester, '+ Log symptoms');
      await tapText(tester, 'Bloating');
      await tapText(tester, 'Mild');
      await tapText(tester, 'Strong'); // changes it
      await tapText(tester, 'Strong'); // tapping again clears it
      await tapText(tester, 'Cramps');
      await tapText(tester, 'Cramps'); // off again
      await tapText(tester, 'Save');
      final d = (await c
          .read(symptomRepositoryProvider)
          .day(c.read(todayProvider)))!;
      expect(d.body.keys, [BodySymptom.bloating]);
      expect(d.body[BodySymptom.bloating], isNull);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('editing starts from the saved answers', (tester) async {
      final c = await pump(tester);
      final today = c.read(todayProvider);
      await tester.runAsync(
        () => c
            .read(symptomRepositoryProvider)
            .saveDay(
              SymptomDay(
                date: today,
                energy: EnergyLevel.low,
                body: {BodySymptom.cramps: Strength.mild},
                note: 'Tired',
              ),
            ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Symptoms');
      expect(find.text('Cramps · mild'), findsOneWidget);
      await tapText(tester, 'Edit');
      expect(find.byKey(const ValueKey('strength-cramps')), findsOneWidget);
      await tapText(tester, 'High'); // energy low -> high
      await tapText(tester, 'Save');
      final d = (await c.read(symptomRepositoryProvider).day(today))!;
      expect(d.energy, EnergyLevel.high);
      expect(d.body[BodySymptom.cramps], Strength.mild); // kept
      expect(d.note, 'Tired'); // kept
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('earlier days appear in "Earlier this week" and open', (
      tester,
    ) async {
      final c = await pump(tester);
      final earlier = c.read(todayProvider).addDays(-2);
      await tester.runAsync(
        () => c
            .read(symptomRepositoryProvider)
            .saveDay(
              SymptomDay(
                date: earlier,
                energy: EnergyLevel.low,
                sleep: SleepQuality.restless,
              ),
            ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Symptoms');
      expect(find.text('EARLIER THIS WEEK'), findsOneWidget);
      expect(find.text('Energy low · Sleep restless'), findsOneWidget);
      await tapText(tester, 'Energy low · Sleep restless');
      expect(find.text('Check-in'), findsOneWidget); // not "Today's"
    });
  });
}
