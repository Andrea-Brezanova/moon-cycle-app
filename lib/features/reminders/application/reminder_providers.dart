import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/ui_prefs.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../preferences/application/preference_providers.dart';
import '../data/reminder_scheduler.dart';
import '../domain/reminder_plan.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalReminderScheduler(),
);

/// What should be scheduled now. Null while the data is loading.
final reminderPlanProvider = Provider<List<PlannedReminder>?>((ref) {
  final cycle = ref.watch(cycleStateProvider);
  final settings = ref.watch(reminderSettingsProvider);
  final detailed = ref.watch(
    uiPrefsProvider.select((p) => p.detailedReminders),
  );
  if (cycle.isLoading || !settings.hasValue) return null;
  final state = cycle.value;
  final s = settings.value!;
  if (state == null) return const [];
  return planReminders(
    lastPeriodStart: state.lastPeriodStart,
    lengths: state.lengths,
    today: state.today,
    settings: s,
    detailed: detailed,
  );
});

/// Keeps the scheduled reminders in step with the plan: whenever the cycle,
/// the settings or the day changes. Watched by the app root.
final reminderSyncProvider = Provider<void>((ref) {
  ref.listen<List<PlannedReminder>?>(reminderPlanProvider, (previous, next) {
    if (next == null || listEquals(previous, next)) return;
    ref
        .read(reminderSchedulerProvider)
        .replaceAll(next)
        .catchError(
          (Object e) => debugPrint('Couldn’t schedule reminders: $e'),
        );
  }, fireImmediately: true);
});
