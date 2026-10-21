import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../../core/domain/local_date.dart';
import '../domain/cycle_profile.dart';
import '../domain/period_log.dart';

/// The user's cycle profile and period history, stored on the phone.
class CycleRepository {
  CycleRepository(this._db, [RowStamp? stamp]) : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  Stream<CycleProfile?> watchProfile() => _liveProfiles()
      .watchSingleOrNull()
      .map((row) => row == null ? null : _profile(row));

  Future<CycleProfile?> profile() async {
    final row = await _liveProfiles().getSingleOrNull();
    return row == null ? null : _profile(row);
  }

  /// Creates the profile, or updates the one that exists.
  Future<void> saveProfile(CycleProfile profile) async {
    final now = _stamp.now();
    final existing = await _liveProfiles().getSingleOrNull();
    final values = CycleProfilesCompanion(
      cycleLength: Value(profile.typicalCycleLength),
      periodLength: Value(profile.typicalPeriodLength),
      lutealLength: Value(profile.lutealLength),
      useHistoryAverages: Value(profile.useHistoryAverages),
      updatedAt: Value(now),
    );
    if (existing == null) {
      await _db
          .into(_db.cycleProfiles)
          .insert(
            values.copyWith(id: Value(_stamp.newId()), createdAt: Value(now)),
          );
    } else {
      await (_db.update(
        _db.cycleProfiles,
      )..where((t) => t.id.equals(existing.id))).write(values);
    }
  }

  /// Every logged period, newest first.
  Stream<List<PeriodLog>> watchPeriodLogs() =>
      _livePeriodLogs().watch().map((rows) => rows.map(_log).toList());

  Future<List<PeriodLog>> periodLogs() async =>
      (await _livePeriodLogs().get()).map(_log).toList();

  /// Logs a period that started on [start]. If one is already logged for that
  /// day, it is updated instead of duplicated (plan §6.2).
  Future<PeriodLog> logPeriod(
    LocalDate start, {
    LocalDate? end,
    PeriodLogSource source = PeriodLogSource.manual,
    bool isEstimated = false,
  }) => _db.transaction(() async {
    final now = _stamp.now();
    final existing =
        await (_db.select(_db.periodLogs)..where(
              (t) => t.startDate.equalsValue(start) & t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (existing != null) {
      final updated = existing.copyWith(
        endDate: Value(end ?? existing.endDate),
        isEstimated: isEstimated,
        updatedAt: now,
      );
      await _db.update(_db.periodLogs).replace(updated);
      return _log(updated);
    }
    final row = PeriodLogRow(
      id: _stamp.newId(),
      createdAt: now,
      updatedAt: now,
      startDate: start,
      endDate: end,
      source: source.name,
      isEstimated: isEstimated,
    );
    await _db.into(_db.periodLogs).insert(row);
    return _log(row);
  });

  /// Changes a logged period's dates.
  Future<void> updatePeriodLog(
    String id, {
    required LocalDate start,
    LocalDate? end,
  }) => (_db.update(_db.periodLogs)..where((t) => t.id.equals(id))).write(
    PeriodLogsCompanion(
      startDate: Value(start),
      endDate: Value(end),
      isEstimated: const Value(false),
      updatedAt: Value(_stamp.now()),
    ),
  );

  /// Removes a logged period (as a tombstone, so it can sync later).
  Future<void> deletePeriodLog(String id) =>
      (_db.update(_db.periodLogs)..where((t) => t.id.equals(id))).write(
        PeriodLogsCompanion(
          deletedAt: Value(_stamp.now()),
          updatedAt: Value(_stamp.now()),
        ),
      );

  SimpleSelectStatement<$CycleProfilesTable, CycleProfileRow> _liveProfiles() =>
      _db.select(_db.cycleProfiles)
        ..where((t) => t.deletedAt.isNull())
        ..limit(1);

  SimpleSelectStatement<$PeriodLogsTable, PeriodLogRow> _livePeriodLogs() =>
      _db.select(_db.periodLogs)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);

  static CycleProfile _profile(CycleProfileRow row) => CycleProfile(
    typicalCycleLength: row.cycleLength,
    typicalPeriodLength: row.periodLength,
    lutealLength: row.lutealLength,
    useHistoryAverages: row.useHistoryAverages,
  );

  static PeriodLog _log(PeriodLogRow row) => PeriodLog(
    id: row.id,
    start: row.startDate,
    end: row.endDate,
    source: PeriodLogSource.values.byName(row.source),
    isEstimated: row.isEstimated,
  );
}

final cycleRepositoryProvider = Provider<CycleRepository>(
  (ref) => CycleRepository(ref.watch(appDatabaseProvider)),
);
