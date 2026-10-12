import '../../../core/domain/local_date.dart';
import 'period_log.dart';

/// Why a period start can't be logged.
enum PeriodStartProblem {
  /// After today.
  inFuture,

  /// Within 10 days of another logged period (plan §6.2): two starts that
  /// close together are almost certainly one period.
  tooCloseToAnother,
}

/// The fewest days between two logged period starts.
const minDaysBetweenPeriodStarts = 10;

/// Checks a period start before logging it. Logging the exact date of an
/// existing period is fine: it updates that log instead of adding one.
PeriodStartProblem? checkPeriodStart(
  LocalDate start, {
  required List<PeriodLog> existing,
  required LocalDate today,
  String? editingId,
}) {
  if (start.isAfter(today)) return PeriodStartProblem.inFuture;
  for (final log in existing) {
    if (log.id == editingId || log.start == start) continue;
    if (log.start.daysUntil(start).abs() < minDaysBetweenPeriodStarts) {
      return PeriodStartProblem.tooCloseToAnother;
    }
  }
  return null;
}
