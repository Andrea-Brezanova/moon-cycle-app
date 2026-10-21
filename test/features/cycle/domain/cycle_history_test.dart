import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_history.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/period_log.dart';

final day0 = LocalDate(2026, 1, 5);

/// Logs starting after each of [gaps] in turn (oldest first), each lasting
/// [days] when given.
List<PeriodLog> logsWithGaps(List<int> gaps, {int? days}) {
  var start = day0;
  final logs = <PeriodLog>[];
  for (var i = 0; i <= gaps.length; i++) {
    logs.add(
      PeriodLog(
        id: 'p$i',
        start: start,
        end: days == null ? null : start.addDays(days - 1),
        source: PeriodLogSource.manual,
      ),
    );
    if (i < gaps.length) start = start.addDays(gaps[i]);
  }
  return logs.reversed.toList(); // newest first, like the repository
}

void main() {
  const profile = CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5);

  group('historyAverages', () {
    test('fewer than 3 cycles: no average', () {
      expect(historyAverages(logsWithGaps([30, 30])).cycleLength, isNull);
      expect(historyAverages(const []).cycleLength, isNull);
    });

    test('exactly 3 cycles: their rounded average', () {
      final a = historyAverages(logsWithGaps([29, 30, 30]));
      expect(a.cycleLength, 30); // 29.67
      expect(a.cyclesUsed, 3);
    });

    test('6+ cycles: only the 6 most recent count', () {
      // Oldest first: two 40s, then six 28s.
      final a = historyAverages(logsWithGaps([40, 40, 28, 28, 28, 28, 28, 28]));
      expect(a.cycleLength, 28);
      expect(a.cyclesUsed, 6);
    });

    test('outliers outside 21–45 are left out', () {
      final a = historyAverages(logsWithGaps([30, 90, 30, 14, 30]));
      expect(a.cycleLength, 30);
      expect(a.cyclesUsed, 3);
    });

    test('outliers leaving fewer than 3 cycles: no average', () {
      expect(historyAverages(logsWithGaps([30, 90, 30])).cycleLength, isNull);
    });

    test('gaps next to an estimated start are left out', () {
      final logs = logsWithGaps([30, 30, 30]);
      final estimated = [
        for (final l in logs)
          l.id == 'p0'
              ? PeriodLog(
                  id: l.id,
                  start: l.start,
                  source: PeriodLogSource.onboarding,
                  isEstimated: true,
                )
              : l,
      ];
      expect(historyAverages(estimated).cycleLength, isNull);
    });

    test('period length from completed cycles’ periods with an end date', () {
      final a = historyAverages(logsWithGaps([28, 28, 28], days: 6));
      expect(a.periodLength, 6);
      expect(a.periodsUsed, 3); // the current period doesn't count
      expect(
        historyAverages(logsWithGaps([28, 28], days: 6)).periodLength,
        isNull,
      );
      expect(historyAverages(logsWithGaps([28, 28, 28])).periodLength, isNull);
    });

    test('the order of the logs doesn’t matter', () {
      final logs = logsWithGaps([26, 27, 31]);
      expect(historyAverages(logs.reversed.toList()), historyAverages(logs));
    });
  });

  group('effectiveLengths', () {
    test('typical values without enough history', () {
      expect(
        effectiveLengths(profile, logsWithGaps([30])),
        CycleLengths.fromProfile(profile),
      );
    });

    test('averages once there is enough history', () {
      final lengths = effectiveLengths(profile, logsWithGaps([32, 32, 32]));
      expect(lengths.cycleLength, 32);
      expect(lengths.periodLength, 5); // no end dates: typical
      expect(lengths.source, LengthsSource.historyAverage);
    });

    test('typical values when the user switches averages off', () {
      expect(
        effectiveLengths(
          profile.copyWith(useHistoryAverages: false),
          logsWithGaps([32, 32, 32]),
        ),
        CycleLengths.fromProfile(profile),
      );
    });
  });

  group('periodHistory', () {
    test('newest first, with period days and cycle lengths', () {
      final history = periodHistory(logsWithGaps([28, 30], days: 5));
      expect([for (final e in history) e.cycleLength], [null, 30, 28]);
      expect([for (final e in history) e.periodDays], [5, 5, 5]);
      expect(history.first.isCurrent, isTrue);
    });

    test('no end date: no period days', () {
      expect(periodHistory(logsWithGaps([28])).first.periodDays, isNull);
    });
  });

  test('periodEnd counts both ends', () {
    expect(periodEnd(day0, 5), day0.addDays(4));
  });
}
