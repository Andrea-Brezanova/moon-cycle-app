import '../../../core/domain/local_date.dart';
import '../../cycle/domain/cycle_input_validation.dart';
import '../../cycle/domain/cycle_rules.dart';
import '../../preferences/domain/diet.dart';

/// What the user has answered so far in onboarding. Kept in memory until the
/// food-preferences step is done, then saved in one go (plan §7.2).
final class OnboardingAnswers {
  const OnboardingAnswers({
    this.lastPeriodStart,
    this.startIsEstimated = false,
    this.cycleLength = CycleRules.defaultCycleLength,
    this.periodLength = CycleRules.defaultPeriodLength,
    this.diet = Diet.omnivore,
    this.allergenIds = const {},
    this.foodIds = const {},
    this.customAvoidances = const [],
  });

  final LocalDate? lastPeriodStart;

  /// "I'm not sure": the start is today − 7, to confirm later.
  final bool startIsEstimated;
  final int cycleLength;
  final int periodLength;
  final Diet diet;
  final Set<String> allergenIds;
  final Set<String> foodIds;
  final List<String> customAvoidances;

  /// Step 2 can continue once a valid (past or today) start is chosen.
  bool lastPeriodValid(LocalDate today) =>
      lastPeriodStart != null &&
      checkCycleInput(
        lastPeriodStart: lastPeriodStart!,
        cycleLength: cycleLength,
        periodLength: periodLength,
        today: today,
      ).isValid;

  /// The days after the start that are predicted to be period days, for the
  /// calendar highlight.
  Set<LocalDate> predictedPeriodDays() => lastPeriodStart == null
      ? const {}
      : {for (var i = 1; i < periodLength; i++) lastPeriodStart!.addDays(i)};

  OnboardingAnswers copyWith({
    LocalDate? lastPeriodStart,
    bool? startIsEstimated,
    int? cycleLength,
    int? periodLength,
    Diet? diet,
    Set<String>? allergenIds,
    Set<String>? foodIds,
    List<String>? customAvoidances,
  }) => OnboardingAnswers(
    lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
    startIsEstimated: startIsEstimated ?? this.startIsEstimated,
    cycleLength: (cycleLength ?? this.cycleLength).clamp(
      CycleRules.minCycleLength,
      CycleRules.maxCycleLength,
    ),
    periodLength: (periodLength ?? this.periodLength).clamp(
      CycleRules.minPeriodLength,
      CycleRules.maxPeriodLength,
    ),
    diet: diet ?? this.diet,
    allergenIds: allergenIds ?? this.allergenIds,
    foodIds: foodIds ?? this.foodIds,
    customAvoidances: customAvoidances ?? this.customAvoidances,
  );
}
