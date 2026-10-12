import 'package:moon_cycle/core/database/row_ids.dart';

/// Predictable ids (`id-1`, `id-2`, …) and a clock that moves one second per
/// call, so ordering by creation time is stable.
RowStamp fakeStamp({DateTime? start}) {
  var ids = 0;
  var time = start ?? DateTime.utc(2026, 10, 4, 9);
  return RowStamp(
    newId: () => 'id-${++ids}',
    now: () => time = time.add(const Duration(seconds: 1)),
  );
}
