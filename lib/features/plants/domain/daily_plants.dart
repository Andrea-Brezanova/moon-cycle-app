import '../../../core/domain/stable_hash.dart';

/// How many plants a day suggests.
const plantsPerDay = 3;

/// The plants to suggest on one day, by food id.
///
/// [poolIds] are the eligible foods. They are put in an order fixed by
/// [seed] (which the caller builds from the cycle start and the phase), and the
/// suggestion walks along that order three foods per day. So, while the pool is
/// at least three foods long:
/// - the three are always distinct;
/// - the same [dayIndex] always gives the same three (stable all day);
/// - the next day gives the next three: no food repeats until the whole pool
///   has been shown, and then the walk wraps to the **least recently suggested**
///   foods, which are the ones at the start of the order;
/// - a different [seed] (the next cycle) is a different order.
///
/// [dayIndex] counts days along the phase; it may keep growing past the phase's
/// usual length (a late period), and it never assumes a cycle length. With a
/// pool of three or fewer, every food is returned (never padded).
List<String> dailyPlantIds({
  required Iterable<String> poolIds,
  required String seed,
  required int dayIndex,
  int count = plantsPerDay,
}) {
  final ordered = poolIds.toSet().toList()
    ..sort((a, b) {
      final byHash = stableHash('$seed|$a').compareTo(stableHash('$seed|$b'));
      return byHash != 0 ? byHash : a.compareTo(b);
    });
  if (ordered.length <= count) return ordered;
  final start = (dayIndex * count) % ordered.length;
  return [
    for (var i = 0; i < count; i++) ordered[(start + i) % ordered.length],
  ];
}
