import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/domain/period_log.dart';
import 'package:moon_cycle/features/cycle/domain/period_start_check.dart';

void main() {
  final today = LocalDate(2025, 10, 4);
  final logs = [
    PeriodLog(
      id: 'a',
      start: LocalDate(2025, 9, 28),
      source: PeriodLogSource.onboarding,
    ),
  ];
  PeriodStartProblem? check(LocalDate d, {String? editing}) =>
      checkPeriodStart(d, existing: logs, today: today, editingId: editing);

  test('today and earlier dates far from other periods are fine', () {
    expect(check(today.addDays(-30)), isNull);
    expect(checkPeriodStart(today, existing: const [], today: today), isNull);
  });
  test('the future is not', () {
    expect(check(today.addDays(1)), PeriodStartProblem.inFuture);
  });
  test('within 10 days of another period is not', () {
    expect(check(LocalDate(2025, 10, 4)), PeriodStartProblem.tooCloseToAnother);
    expect(check(LocalDate(2025, 9, 19)), PeriodStartProblem.tooCloseToAnother);
    expect(check(LocalDate(2025, 9, 18)), isNull);
  });
  test('the same date updates that log, so it is fine', () {
    expect(check(LocalDate(2025, 9, 28)), isNull);
  });
  test('moving a log is checked against the others only', () {
    expect(check(LocalDate(2025, 9, 30), editing: 'a'), isNull);
  });
}
