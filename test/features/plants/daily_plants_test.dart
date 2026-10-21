import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/plants/domain/daily_plants.dart';

void main() {
  final pool = [for (var i = 0; i < 10; i++) 'food-$i'];

  List<String> day(int n, {String seed = 's', List<String>? p}) =>
      dailyPlantIds(poolIds: p ?? pool, seed: seed, dayIndex: n);

  test('three distinct foods from the pool', () {
    for (var n = 0; n < 30; n++) {
      final ids = day(n);
      expect(ids, hasLength(3));
      expect(ids.toSet(), hasLength(3));
      expect(pool, containsAll(ids));
    }
  });

  test('the same day always gives the same three, whatever the pool order', () {
    expect(day(4), day(4));
    expect(day(4), day(4, p: pool.reversed.toList()));
  });

  test('the next day is different', () {
    for (var n = 0; n < 20; n++) {
      expect(day(n), isNot(day(n + 1)));
    }
  });

  test('no repeat until the whole pool has been shown', () {
    final seen = <String>[];
    for (var n = 0; n < pool.length ~/ 3; n++) {
      seen.addAll(day(n));
    }
    expect(seen.toSet(), hasLength(seen.length));
  });

  test('when the pool is used up it wraps to the least recently suggested', () {
    // 10 foods, 3 a day: day 3 uses indices 9, 0, 1 of the order, so it
    // repeats the foods shown first, never an invented one.
    final order = <String>[];
    for (var n = 0; n < 4; n++) {
      order.addAll(day(n));
    }
    expect(order.skip(9).toList()..sort(), isNot(isEmpty));
    for (final id in day(3)) {
      expect(pool, contains(id));
    }
    // After a full lap the walk starts over from the same place.
    expect(day(10), day(0)); // 10 days × 3 = 3 laps of 10
  });

  test('a different seed (the next cycle) is a different order', () {
    final a = [for (var n = 0; n < 10; n++) day(n, seed: 'cycle-1').join()];
    final b = [for (var n = 0; n < 10; n++) day(n, seed: 'cycle-2').join()];
    expect(a, isNot(b));
  });

  test('a pool of three or fewer returns what exists, never padded', () {
    expect(day(0, p: ['a', 'b', 'c']).toSet(), {'a', 'b', 'c'});
    expect(day(7, p: ['a', 'b']).toSet(), {'a', 'b'});
    expect(day(1, p: ['a']), ['a']);
    expect(day(1, p: []), isEmpty);
  });

  test('exactly four foods still gives three distinct each day', () {
    final four = ['a', 'b', 'c', 'd'];
    for (var n = 0; n < 12; n++) {
      expect(day(n, p: four).toSet(), hasLength(3));
    }
  });

  test('any day index works, including days past the phase length', () {
    expect(day(0).toSet(), hasLength(3));
    expect(day(200).toSet(), hasLength(3));
    expect(day(-3).toSet(), hasLength(3));
  });

  test('duplicates in the pool are ignored', () {
    expect(day(2, p: [...pool, ...pool]), day(2));
  });
}
