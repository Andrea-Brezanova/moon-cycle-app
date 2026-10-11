import '../../../core/domain/phase.dart';
import 'cycle_lengths.dart';

/// The cycle days a phase is estimated to cover, e.g. follicular 6–11.
final class PhaseRange {
  const PhaseRange(this.phase, this.firstDay, this.lastDay);

  final Phase phase;
  final int firstDay;
  final int lastDay;

  int get length => lastDay - firstDay + 1;

  bool contains(int cycleDay) => cycleDay >= firstDay && cycleDay <= lastDay;

  @override
  bool operator ==(Object other) =>
      other is PhaseRange &&
      other.phase == phase &&
      other.firstDay == firstDay &&
      other.lastDay == lastDay;

  @override
  int get hashCode => Object.hash(phase, firstDay, lastDay);

  @override
  String toString() => '${phase.name} $firstDay–$lastDay';
}

/// The four estimated phase ranges of one cycle, in cycle order, covering
/// every day from 1 to the cycle length.
final class PhaseRanges {
  PhaseRanges._(List<PhaseRange> ranges) : all = List.unmodifiable(ranges);

  /// Menstrual, follicular, ovulatory, luteal.
  final List<PhaseRange> all;

  int get cycleLength => all.last.lastDay;

  PhaseRange of(Phase phase) => all[phase.index];

  /// The range containing [cycleDay]. Throws [RangeError] outside 1 to the
  /// cycle length (a late period is handled by the calculator, not here).
  PhaseRange forDay(int cycleDay) {
    RangeError.checkValueInInterval(cycleDay, 1, cycleLength, 'cycleDay');
    return all.firstWhere((r) => r.contains(cycleDay));
  }
}

/// Estimated phase ranges for [lengths].
///
/// An exact port of `phaseRanges` in the approved reference
/// `design/code/cycle.ts` (checked against it for every valid input):
///
/// - estimated ovulation day = cycle length − luteal length;
/// - the ovulatory window is 4 days, from 2 days before that day to 1 after;
/// - the follicular phase always gets at least 1 day, and so does the luteal.
///
/// Because the window ends the day after the estimated ovulation day, the
/// displayed luteal phase is `lutealLength − 1` days in the usual case
/// (13 days for the default 14). When the minimums collide in short cycles,
/// the luteal phase is what gets shorter.
PhaseRanges phaseRangesFor(CycleLengths lengths) {
  final cycle = lengths.cycleLength;
  final period = lengths.periodLength;
  final ovulationDay = cycle - lengths.lutealLength;

  var ovulatoryStart = _max(ovulationDay - 2, period + 2);
  final ovulatoryEnd = _min(ovulatoryStart + 3, cycle - 1);
  ovulatoryStart = _min(ovulatoryStart, ovulatoryEnd);

  return PhaseRanges._([
    PhaseRange(Phase.menstrual, 1, period),
    PhaseRange(Phase.follicular, period + 1, ovulatoryStart - 1),
    PhaseRange(Phase.ovulatory, ovulatoryStart, ovulatoryEnd),
    PhaseRange(Phase.luteal, ovulatoryEnd + 1, cycle),
  ]);
}

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;
