/// Limits and defaults for cycle calculations, in one place.
///
/// They match the approved reference algorithm (`design/code/cycle.ts`).
/// They are modelling assumptions for estimates, not medical facts.
abstract final class CycleRules {
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;
  static const int defaultCycleLength = 28;

  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;
  static const int defaultPeriodLength = 5;

  /// Days from the estimated ovulation day to the end of the cycle.
  static const int minLutealLength = 10;
  static const int maxLutealLength = 16;
  static const int defaultLutealLength = 14;

  /// A last period start older than this many days is valid, but flagged so
  /// the UI can treat a very long gap with care.
  static const int longGapDays = 90;
}
