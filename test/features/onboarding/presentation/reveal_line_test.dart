import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/onboarding/presentation/phase_reveal_page.dart';

void main() {
  final start = LocalDate(2025, 9, 28);
  final lengths = CycleLengths.fromProfile(
    const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
  );
  String line(int cycleDay) => revealNextLine(
    calculateCycleState(
      lastPeriodStart: start,
      lengths: lengths,
      today: start.addDays(cycleDay - 1),
    ),
  );

  // The canvas's four examples (EdRevealPhases), on a 28/5 cycle.
  test('menstrual', () {
    expect(line(2), 'Follicular in 4 days · Next period 26 October');
  });
  test('follicular', () {
    expect(line(7), 'Ovulatory in 5 days · Next period 26 October');
  });
  test('ovulatory', () {
    expect(line(13), 'Luteal in 3 days · Next period 26 October');
  });
  test('luteal names only the period', () {
    expect(line(18), 'Next period in 11 days · 26 October');
  });
  test('one day is singular', () {
    expect(line(28), 'Next period in 1 day · 26 October');
  });
  test('late', () => expect(line(32), 'Period 4 days late'));
}
