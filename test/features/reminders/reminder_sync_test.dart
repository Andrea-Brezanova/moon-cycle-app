import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/storage/ui_prefs.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/preferences/domain/reminder_settings.dart';
import 'package:moon_cycle/features/privacy/data/local_data_wiper.dart';
import 'package:moon_cycle/features/reminders/application/reminder_providers.dart';
import 'package:moon_cycle/features/reminders/domain/reminder_copy.dart';
import 'package:moon_cycle/features/reminders/domain/reminder_plan.dart';

import '../../helpers/fake_reminders.dart';
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  // `todayProvider` listens to the app lifecycle.
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeReminderScheduler scheduler;
  late ProviderContainer container;

  setUp(() async {
    db = testDatabase();
    scheduler = FakeReminderScheduler();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(designNow),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    final cycles = CycleRepository(db);
    await cycles.saveProfile(
      const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
    );
    await cycles.logPeriod(sampleStart);
    container.listen(reminderSyncProvider, (_, _) {}, fireImmediately: true);
  });

  /// Lets the database streams and the sync run.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('off by default: nothing scheduled', () async {
    await settle();
    expect(scheduler.scheduled, isEmpty);
  });

  test('turning reminders on schedules the plan; off cancels it', () async {
    final prefs = PreferencesRepository(db);
    await prefs.saveReminders(const ReminderSettings(enabled: true));
    await settle();
    expect(scheduler.scheduled, hasLength(18));
    expect(scheduler.scheduled.first.kind, ReminderKind.phaseStart);

    await prefs.saveReminders(const ReminderSettings());
    await settle();
    expect(scheduler.scheduled, isEmpty);
  });

  test('the schedule is recomputed after a period is logged', () async {
    await PreferencesRepository(db)
        .saveReminders(const ReminderSettings(enabled: true));
    await settle();
    final before = scheduler.scheduled;
    // A new period today: day 1 again.
    await CycleRepository(db).logPeriod(sampleStart.addDays(6));
    await settle();
    expect(scheduler.scheduled, isNot(before));
    expect(
      scheduler.scheduled.first.date,
      sampleStart.addDays(6 + 5), // follicular starts on day 6
    );
  });

  test('unchanged data doesn’t reschedule', () async {
    await PreferencesRepository(db)
        .saveReminders(const ReminderSettings(enabled: true));
    await settle();
    final calls = scheduler.replaceCalls;
    // Saving the same settings again emits the same plan.
    await PreferencesRepository(db)
        .saveReminders(const ReminderSettings(enabled: true));
    await settle();
    expect(scheduler.replaceCalls, calls);
  });

  test('Delete my data cancels every reminder', () async {
    for (final step in container.read(wipeStepsProvider)) {
      await step();
    }
    expect(scheduler.cancelCalls, 1);
  });

  group('discreet by default, detailed only by choice', () {
    test('scheduled reminders are neutral until the user opts in', () async {
      await PreferencesRepository(db)
          .saveReminders(const ReminderSettings(enabled: true));
      await settle();
      expect(scheduler.scheduled, hasLength(18));
      for (final r in scheduler.scheduled) {
        expect(r.detailed, isFalse);
        expect(reminderText(r), discreetReminderText);
      }
    });

    test('opting in reschedules the same reminders with details', () async {
      await PreferencesRepository(db)
          .saveReminders(const ReminderSettings(enabled: true));
      await settle();
      final ids = scheduler.scheduled.map((r) => r.id).toList();
      final dates = scheduler.scheduled.map((r) => r.date).toList();

      await container
          .read(uiPrefsProvider.notifier)
          .update(const UiPrefs(detailedReminders: true));
      await settle();
      expect(scheduler.scheduled.map((r) => r.id), ids);
      expect(scheduler.scheduled.map((r) => r.date), dates);
      expect(scheduler.scheduled.every((r) => r.detailed), isTrue);
      expect(
        scheduler.scheduled.map((r) => reminderText(r)),
        isNot(contains(discreetReminderText)),
      );

      // And back: the choice can be undone, nothing is lost.
      await container.read(uiPrefsProvider.notifier).update(const UiPrefs());
      await settle();
      expect(scheduler.scheduled, hasLength(18));
      expect(scheduler.scheduled.every((r) => !r.detailed), isTrue);
    });

    test('with reminders off, changing the detail schedules nothing', () async {
      await settle();
      expect(scheduler.scheduled, isEmpty);
      await container
          .read(uiPrefsProvider.notifier)
          .update(const UiPrefs(detailedReminders: true));
      await settle();
      expect(scheduler.scheduled, isEmpty);
    });

    test('turning reminders off and on keeps the detail choice', () async {
      final prefs = PreferencesRepository(db);
      await container
          .read(uiPrefsProvider.notifier)
          .update(const UiPrefs(detailedReminders: true));
      await prefs.saveReminders(const ReminderSettings(enabled: true));
      await settle();
      expect(scheduler.scheduled.every((r) => r.detailed), isTrue);
      await prefs.saveReminders(const ReminderSettings());
      await settle();
      expect(scheduler.scheduled, isEmpty);
      await prefs.saveReminders(const ReminderSettings(enabled: true));
      await settle();
      expect(scheduler.scheduled.every((r) => r.detailed), isTrue);
    });

    test('the choice does not touch the saved reminder settings', () async {
      final prefs = PreferencesRepository(db);
      const saved = ReminderSettings(enabled: true, beforePeriod: false);
      await prefs.saveReminders(saved);
      await container
          .read(uiPrefsProvider.notifier)
          .update(const UiPrefs(detailedReminders: true));
      await settle();
      expect(await prefs.watchReminders().first, saved);
    });
  });
}
