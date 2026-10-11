/// A calendar date with no time of day and no time zone, e.g. 2025-09-28.
///
/// Cycle maths counts calendar days, so it uses [LocalDate] instead of
/// [DateTime]. Arithmetic goes through UTC internally, so daylight-saving
/// changes can never add or lose a day.
final class LocalDate implements Comparable<LocalDate> {
  /// Throws [ArgumentError] for a date that doesn't exist (e.g. 2025-02-30).
  LocalDate(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw ArgumentError('Not a valid date: $year-$month-$day');
    }
  }

  /// The calendar day of [dateTime], in that DateTime's own time zone (for
  /// `DateTime.now()` that is the device's local day).
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Parses an ISO date, `YYYY-MM-DD`, the format used for storage.
  factory LocalDate.parse(String iso) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (match == null) {
      throw FormatException('Expected YYYY-MM-DD', iso);
    }
    return LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// This date moved by [days] calendar days (negative moves back).
  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(_utc.add(Duration(days: days)));

  /// Calendar days from this date to [other]; negative if [other] is earlier.
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO format, `YYYY-MM-DD`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
