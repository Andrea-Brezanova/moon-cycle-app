import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import 'cycle_lengths.dart';
import 'phase_ranges.dart';

/// Everything the app shows about where the user is in their cycle on one
/// day, as calculated by `calculateCycleState`.
///
/// Phases, phase dates and the next period are **estimates** calculated from
/// the user's dates and lengths. They are not observations of the body, and
/// the UI must not present them (estimated ovulation in particular) as
/// confirmed biological events.
final class CycleState {
  const CycleState({
    required this.today,
    required this.lastPeriodStart,
    required this.lengths,
    required this.ranges,
    required this.cycleDay,
    required this.orbitDay,
    required this.phase,
    required this.phaseDay,
    required this.phaseLength,
    required this.nextPhase,
    required this.daysToNextPhase,
    required this.estimatedNextPhaseDate,
    required this.estimatedNextPeriodDate,
    required this.daysUntilNextPeriod,
    required this.isLate,
    required this.daysLate,
    required this.isLongGap,
  });

  final LocalDate today;
  final LocalDate lastPeriodStart;

  /// The lengths used, including where they came from (`lengths.source`).
  final CycleLengths lengths;

  /// The four estimated phase ranges for this cycle.
  final PhaseRanges ranges;

  /// Day of the cycle, starting at 1 on [lastPeriodStart]. Exceeds the cycle
  /// length while a period is late ("Day 32 in cycle").
  final int cycleDay;

  /// The day the today-marker sits on in the orbit: [cycleDay], but never
  /// past the last day of the cycle.
  final int orbitDay;

  /// The current estimated phase. Stays luteal while a period is late.
  final Phase phase;

  /// Day within [phase], starting at 1 ("Day 2 of 6 in phase").
  final int phaseDay;

  /// Length of [phase] in this cycle.
  final int phaseLength;

  /// The phase after [phase]; menstrual after luteal.
  final Phase nextPhase;

  /// Days until [nextPhase] starts ("Ovulatory in 5 days"). In the luteal
  /// phase this is the days until the next period. 0 while late.
  final int daysToNextPhase;

  /// The date [nextPhase] is estimated to start. While late, this is the
  /// expected period date that has already passed.
  final LocalDate estimatedNextPhaseDate;

  /// [lastPeriodStart] plus the cycle length. In the past while late.
  final LocalDate estimatedNextPeriodDate;

  /// Days until [estimatedNextPeriodDate] ("In 22 days"). 0 while late.
  final int daysUntilNextPeriod;

  /// True once [cycleDay] is past the cycle length with no new period logged.
  final bool isLate;

  /// How many days the period is late; 0 when not late.
  final int daysLate;

  /// True when [lastPeriodStart] is more than 90 days before [today]. A valid
  /// state (some users have long gaps); a flag for the UI to handle with care.
  final bool isLongGap;

  int get cycleLength => lengths.cycleLength;
}
