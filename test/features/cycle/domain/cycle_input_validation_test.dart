import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_input_validation.dart';

final today = LocalDate(2025, 10, 4);

CycleInputCheck check({
  LocalDate? start,
  int cycleLength = 28,
  int periodLength = 5,
}) => checkCycleInput(
  lastPeriodStart: start ?? LocalDate(2025, 9, 28),
  cycleLength: cycleLength,
  periodLength: periodLength,
  today: today,
);

void main() {
  test('typical input is valid with no warnings', () {
    final c = check();
    expect(c.isValid, isTrue);
    expect(c.errors, isEmpty);
    expect(c.warnings, isEmpty);
  });

  group('last period start', () {
    test('today is valid', () {
      expect(check(start: today).isValid, isTrue);
    });

    test('a future date is an error', () {
      final c = check(start: today.addDays(1));
      expect(c.isValid, isFalse);
      expect(c.errors, {CycleInputError.lastPeriodStartInFuture});
      expect(c.warnings, isEmpty);
    });

    test('exactly 90 days ago is valid without a warning', () {
      final c = check(start: today.addDays(-90));
      expect(c.isValid, isTrue);
      expect(c.warnings, isEmpty);
    });

    test('more than 90 days ago is valid, with a warning', () {
      for (final daysAgo in [91, 200, 1000]) {
        final c = check(start: today.addDays(-daysAgo));
        expect(c.isValid, isTrue, reason: '$daysAgo days ago');
        expect(c.warnings, {CycleInputWarning.lastPeriodStartOver90DaysAgo});
      }
    });
  });

  group('lengths', () {
    test('the limits themselves are valid', () {
      for (final (cycle, period) in [(21, 2), (45, 10), (21, 10), (45, 2)]) {
        expect(
          check(cycleLength: cycle, periodLength: period).isValid,
          isTrue,
          reason: '$cycle/$period',
        );
      }
    });

    test('cycle length outside 21–45 is an error', () {
      for (final cycle in [20, 46, 0]) {
        expect(check(cycleLength: cycle).errors, {
          CycleInputError.cycleLengthOutOfRange,
        });
      }
    });

    test('period length outside 2–10 is an error', () {
      for (final period in [1, 11]) {
        expect(check(periodLength: period).errors, {
          CycleInputError.periodLengthOutOfRange,
        });
      }
    });
  });

  test('several problems are reported together', () {
    final c = check(start: today.addDays(3), cycleLength: 50, periodLength: 0);
    expect(c.isValid, isFalse);
    expect(c.errors, {
      CycleInputError.lastPeriodStartInFuture,
      CycleInputError.cycleLengthOutOfRange,
      CycleInputError.periodLengthOutOfRange,
    });
  });

  test('results cannot be modified', () {
    final c = check(start: today.addDays(-120));
    expect(
      () => c.errors.add(CycleInputError.cycleLengthOutOfRange),
      throwsUnsupportedError,
    );
    expect(c.warnings.clear, throwsUnsupportedError);
  });
}
