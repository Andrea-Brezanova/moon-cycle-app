import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import 'cycle_lengths.dart';
import 'cycle_rules.dart';
import 'cycle_state.dart';
import 'phase_ranges.dart';

/// Calculates the user's estimated cycle position on [today].
///
/// - [lastPeriodStart] is day 1 of the most recent period.
/// - [lengths] are the lengths to calculate with (from the profile now, from
///   period history later).
/// - [today] is always passed in; this code never reads the clock.
///
/// Throws [ArgumentError] if [lastPeriodStart] is after [today]. That is
/// invalid input: `checkCycleInput` reports it so the UI can prevent it.
CycleState calculateCycleState({
  required LocalDate lastPeriodStart,
  required CycleLengths lengths,
  required LocalDate today,
}) {
  if (lastPeriodStart.isAfter(today)) {
    throw ArgumentError.value(
      lastPeriodStart,
      'lastPeriodStart',
      'is after today ($today)',
    );
  }

  final ranges = phaseRangesFor(lengths);
  final cycleLength = lengths.cycleLength;
  final daysSinceStart = lastPeriodStart.daysUntil(today);
  final cycleDay = daysSinceStart + 1;

  // Late: no new period logged after the cycle should have ended. The phase
  // stays luteal and the marker stays on the last day.
  final isLate = cycleDay > cycleLength;
  final orbitDay = isLate ? cycleLength : cycleDay;

  final current = ranges.forDay(orbitDay);
  final nextPhase = current.phase.next;
  final daysUntilNextPeriod = isLate ? 0 : cycleLength - cycleDay + 1;
  final daysToNextPhase = current.phase == Phase.luteal
      ? daysUntilNextPeriod
      : ranges.of(nextPhase).firstDay - cycleDay;
  final estimatedNextPeriodDate = lastPeriodStart.addDays(cycleLength);

  return CycleState(
    today: today,
    lastPeriodStart: lastPeriodStart,
    lengths: lengths,
    ranges: ranges,
    cycleDay: cycleDay,
    orbitDay: orbitDay,
    phase: current.phase,
    phaseDay: orbitDay - current.firstDay + 1,
    phaseLength: current.length,
    nextPhase: nextPhase,
    daysToNextPhase: daysToNextPhase,
    estimatedNextPhaseDate: isLate
        ? estimatedNextPeriodDate
        : today.addDays(daysToNextPhase),
    estimatedNextPeriodDate: estimatedNextPeriodDate,
    daysUntilNextPeriod: daysUntilNextPeriod,
    isLate: isLate,
    daysLate: isLate ? cycleDay - cycleLength : 0,
    isLongGap: daysSinceStart > CycleRules.longGapDays,
  );
}
