import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_history.dart';
import 'package:moon_cycle/features/cycle/domain/period_log.dart';

void main() {
  final start = LocalDate(2026, 9, 28);

  test('PeriodLog is a value', () {
    PeriodLog log({LocalDate? end}) => PeriodLog(
      id: 'a',
      start: start,
      end: end,
      source: PeriodLogSource.manual,
    );
    expect(log(), log());
    expect(log().hashCode, log().hashCode);
    expect(log(), isNot(log(end: start.addDays(4))));
    expect(log().toString(), 'PeriodLog(2026-09-28)');
    expect(
      log(end: start.addDays(4)).toString(),
      'PeriodLog(2026-09-28–2026-10-02)',
    );
  });

  test('HistoryAverages is a value', () {
    const a = HistoryAverages(cycleLength: 28, cyclesUsed: 3);
    expect(a, const HistoryAverages(cycleLength: 28, cyclesUsed: 3));
    expect(
      a.hashCode,
      const HistoryAverages(cycleLength: 28, cyclesUsed: 3).hashCode,
    );
    expect(a, isNot(const HistoryAverages()));
    expect(a.toString(), 'HistoryAverages(cycle 28/3, period null/0)');
  });

  test('an end before the start has no length', () {
    final log = PeriodLog(
      id: 'a',
      start: start,
      end: start.addDays(-1),
      source: PeriodLogSource.manual,
    );
    expect(periodDays(log), isNull);
  });
}
