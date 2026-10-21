import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../cycle/domain/cycle_state.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _weekday(LocalDate d) =>
    _weekdays[DateTime.utc(d.year, d.month, d.day).weekday - 1];

/// "Saturday 4 October" (or "Sat 4 Oct" when [short]).
String plainDate(LocalDate d, {bool short = false}) {
  final w = _weekday(d);
  final m = _months[d.month - 1];
  return short
      ? '${w.substring(0, 3)} ${d.day} ${m.substring(0, 3)}'
      : '$w ${d.day} $m';
}

/// "Today · Saturday 4 October", dropping "Today · " on other days.
String barDate(LocalDate d, LocalDate today, {bool short = false}) {
  final base = plainDate(d, short: short);
  return d == today ? 'Today · $base' : base;
}

/// "Today", "Yesterday" or "Fri 3 Oct", for a history row.
String historyDay(LocalDate d, LocalDate today) {
  if (d == today) return 'Today';
  if (d == today.addDays(-1)) return 'Yesterday';
  return plainDate(d, short: true);
}

/// The phase and day of the cycle on [date], by the current cycle's lengths.
/// Today is the real state; other days wrap by the cycle length, which is an
/// estimate (the app does not keep per-cycle phases for the past).
({Phase phase, int day}) phaseOn(
  CycleState s,
  LocalDate date,
  LocalDate today,
) {
  if (date == today) return (phase: s.phase, day: s.cycleDay);
  final length = s.lengths.cycleLength;
  final raw = s.lastPeriodStart.daysUntil(date);
  final day = ((raw % length) + length) % length + 1;
  return (phase: s.ranges.forDay(day).phase, day: day);
}
