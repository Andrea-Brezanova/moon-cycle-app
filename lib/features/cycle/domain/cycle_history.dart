import '../../../core/domain/local_date.dart';
import 'cycle_lengths.dart';
import 'cycle_profile.dart';
import 'cycle_rules.dart';
import 'period_log.dart';

/// Averages need at least this many completed cycles (or periods with an
/// end date) before they replace the typical values (plan §6.2).
const minCyclesForAverage = 3;

/// Only the most recent cycles count.
const maxCyclesAveraged = 6;

/// Averages worked out from logged periods. A value is null until there is
/// enough history for it.
final class HistoryAverages {
  const HistoryAverages({
    this.cycleLength,
    this.cyclesUsed = 0,
    this.periodLength,
    this.periodsUsed = 0,
  });

  /// The rounded average gap between consecutive period starts.
  final int? cycleLength;

  /// How many cycles [cycleLength] averages ("Average of your last 3
  /// cycles").
  final int cyclesUsed;

  /// The rounded average length of periods that have an end date.
  final int? periodLength;
  final int periodsUsed;

  @override
  bool operator ==(Object other) =>
      other is HistoryAverages &&
      other.cycleLength == cycleLength &&
      other.cyclesUsed == cyclesUsed &&
      other.periodLength == periodLength &&
      other.periodsUsed == periodsUsed;

  @override
  int get hashCode =>
      Object.hash(cycleLength, cyclesUsed, periodLength, periodsUsed);

  @override
  String toString() =>
      'HistoryAverages(cycle $cycleLength/$cyclesUsed, '
      'period $periodLength/$periodsUsed)';
}

/// Averages from [logs] (in any order), per plan §6.2:
/// - cycle length: the gaps between consecutive starts. Gaps outside the
///   21–45 day range are outliers and don't count (they stay in history),
///   nor do gaps next to an estimated start ("I'm not sure"). The most
///   recent [maxCyclesAveraged] remaining gaps are averaged once there are
///   at least [minCyclesForAverage].
/// - period length: the same way, from periods with an end date in
///   completed cycles (not the current one, which may still be going on),
///   within 2–10 days.
HistoryAverages historyAverages(List<PeriodLog> logs) {
  final newestFirst = [...logs]..sort((a, b) => b.start.compareTo(a.start));

  final gaps = <int>[];
  for (var i = 0; i + 1 < newestFirst.length; i++) {
    final newer = newestFirst[i];
    final older = newestFirst[i + 1];
    if (newer.isEstimated || older.isEstimated) continue;
    final gap = older.start.daysUntil(newer.start);
    if (gap >= CycleRules.minCycleLength && gap <= CycleRules.maxCycleLength) {
      gaps.add(gap);
    }
  }

  final periods = [
    for (final log in newestFirst.skip(1))
      if (periodDays(log) case final days?)
        if (days >= CycleRules.minPeriodLength &&
            days <= CycleRules.maxPeriodLength)
          days,
  ];

  final (cycle, cyclesUsed) = _average(gaps);
  final (period, periodsUsed) = _average(periods);
  return HistoryAverages(
    cycleLength: cycle,
    cyclesUsed: cyclesUsed,
    periodLength: period,
    periodsUsed: periodsUsed,
  );
}

(int?, int) _average(List<int> newestFirst) {
  if (newestFirst.length < minCyclesForAverage) return (null, 0);
  final used = newestFirst.take(maxCyclesAveraged).toList();
  final sum = used.fold<int>(0, (a, b) => a + b);
  return ((sum / used.length).round(), used.length);
}

/// The days a logged period lasted, counting both ends. Null without an end
/// date (or with an end before the start).
int? periodDays(PeriodLog log) {
  final end = log.end;
  if (end == null || end.isBefore(log.start)) return null;
  return log.start.daysUntil(end) + 1;
}

/// The lengths to calculate with: the history averages when the user lets
/// them be used and there's enough history, otherwise the typical values.
CycleLengths effectiveLengths(CycleProfile profile, List<PeriodLog> logs) {
  final typical = CycleLengths.fromProfile(profile);
  if (!profile.useHistoryAverages) return typical;
  final averages = historyAverages(logs);
  if (averages.cycleLength == null && averages.periodLength == null) {
    return typical;
  }
  return CycleLengths(
    cycleLength: averages.cycleLength ?? typical.cycleLength,
    periodLength: averages.periodLength ?? typical.periodLength,
    lutealLength: typical.lutealLength,
    source: LengthsSource.historyAverage,
  );
}

/// One row of My Cycle › History.
final class PeriodHistoryEntry {
  const PeriodHistoryEntry({
    required this.log,
    required this.periodDays,
    required this.cycleLength,
  });

  final PeriodLog log;

  /// Null when no end date is logged.
  final int? periodDays;

  /// Days from this start to the next one. Null for the current cycle.
  final int? cycleLength;

  bool get isCurrent => cycleLength == null;
}

/// Every logged period, newest first, with its length and the length of
/// the cycle it started.
List<PeriodHistoryEntry> periodHistory(List<PeriodLog> logs) {
  final newestFirst = [...logs]..sort((a, b) => b.start.compareTo(a.start));
  return [
    for (final (i, log) in newestFirst.indexed)
      PeriodHistoryEntry(
        log: log,
        periodDays: periodDays(log),
        cycleLength: i == 0
            ? null
            : log.start.daysUntil(newestFirst[i - 1].start),
      ),
  ];
}

/// The end date for a period of [days] starting on [start].
LocalDate periodEnd(LocalDate start, int days) => start.addDays(days - 1);
