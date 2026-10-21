import 'package:moon_cycle/features/reminders/data/reminder_scheduler.dart';
import 'package:moon_cycle/features/reminders/domain/reminder_plan.dart';

/// Records what would be scheduled; permission as set.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.permission = true});

  bool permission;
  List<PlannedReminder> scheduled = const [];
  int replaceCalls = 0;
  int cancelCalls = 0;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {
    replaceCalls++;
    scheduled = plan;
  }

  @override
  Future<void> debugShowSoon(PlannedReminder reminder, Duration delay) async {}

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    scheduled = const [];
  }
}
