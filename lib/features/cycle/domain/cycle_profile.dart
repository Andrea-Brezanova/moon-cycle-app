/// The user's own typical values, as entered in onboarding or My Cycle.
///
/// Stored as entered; [CycleLengths.fromProfile] makes them safe to calculate
/// with.
final class CycleProfile {
  const CycleProfile({
    required this.typicalCycleLength,
    required this.typicalPeriodLength,
    this.lutealLength,
    this.useHistoryAverages = true,
  });

  final int typicalCycleLength;
  final int typicalPeriodLength;

  /// Null means the default (`CycleRules.defaultLutealLength`).
  final int? lutealLength;

  /// Once enough periods are logged, calculate with their averages instead
  /// of the typical values (My Cycle can switch this off).
  final bool useHistoryAverages;

  CycleProfile copyWith({
    int? typicalCycleLength,
    int? typicalPeriodLength,
    bool? useHistoryAverages,
  }) => CycleProfile(
    typicalCycleLength: typicalCycleLength ?? this.typicalCycleLength,
    typicalPeriodLength: typicalPeriodLength ?? this.typicalPeriodLength,
    lutealLength: lutealLength,
    useHistoryAverages: useHistoryAverages ?? this.useHistoryAverages,
  );

  @override
  bool operator ==(Object other) =>
      other is CycleProfile &&
      other.typicalCycleLength == typicalCycleLength &&
      other.typicalPeriodLength == typicalPeriodLength &&
      other.lutealLength == lutealLength &&
      other.useHistoryAverages == useHistoryAverages;

  @override
  int get hashCode => Object.hash(
    typicalCycleLength,
    typicalPeriodLength,
    lutealLength,
    useHistoryAverages,
  );
}
