import '../../../core/domain/local_date.dart';
import 'cycle_rules.dart';

/// Input that must be corrected before it can be saved.
enum CycleInputError {
  lastPeriodStartInFuture,
  cycleLengthOutOfRange,
  periodLengthOutOfRange,
}

/// Input that is valid, but that the UI may want to handle with care.
enum CycleInputWarning {
  /// The last period started more than [CycleRules.longGapDays] days ago.
  /// Accepted: some users genuinely have long gaps.
  lastPeriodStartOver90DaysAgo,
}

/// The result of checking cycle input from onboarding or My Cycle.
final class CycleInputCheck {
  const CycleInputCheck({required this.errors, required this.warnings});

  final Set<CycleInputError> errors;
  final Set<CycleInputWarning> warnings;

  /// True when the input can be saved (warnings don't block saving).
  bool get isValid => errors.isEmpty;
}

/// Checks the values a user enters for their cycle. [today] is passed in.
CycleInputCheck checkCycleInput({
  required LocalDate lastPeriodStart,
  required int cycleLength,
  required int periodLength,
  required LocalDate today,
}) {
  final errors = <CycleInputError>{};
  final warnings = <CycleInputWarning>{};

  if (lastPeriodStart.isAfter(today)) {
    errors.add(CycleInputError.lastPeriodStartInFuture);
  } else if (lastPeriodStart.daysUntil(today) > CycleRules.longGapDays) {
    warnings.add(CycleInputWarning.lastPeriodStartOver90DaysAgo);
  }
  if (cycleLength < CycleRules.minCycleLength ||
      cycleLength > CycleRules.maxCycleLength) {
    errors.add(CycleInputError.cycleLengthOutOfRange);
  }
  if (periodLength < CycleRules.minPeriodLength ||
      periodLength > CycleRules.maxPeriodLength) {
    errors.add(CycleInputError.periodLengthOutOfRange);
  }

  return CycleInputCheck(
    errors: Set.unmodifiable(errors),
    warnings: Set.unmodifiable(warnings),
  );
}
