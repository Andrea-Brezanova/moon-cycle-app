import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../cycle/domain/cycle_lengths.dart';
import '../../cycle/domain/phase_ranges.dart';
import '../../preferences/domain/reminder_settings.dart';

/// "Before your period": two days before it's due (spec, Notifications).
const periodReminderDaysBefore = 2;

/// Reminders arrive at 9:00 local time ("on the morning of each new phase").
const reminderHour = 9;

/// How many cycles ahead are scheduled. Three cycles stay far below iOS's
/// limit of 64 pending notifications, and the plan is redone every day the
/// app is opened and whenever the cycle data changes.
const reminderCyclesAhead = 3;

enum ReminderKind {
  /// A phase is estimated to start today.
  phaseStart,

  /// The period is estimated to be due in [periodReminderDaysBefore] days.
  periodSoon,
}

/// One reminder to deliver at [reminderHour] on [date].
final class PlannedReminder {
  const PlannedReminder({
    required this.date,
    required this.kind,
    required this.phase,
    required this.periodDue,
    this.detailed = false,
  });

  final LocalDate date;
  final ReminderKind kind;

  /// The phase that starts ([ReminderKind.phaseStart]), or menstrual.
  final Phase phase;

  /// The estimated start of the period this reminder belongs to.
  final LocalDate periodDue;

  /// Whether the text may name the phase or the period (the user opted in).
  /// Otherwise it is neutral.
  final bool detailed;

  /// Stable and unique per day and kind, so rescheduling replaces rather
  /// than duplicates (days since 2000 × 2 + kind; fits in 32 bits).
  int get id =>
      LocalDate(2000, 1, 1).daysUntil(date) * ReminderKind.values.length +
      kind.index;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.date == date &&
      other.kind == kind &&
      other.phase == phase &&
      other.periodDue == periodDue &&
      other.detailed == detailed;

  @override
  int get hashCode => Object.hash(date, kind, phase, periodDue, detailed);

  @override
  String toString() => 'PlannedReminder($date ${kind.name} ${phase.name})';
}

/// The reminders to schedule after [today], oldest first (plan §M14).
///
/// - Nothing when reminders are off, or when the period is late: the
///   estimates for the cycles after it are no longer meaningful until a new
///   period is logged.
/// - Phase starts are the first day of each phase in the current cycle and
///   the next [reminderCyclesAhead] estimated cycles.
/// - "Before your period" is [periodReminderDaysBefore] days before each
///   estimated period start.
List<PlannedReminder> planReminders({
  required LocalDate lastPeriodStart,
  required CycleLengths lengths,
  required LocalDate today,
  required ReminderSettings settings,
  bool detailed = false,
}) {
  if (!settings.enabled) return const [];
  final cycleLength = lengths.cycleLength;
  final isLate = lastPeriodStart.daysUntil(today) + 1 > cycleLength;
  if (isLate) return const [];

  final ranges = phaseRangesFor(lengths);
  final plan = <PlannedReminder>[];
  for (var k = 0; k <= reminderCyclesAhead; k++) {
    final cycleStart = lastPeriodStart.addDays(k * cycleLength);
    final nextPeriod = cycleStart.addDays(cycleLength);
    if (settings.phaseChange) {
      for (final phase in Phase.values) {
        plan.add(
          PlannedReminder(
            date: cycleStart.addDays(ranges.of(phase).firstDay - 1),
            kind: ReminderKind.phaseStart,
            phase: phase,
            periodDue: phase == Phase.menstrual ? cycleStart : nextPeriod,
            detailed: detailed,
          ),
        );
      }
    }
    if (settings.beforePeriod) {
      plan.add(
        PlannedReminder(
          date: nextPeriod.addDays(-periodReminderDaysBefore),
          kind: ReminderKind.periodSoon,
          phase: Phase.menstrual,
          periodDue: nextPeriod,
          detailed: detailed,
        ),
      );
    }
  }
  return [
    for (final r in plan)
      if (r.date.isAfter(today)) r,
  ]..sort(
    (a, b) => a.date == b.date
        ? a.kind.index - b.kind.index
        : a.date.compareTo(b.date),
  );
}
