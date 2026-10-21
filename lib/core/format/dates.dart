import '../domain/local_date.dart';

/// English date wording used across the app (v1 is English only).
abstract final class DateText {
  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ];
  static const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
    'Sunday',
  ];

  static int _weekday(LocalDate d) =>
      DateTime.utc(d.year, d.month, d.day).weekday - 1;

  /// "26 October".
  static String dayMonth(LocalDate d) => '${d.day} ${months[d.month - 1]}';

  /// "Sunday 28 September".
  static String weekdayDayMonth(LocalDate d) =>
      '${weekdays[_weekday(d)]} ${dayMonth(d)}';

  /// "Sat 4 Oct" (Home header).
  static String short(LocalDate d) =>
      '${weekdays[_weekday(d)].substring(0, 3)} ${d.day} '
      '${months[d.month - 1].substring(0, 3)}';

  /// "28 Sep" (period history).
  static String shortDayMonth(LocalDate d) =>
      '${d.day} ${months[d.month - 1].substring(0, 3)}';

  /// "1 day", "5 days".
  static String days(int n) => n == 1 ? '1 day' : '$n days';
}
