import 'package:flutter_test/flutter_test.dart';

import 'plant_providers_test.dart' show ids, on, start;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Item 12: the same three plants must not come back on successive days, in a
  // phase or across a phase boundary, for short, usual and long cycles.
  for (final length in [24, 28, 35]) {
    test('a $length-day cycle: next-day plants share at most one food, '
        'including across phase boundaries and a late period', () {
      for (var d = 2; d <= length + 12; d++) {
        final yesterday = ids(
          on(start.addDays(d - 2), start: start, cycleLength: length),
        );
        final today = ids(
          on(start.addDays(d - 1), start: start, cycleLength: length),
        );
        expect(yesterday, isNot(today), reason: 'day $d');
        expect(
          yesterday.where(today.contains).length,
          lessThanOrEqualTo(1),
          reason: 'day $d of $length',
        );
      }
    });
  }

  test(
    'a restart (a fresh container) on the same day shows the same three',
    () {
      final day = start.addDays(15);
      expect(ids(on(day, start: start)), ids(on(day, start: start)));
    },
  );
}
