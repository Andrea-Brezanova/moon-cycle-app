import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';

void main() {
  group('creating', () {
    test('rejects dates that do not exist', () {
      expect(() => LocalDate(2025, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2025, 13, 1), throwsArgumentError);
      expect(() => LocalDate(2025, 4, 31), throwsArgumentError);
      expect(LocalDate(2028, 2, 29).day, 29); // leap year
    });

    test('fromDateTime keeps the calendar day at any time of day', () {
      expect(
        LocalDate.fromDateTime(DateTime(2025, 10, 4, 0, 1)),
        LocalDate(2025, 10, 4),
      );
      expect(
        LocalDate.fromDateTime(DateTime(2025, 10, 4, 23, 59)),
        LocalDate(2025, 10, 4),
      );
      expect(
        LocalDate.fromDateTime(DateTime.utc(2025, 10, 4, 23, 59)),
        LocalDate(2025, 10, 4),
      );
    });
  });

  group('ISO text', () {
    test('parses and prints YYYY-MM-DD', () {
      expect(LocalDate.parse('2025-09-28'), LocalDate(2025, 9, 28));
      expect(LocalDate(2025, 9, 8).toString(), '2025-09-08');
      expect(LocalDate(987, 1, 2).toString(), '0987-01-02');
      final d = LocalDate(2026, 12, 31);
      expect(LocalDate.parse(d.toString()), d);
    });

    test('rejects anything else', () {
      for (final bad in ['2025-9-28', '28.09.2025', '2025-09-28T00:00', '']) {
        expect(() => LocalDate.parse(bad), throwsFormatException, reason: bad);
      }
      expect(() => LocalDate.parse('2025-02-30'), throwsArgumentError);
    });
  });

  group('arithmetic', () {
    test('addDays crosses month, year and leap days', () {
      expect(LocalDate(2025, 9, 28).addDays(28), LocalDate(2025, 10, 26));
      expect(LocalDate(2025, 12, 31).addDays(1), LocalDate(2026, 1, 1));
      expect(LocalDate(2028, 2, 28).addDays(1), LocalDate(2028, 2, 29));
      expect(LocalDate(2028, 2, 28).addDays(2), LocalDate(2028, 3, 1));
      expect(LocalDate(2027, 2, 28).addDays(1), LocalDate(2027, 3, 1));
      expect(LocalDate(2026, 1, 1).addDays(-1), LocalDate(2025, 12, 31));
      expect(LocalDate(2025, 10, 4).addDays(0), LocalDate(2025, 10, 4));
    });

    test('daysUntil counts calendar days, ignoring daylight saving', () {
      // Europe springs forward on 30 March 2025 and falls back on 26 October;
      // the US on 9 March and 2 November.
      expect(LocalDate(2025, 3, 29).daysUntil(LocalDate(2025, 3, 31)), 2);
      expect(LocalDate(2025, 10, 25).daysUntil(LocalDate(2025, 10, 27)), 2);
      expect(LocalDate(2025, 3, 8).daysUntil(LocalDate(2025, 3, 10)), 2);
      expect(LocalDate(2025, 11, 1).daysUntil(LocalDate(2025, 11, 3)), 2);
      expect(LocalDate(2025, 1, 1).daysUntil(LocalDate(2026, 1, 1)), 365);
      expect(LocalDate(2028, 1, 1).daysUntil(LocalDate(2029, 1, 1)), 366);
      expect(LocalDate(2025, 10, 4).daysUntil(LocalDate(2025, 9, 28)), -6);
    });
  });

  group('comparing', () {
    test('equality, hashCode and order', () {
      final a = LocalDate(2025, 9, 28);
      expect(a, LocalDate(2025, 9, 28));
      expect(a.hashCode, LocalDate(2025, 9, 28).hashCode);
      expect(a == LocalDate(2025, 9, 29), isFalse);
      expect(a.isBefore(LocalDate(2025, 9, 29)), isTrue);
      expect(a.isAfter(LocalDate(2025, 9, 27)), isTrue);
      expect(a.isBefore(a) || a.isAfter(a), isFalse);
      expect(a.compareTo(LocalDate(2025, 10, 1)), lessThan(0));
      final sorted = [LocalDate(2026, 1, 1), a, LocalDate(2025, 10, 4)]..sort();
      expect(sorted.first, a);
    });
  });
}
