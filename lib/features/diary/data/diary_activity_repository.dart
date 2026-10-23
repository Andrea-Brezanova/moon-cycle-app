import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../../core/domain/local_date.dart';
import '../domain/diary_activity.dart';

/// Movement the user chose to note, stored on the phone only (encrypted
/// database). Nothing is estimated or sent anywhere.
class DiaryActivityRepository {
  DiaryActivityRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  SimpleSelectStatement<$DiaryActivitiesTable, DiaryActivityRow> _live() =>
      _db.select(_db.diaryActivities)..where((t) => t.deletedAt.isNull());

  /// Every activity, newest day first, and within a day the latest first.
  Stream<List<DiaryActivity>> watchAll() =>
      (_live()..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
          .watch()
          .map((rows) => [for (final r in rows) ?_toDomain(r)]);

  Future<List<DiaryActivity>> all() => watchAll().first;

  Future<DiaryActivity?> byId(String id) async {
    final r = await (_live()..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  /// A new activity. [minutes] outside 1 to [maxActivityMinutes] is stored as
  /// "not given".
  Future<DiaryActivity?> add({
    required LocalDate date,
    required ActivityType type,
    String? customName,
    int? minutes,
    ActivityIntensity? intensity,
    String? note,
  }) async {
    final now = _stamp.now();
    final id = _stamp.newId();
    await _db
        .into(_db.diaryActivities)
        .insert(
          DiaryActivitiesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            date: date,
            type: type.name,
            customName: Value(_name(type, customName)),
            minutes: Value(_minutes(minutes)),
            intensity: Value(intensity?.name),
            note: Value(_clean(note)),
          ),
        );
    return byId(id);
  }

  Future<void> update(
    String id, {
    required LocalDate date,
    required ActivityType type,
    String? customName,
    int? minutes,
    ActivityIntensity? intensity,
    String? note,
  }) =>
      (_db.update(
        _db.diaryActivities,
      )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
        DiaryActivitiesCompanion(
          date: Value(date),
          type: Value(type.name),
          customName: Value(_name(type, customName)),
          minutes: Value(_minutes(minutes)),
          intensity: Value(intensity?.name),
          note: Value(_clean(note)),
          updatedAt: Value(_stamp.now()),
        ),
      );

  /// Deletes an activity: the row is tombstoned like every user row, and its
  /// name and note are emptied so they are not kept.
  Future<void> delete(String id) {
    final now = _stamp.now();
    return (_db.update(
      _db.diaryActivities,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
      DiaryActivitiesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        customName: const Value(null),
        note: const Value(null),
      ),
    );
  }

  String? _clean(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  String? _name(ActivityType type, String? name) =>
      type == ActivityType.other ? _clean(name) : null;

  int? _minutes(int? m) =>
      m == null || m < 1 || m > maxActivityMinutes ? null : m;

  /// A row with an unknown type (from a future version) is left out.
  DiaryActivity? _toDomain(DiaryActivityRow r) {
    final type = ActivityType.fromKey(r.type);
    if (type == null) return null;
    return DiaryActivity(
      id: r.id,
      date: r.date,
      type: type,
      customName: r.customName,
      minutes: r.minutes,
      intensity: ActivityIntensity.fromKey(r.intensity),
      note: r.note,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}

final diaryActivityRepositoryProvider = Provider<DiaryActivityRepository>(
  (ref) => DiaryActivityRepository(ref.watch(appDatabaseProvider)),
);

/// Every activity, newest first.
final diaryActivitiesProvider = StreamProvider.autoDispose<List<DiaryActivity>>(
  (ref) => ref.watch(diaryActivityRepositoryProvider).watchAll(),
);
