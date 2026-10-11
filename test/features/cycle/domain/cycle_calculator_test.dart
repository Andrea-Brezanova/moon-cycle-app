import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_state.dart';

CycleLengths lengths({int cycle = 28, int period = 5, int luteal = 14}) =>
    CycleLengths(
      cycleLength: cycle,
      periodLength: period,
      lutealLength: luteal,
      source: LengthsSource.typical,
    );

/// The state on [cycleDay] for a cycle that started on 28 September 2025
/// (the date used throughout the designs).
CycleState onDay(int cycleDay, {CycleLengths? l}) {
  final start = LocalDate(2025, 9, 28);
  return calculateCycleState(
    lastPeriodStart: start,
    lengths: l ?? lengths(),
    today: start.addDays(cycleDay - 1),
  );
}

void main() {
  group('the four examples in the designs (28-day cycle, 5-day period)', () {
    test('day 2: menstrual, day 2 of 5, follicular in 4 days', () {
      final s = onDay(2);
      expect(s.phase, Phase.menstrual);
      expect([s.phaseDay, s.phaseLength], [2, 5]);
      expect(s.nextPhase, Phase.follicular);
      expect(s.daysToNextPhase, 4);
    });

    test('day 7 (Sat 4 Oct): follicular, day 2 of 6, ovulatory in 5 days', () {
      final s = onDay(7);
      expect(s.today, LocalDate(2025, 10, 4));
      expect(s.cycleDay, 7);
      expect(s.phase, Phase.follicular);
      expect([s.phaseDay, s.phaseLength], [2, 6]);
      expect(s.nextPhase, Phase.ovulatory);
      expect(s.daysToNextPhase, 5);
      expect(s.estimatedNextPhaseDate, LocalDate(2025, 10, 9));
      // My Cycle: "Sunday 26 October · In 22 days"
      expect(s.estimatedNextPeriodDate, LocalDate(2025, 10, 26));
      expect(s.daysUntilNextPeriod, 22);
    });

    test('day 13: ovulatory, day 2 of 4, luteal in 3 days', () {
      final s = onDay(13);
      expect(s.phase, Phase.ovulatory);
      expect([s.phaseDay, s.phaseLength], [2, 4]);
      expect(s.nextPhase, Phase.luteal);
      expect(s.daysToNextPhase, 3);
    });

    test('day 21: luteal, day 6 of 13, period in 8 days', () {
      final s = onDay(21);
      expect(s.phase, Phase.luteal);
      expect([s.phaseDay, s.phaseLength], [6, 13]);
      expect(s.nextPhase, Phase.menstrual);
      expect(s.daysToNextPhase, 8);
      expect(s.daysUntilNextPeriod, 8);
      expect(s.estimatedNextPhaseDate, s.estimatedNextPeriodDate);
    });
  });

  test('every day of a 28-day cycle', () {
    // (phase, phase day, days to next phase) for days 1–28.
    final expected = <(Phase, int, int)>[
      for (var d = 1; d <= 5; d++) (Phase.menstrual, d, 6 - d),
      for (var d = 6; d <= 11; d++) (Phase.follicular, d - 5, 12 - d),
      for (var d = 12; d <= 15; d++) (Phase.ovulatory, d - 11, 16 - d),
      for (var d = 16; d <= 28; d++) (Phase.luteal, d - 15, 29 - d),
    ];
    for (var day = 1; day <= 28; day++) {
      final s = onDay(day);
      final (phase, phaseDay, toNext) = expected[day - 1];
      expect(
        (s.phase, s.phaseDay, s.daysToNextPhase),
        (phase, phaseDay, toNext),
        reason: 'day $day',
      );
      expect(s.cycleDay, day);
      expect(s.orbitDay, day);
      expect(s.isLate, isFalse);
      expect(s.daysLate, 0);
      expect(s.daysUntilNextPeriod, 29 - day);
      expect(s.today.addDays(s.daysToNextPhase), s.estimatedNextPhaseDate);
    }
  });

  group('boundaries', () {
    test('day 1 is the start date itself', () {
      final s = onDay(1);
      expect(s.cycleDay, 1);
      expect(s.phase, Phase.menstrual);
      expect(s.phaseDay, 1);
      expect(s.lastPeriodStart, s.today);
    });

    test('the last day of the cycle: luteal, period in 1 day', () {
      final s = onDay(28);
      expect(s.phase, Phase.luteal);
      expect([s.phaseDay, s.phaseLength], [13, 13]);
      expect(s.daysToNextPhase, 1);
      expect(s.isLate, isFalse);
    });

    test('short cycle (21/4/14: 1–4, 5, 6–9, 10–21)', () {
      final short = lengths(cycle: 21, period: 4);
      final day5 = onDay(5, l: short);
      expect(day5.phase, Phase.follicular);
      expect([day5.phaseDay, day5.phaseLength], [1, 1]);
      expect(day5.daysToNextPhase, 1);

      final day21 = onDay(21, l: short);
      expect(day21.phase, Phase.luteal);
      expect([day21.phaseDay, day21.phaseLength], [12, 12]);
      expect(day21.daysToNextPhase, 1);
      expect(onDay(22, l: short).isLate, isTrue);
    });

    test('long cycle (45/7/12: 1–7, 8–30, 31–34, 35–45)', () {
      final long = lengths(cycle: 45, period: 7, luteal: 12);
      final day30 = onDay(30, l: long);
      expect(day30.phase, Phase.follicular);
      expect([day30.phaseDay, day30.phaseLength], [23, 23]);
      expect(day30.daysToNextPhase, 1);

      final day40 = onDay(40, l: long);
      expect(day40.phase, Phase.luteal);
      expect(day40.daysToNextPhase, 6);
      expect(day40.estimatedNextPeriodDate, LocalDate(2025, 11, 12));
    });
  });

  group('late period', () {
    test('1 day late: still luteal, marker pinned to the last day', () {
      final s = onDay(29);
      expect(s.isLate, isTrue);
      expect(s.daysLate, 1);
      expect(s.cycleDay, 29);
      expect(s.orbitDay, 28);
      expect(s.phase, Phase.luteal);
      expect([s.phaseDay, s.phaseLength], [13, 13]);
      expect(s.nextPhase, Phase.menstrual);
      expect(s.daysToNextPhase, 0);
      expect(s.daysUntilNextPeriod, 0);
    });

    test('4 days late matches the design ("Period 4 days late · Day 32")', () {
      final s = onDay(32);
      expect(s.daysLate, 4);
      expect(s.cycleDay, 32);
      expect(s.estimatedNextPeriodDate, LocalDate(2025, 10, 26));
      expect(s.estimatedNextPeriodDate.isBefore(s.today), isTrue);
      expect(s.estimatedNextPhaseDate, s.estimatedNextPeriodDate);
    });

    test('60 days late keeps counting without failing', () {
      final s = onDay(88);
      expect(s.daysLate, 60);
      expect(s.phase, Phase.luteal);
      expect(s.orbitDay, 28);
    });
  });

  group('long gap flag (valid input, flagged for the UI)', () {
    test('false up to 90 days since the start, true after', () {
      expect(onDay(91).isLongGap, isFalse); // 90 days since the start
      expect(onDay(92).isLongGap, isTrue); // 91 days
      expect(onDay(7).isLongGap, isFalse);
    });

    test('a very old start date is still calculated', () {
      final start = LocalDate(2024, 1, 15);
      final s = calculateCycleState(
        lastPeriodStart: start,
        lengths: lengths(),
        today: LocalDate(2025, 10, 4),
      );
      expect(s.isLongGap, isTrue);
      expect(s.isLate, isTrue);
      expect(s.cycleDay, start.daysUntil(LocalDate(2025, 10, 4)) + 1);
    });
  });

  test('a last period start after today is invalid input', () {
    expect(
      () => calculateCycleState(
        lastPeriodStart: LocalDate(2025, 10, 5),
        lengths: lengths(),
        today: LocalDate(2025, 10, 4),
      ),
      throwsArgumentError,
    );
  });

  test('dates are counted in calendar days across month and year ends', () {
    final s = calculateCycleState(
      lastPeriodStart: LocalDate(2025, 12, 20),
      lengths: lengths(),
      today: LocalDate(2026, 1, 2),
    );
    expect(s.cycleDay, 14);
    expect(s.phase, Phase.ovulatory);
    expect(s.estimatedNextPeriodDate, LocalDate(2026, 1, 17));
  });

  test('the state carries the lengths and ranges it used', () {
    final l = lengths(cycle: 35, period: 6, luteal: 12);
    final s = onDay(10, l: l);
    expect(s.lengths, l);
    expect(s.cycleLength, 35);
    expect(s.ranges.cycleLength, 35);
    expect(s.ranges.forDay(10).phase, s.phase);
  });
}
