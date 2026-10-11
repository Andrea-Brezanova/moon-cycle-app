import 'cycle_profile.dart';
import 'cycle_rules.dart';

/// Where a set of [CycleLengths] came from.
enum LengthsSource {
  /// The user's typical values from their profile.
  typical,

  /// Averaged from logged periods. Produced once period history exists
  /// (a later milestone); the calculator doesn't need to change for it.
  historyAverage,
}

/// The lengths the calculator works with. Always within [CycleRules] limits.
final class CycleLengths {
  /// Throws [ArgumentError] if a value is outside the [CycleRules] limits.
  CycleLengths({
    required this.cycleLength,
    required this.periodLength,
    required this.lutealLength,
    required this.source,
  }) {
    _check(
      'cycleLength',
      cycleLength,
      CycleRules.minCycleLength,
      CycleRules.maxCycleLength,
    );
    _check(
      'periodLength',
      periodLength,
      CycleRules.minPeriodLength,
      CycleRules.maxPeriodLength,
    );
    _check(
      'lutealLength',
      lutealLength,
      CycleRules.minLutealLength,
      CycleRules.maxLutealLength,
    );
  }

  /// The profile's typical values, clamped to the limits so an out-of-range
  /// stored value can never crash a calculation.
  factory CycleLengths.fromProfile(CycleProfile profile) => CycleLengths(
    cycleLength: profile.typicalCycleLength.clamp(
      CycleRules.minCycleLength,
      CycleRules.maxCycleLength,
    ),
    periodLength: profile.typicalPeriodLength.clamp(
      CycleRules.minPeriodLength,
      CycleRules.maxPeriodLength,
    ),
    lutealLength: (profile.lutealLength ?? CycleRules.defaultLutealLength)
        .clamp(CycleRules.minLutealLength, CycleRules.maxLutealLength),
    source: LengthsSource.typical,
  );

  final int cycleLength;
  final int periodLength;
  final int lutealLength;
  final LengthsSource source;

  static void _check(String name, int value, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'must be $min–$max');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CycleLengths &&
      other.cycleLength == cycleLength &&
      other.periodLength == periodLength &&
      other.lutealLength == lutealLength &&
      other.source == source;

  @override
  int get hashCode =>
      Object.hash(cycleLength, periodLength, lutealLength, source);
}
