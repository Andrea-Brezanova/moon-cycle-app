import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/onboarding/data/app_state_repository.dart';
import 'package:moon_cycle/features/onboarding/presentation/phase_reveal_page.dart';
import 'package:moon_cycle/features/onboarding/presentation/welcome_page.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/pump_app.dart';

/// Saturday 4 October 2025, as in the design.
DateTime fixedNow() => DateTime(2025, 10, 4, 9);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

void main() {
  Future<(ProviderContainer, AppDatabase)> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    final container = await pumpApp(
      tester,
      onboarded: false,
      database: db,
      overrides: [clockProvider.overrideWithValue(fixedNow)],
    );
    expect(find.byType(WelcomePage), findsOneWidget);
    return (container, db);
  }

  testWidgets('the whole flow saves everything and opens Foods', (
    tester,
  ) async {
    final (container, db) = await start(tester);
    await tapText(tester, 'Get started');

    // Step 2: Continue waits for a date.
    expect(find.text('When did your last period start?'), findsOneWidget);
    await tapText(tester, 'Continue');
    expect(find.text('When did your last period start?'), findsOneWidget);
    await tapLabel(tester, 'Previous month');
    await tapText(tester, '28');
    expect(find.text('Day 1 · Sunday 28 September'), findsOneWidget);
    await tapText(tester, 'Continue');

    // Step 3: defaults 28 and 5; one day longer.
    expect(find.text('How long is your cycle, usually?'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await tapLabel(tester, 'Increase cycle length');
    expect(find.text('29'), findsOneWidget);
    await tapText(tester, 'Continue');

    // Step 4: vegetarian, avoid peanuts.
    expect(find.text('Anything you’d rather not eat?'), findsOneWidget);
    await tapText(tester, 'Vegetarian');
    await tapText(tester, 'Peanuts');
    await tapText(tester, 'Continue');

    // Step 5: day 7 of a 29-day cycle is follicular.
    expect(find.byType(PhaseRevealPage), findsOneWidget);
    expect(find.text('Follicular'), findsOneWidget);
    expect(find.text('Inner spring'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(
      find.text('Ovulatory in 6 days · Next period 27 October'),
      findsOneWidget,
    );

    final cycles = CycleRepository(db);
    expect(
      await tester.runAsync(cycles.profile),
      const CycleProfile(typicalCycleLength: 29, typicalPeriodLength: 5),
    );
    final log = (await tester.runAsync(cycles.periodLogs))!.single;
    expect(log.start, LocalDate(2025, 9, 28));
    expect(log.isEstimated, isFalse);
    final prefs = PreferencesRepository(db);
    expect(
      await tester.runAsync(() => prefs.watchDiet().first),
      Diet.vegetarian,
    );
    expect(
      (await tester.runAsync(prefs.avoidances))!.single,
      isA<AllergenAvoidance>().having((a) => a.allergenId, 'id', 'peanut'),
    );
    // Saved as complete, so a restart from here opens the tabs.
    expect(
      await tester.runAsync(AppStateRepository(db).isOnboardingComplete),
      isTrue,
    );

    await tapText(tester, 'See my foods');
    expect(
      find.text('Placeholder. The real screen arrives in Milestone 10.'),
      findsOneWidget,
    );
    expect(container, isNotNull);
  });

  testWidgets('"I’m not sure" uses a week ago, marked as an estimate', (
    tester,
  ) async {
    final (_, db) = await start(tester);
    await tapText(tester, 'Get started');
    await tapText(tester, 'I’m not sure');
    expect(find.text('How long is your cycle, usually?'), findsOneWidget);
    await tapText(tester, 'Continue');
    await tapText(tester, 'Skip for now');
    final log = (await tester.runAsync(CycleRepository(db).periodLogs))!.single;
    expect(log.start, LocalDate(2025, 9, 27));
    expect(log.isEstimated, isTrue);
  });

  testWidgets('"Skip for now" saves no preferences', (tester) async {
    final (_, db) = await start(tester);
    await tapText(tester, 'Get started');
    await tapText(tester, 'I’m not sure');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Vegan');
    await tapText(tester, 'Gluten');
    await tapText(tester, 'Skip for now');
    expect(find.byType(PhaseRevealPage), findsOneWidget);
    final prefs = PreferencesRepository(db);
    expect(await tester.runAsync(() => prefs.watchDiet().first), Diet.omnivore);
    expect(await tester.runAsync(prefs.avoidances), isEmpty);
  });

  testWidgets('back returns to the previous step with answers kept', (
    tester,
  ) async {
    await start(tester);
    await tapText(tester, 'Get started');
    await tapLabel(tester, 'Previous month');
    await tapText(tester, '28');
    await tapText(tester, 'Continue');
    await tapLabel(tester, 'Back');
    expect(find.text('Day 1 · Sunday 28 September'), findsOneWidget);
    await tester.binding.handlePopRoute(); // Android back
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('the reveal has no way back', (tester) async {
    await start(tester);
    await tapText(tester, 'Get started');
    await tapText(tester, 'I’m not sure');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Skip for now');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PhaseRevealPage), findsOneWidget);
  });
}
