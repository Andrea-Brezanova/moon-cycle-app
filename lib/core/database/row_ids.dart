import 'package:uuid/uuid.dart';

/// Makes ids and timestamps for new rows. Repositories take one so tests can
/// fix the clock and the ids.
class RowStamp {
  RowStamp({DateTime Function()? now, String Function()? newId})
    : now = now ?? DateTime.now,
      newId = newId ?? _uuid.v4;

  static const _uuid = Uuid();

  final DateTime Function() now;
  final String Function() newId;
}
