import '../../../core/domain/local_date.dart';

/// Where a period log came from.
enum PeriodLogSource { onboarding, manual }

/// One logged period. The most recent [start] is the "last period start"
/// the cycle is calculated from.
final class PeriodLog {
  const PeriodLog({
    required this.id,
    required this.start,
    this.end,
    required this.source,
    this.isEstimated = false,
  });

  final String id;
  final LocalDate start;

  /// The last day of bleeding, when the user has logged it.
  final LocalDate? end;

  final PeriodLogSource source;

  /// True when the user chose "I'm not sure" in onboarding: the start is a
  /// guess (today − 7) to confirm later.
  final bool isEstimated;

  @override
  bool operator ==(Object other) =>
      other is PeriodLog &&
      other.id == id &&
      other.start == start &&
      other.end == end &&
      other.source == source &&
      other.isEstimated == isEstimated;

  @override
  int get hashCode => Object.hash(id, start, end, source, isEstimated);

  @override
  String toString() => 'PeriodLog($start${end == null ? '' : '–$end'})';
}
