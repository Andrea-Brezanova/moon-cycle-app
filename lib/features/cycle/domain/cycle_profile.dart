/// The user's own typical values, as entered in onboarding or My Cycle.
///
/// Stored as entered; [CycleLengths.fromProfile] makes them safe to calculate
/// with.
final class CycleProfile {
  const CycleProfile({
    required this.typicalCycleLength,
    required this.typicalPeriodLength,
    this.lutealLength,
  });

  final int typicalCycleLength;
  final int typicalPeriodLength;

  /// Null means the default (`CycleRules.defaultLutealLength`).
  final int? lutealLength;

  @override
  bool operator ==(Object other) =>
      other is CycleProfile &&
      other.typicalCycleLength == typicalCycleLength &&
      other.typicalPeriodLength == typicalPeriodLength &&
      other.lutealLength == lutealLength;

  @override
  int get hashCode =>
      Object.hash(typicalCycleLength, typicalPeriodLength, lutealLength);
}
