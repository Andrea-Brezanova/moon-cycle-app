import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/preferences/application/preference_providers.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/preferences/domain/reminder_settings.dart';
import 'package:moon_cycle/features/reminders/domain/reminder_plan.dart';

import '../../helpers/fake_reminders.dart';
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';
import '../../helpers/test_catalogue.dart';

void main() {
  /// The app on the design's sample day, on the Settings tab.
  Future<(ProviderContainer, AppDatabase)> pumpSettings(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? seed,
    FakeReminderScheduler? reminders,
  }) async {
    tester.view.physicalSize = const Size(390, 1300) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(
      tester,
      db,
      start: sampleStart,
      more: seed == null ? null : () => seed(db),
    );
    final container = await pumpApp(
      tester,
      database: db,
      reminders: reminders,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    return (container, db);
  }

  Future<void> open(WidgetTester tester, String row) async {
    await tester.ensureVisible(find.text(row));
    await tester.pumpAndSettle();
    await tester.tap(find.text(row));
    await tester.pumpAndSettle();
  }

  /// Taps in fake time, then lets the write and its streams finish.
  Future<void> tapAndSave(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the root rows summarise each setting', (tester) async {
    await pumpSettings(
      tester,
      seed: (db) async {
        final prefs = PreferencesRepository(db);
        await prefs.avoidAllergen('peanut');
        await prefs.avoidAllergen('shellfish');
      },
    );
    expect(
      find.text('28-day cycle · 5-day period · Next period 26 Oct'),
      findsOneWidget,
    );
    expect(find.text('Omnivore'), findsOneWidget);
    expect(find.text('Peanuts, shellfish'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget); // reminders start off
    expect(find.text('Free at launch'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing); // no accounts in v1
  });

  group('My Cycle', () {
    testWidgets('the next period, the values and the history', (tester) async {
      await pumpSettings(tester);
      await open(tester, 'My Cycle');
      expect(find.text('Sunday 26 October'), findsOneWidget);
      expect(find.text('In 22 days · Ovulatory in 5 days'), findsOneWidget);
      expect(find.text('Sun 28 Sep'), findsOneWidget);
      expect(find.text('28 days'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('current cycle'), findsOneWidget);
      expect(find.textContaining('Average of'), findsNothing);
    });

    testWidgets('changing the cycle length updates the cycle everywhere', (
      tester,
    ) async {
      final (container, _) = await pumpSettings(tester);
      await open(tester, 'My Cycle');
      await open(tester, 'Cycle length');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.bySemanticsLabel('Increase cycle length'));
        await tester.pumpAndSettle();
      }
      await tapAndSave(tester, find.text('Save'));
      expect(container.read(cycleStateProvider).value!.lengths.cycleLength, 30);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('Sunday 28 October'), findsNothing);
      expect(find.text('Tuesday 28 October'), findsOneWidget);
    });

    testWidgets('a history row edits that period’s length', (tester) async {
      final (_, db) = await pumpSettings(tester);
      await open(tester, 'My Cycle');
      await open(tester, '28 Sep');
      expect(find.text('Edit period'.toUpperCase()), findsOneWidget);
      await tester.ensureVisible(
        find.bySemanticsLabel('Increase period length'),
      );
      await tester.tap(find.bySemanticsLabel('Increase period length'));
      await tester.pumpAndSettle();
      await tapAndSave(tester, find.text('Save'));
      expect(find.text('28 Sep – 3 Oct'), findsOneWidget);
      expect(find.text('6 days · current cycle'), findsOneWidget);
      final logs = await tester.runAsync(
        () => CycleRepository(db).periodLogs(),
      );
      expect(logs!.single.end, sampleStart.addDays(5));
    });

    testWidgets('three logged cycles: averages, with the designed subtitle', (
      tester,
    ) async {
      final (container, _) = await pumpSettings(
        tester,
        seed: (db) async {
          final cycles = CycleRepository(db);
          for (final back in [30, 60, 90]) {
            await cycles.logPeriod(sampleStart.addDays(-back));
          }
        },
      );
      await open(tester, 'My Cycle');
      expect(find.text('Average of your last 3 cycles'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('30-day cycle'), findsNWidgets(3));
      expect(container.read(cycleStateProvider).value!.lengths.cycleLength, 30);
    });
  });

  testWidgets('Food Preferences: a diet is saved on tap and filters foods', (
    tester,
  ) async {
    final (container, _) = await pumpSettings(tester);
    await open(tester, 'Food Preferences');
    expect(find.text('No animal foods'), findsOneWidget);
    await tapAndSave(tester, find.text('Vegan').first);
    expect(container.read(dietProvider).value, Diet.vegan);
    final chicken = testCatalogue.food('chicken')!;
    expect(container.read(foodFilterProvider).allowsFood(chicken), isFalse);
  });

  group('Allergies', () {
    testWidgets('allergen chips save and remove', (tester) async {
      final (container, _) = await pumpSettings(tester);
      await open(tester, 'Allergies / Foods to Avoid');
      await tapAndSave(tester, find.text('Peanuts'));
      expect(container.read(avoidancesProvider).value, [
        isA<AllergenAvoidance>(),
      ]);
      await tapAndSave(tester, find.text('Peanuts'));
      expect(container.read(avoidancesProvider).value, isEmpty);
    });

    testWidgets('specific foods show as removable chips', (tester) async {
      final (container, _) = await pumpSettings(
        tester,
        seed: (db) async {
          await PreferencesRepository(db).avoidFood('chicken');
          await PreferencesRepository(db).avoidCustom('Coriander');
        },
      );
      await open(tester, 'Allergies / Foods to Avoid');
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Coriander'), findsOneWidget);
      await tapAndSave(tester, find.bySemanticsLabel('Remove chicken'));
      expect(container.read(avoidancesProvider).value, [
        isA<CustomAvoidance>(),
      ]);
    });

    testWidgets('the search opens the food search sheet', (tester) async {
      final (container, _) = await pumpSettings(tester);
      await open(tester, 'Allergies / Foods to Avoid');
      await open(tester, 'Search foods to avoid');
      await tester.enterText(find.byType(EditableText), 'chicken');
      await tester.pumpAndSettle();
      await tapAndSave(tester, find.text('Chicken').last);
      expect(container.read(avoidancesProvider).value, [
        isA<FoodItemAvoidance>(),
      ]);
    });
  });

  testWidgets('Notifications: switches are saved; details need reminders on', (
    tester,
  ) async {
    final reminders = FakeReminderScheduler();
    final (container, _) = await pumpSettings(tester, reminders: reminders);
    await open(tester, 'Notifications');
    // Off: the detail switches can't be changed.
    await tapAndSave(tester, find.text('Before your period'));
    expect(
      container.read(reminderSettingsProvider).value,
      const ReminderSettings(),
    );
    await tapAndSave(tester, find.text('Reminders'));
    await tapAndSave(tester, find.text('Before your period'));
    expect(
      container.read(reminderSettingsProvider).value,
      const ReminderSettings(enabled: true, beforePeriod: false),
    );
    expect(reminders.permissionRequests, 1);
    // The phase reminders for the next three cycles are scheduled.
    expect(reminders.scheduled, isNotEmpty);
    expect(
      reminders.scheduled.every((r) => r.kind == ReminderKind.phaseStart),
      isTrue,
    );
  });

  testWidgets('Notifications: permission refused keeps reminders off', (
    tester,
  ) async {
    final reminders = FakeReminderScheduler(permission: false);
    final (container, _) = await pumpSettings(tester, reminders: reminders);
    await open(tester, 'Notifications');
    await tapAndSave(tester, find.text('Reminders'));
    expect(
      container.read(reminderSettingsProvider).value,
      const ReminderSettings(),
    );
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(reminders.scheduled, isEmpty);
  });

  testWidgets('Subscription: the launch promo, with the date placeholder', (
    tester,
  ) async {
    await pumpSettings(tester);
    await open(tester, 'Subscription');
    expect(
      find.text('Free at launch · until [launch-free end date]'),
      findsOneWidget,
    );
  });

  testWidgets('Help: questions open in place', (tester) async {
    await pumpSettings(tester);
    // Clear of the tab bar.
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await open(tester, 'Help');
    expect(find.textContaining('Ovulation is estimated'), findsOneWidget);
    expect(find.textContaining('Your data lives on this phone'), findsNothing);
    await open(tester, 'Where is my data stored?');
    expect(
      find.textContaining('Your data lives on this phone'),
      findsOneWidget,
    );
    // No support address yet: the button is disabled, not broken.
    expect(find.text('Contact support'), findsOneWidget);
  });

  testWidgets('Privacy & Data: the note, export and the policies', (
    tester,
  ) async {
    await pumpSettings(tester);
    await open(tester, 'Privacy & Data');
    expect(find.text('Export my data'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('How Moon Cycle uses data'), findsOneWidget);
  });
}
