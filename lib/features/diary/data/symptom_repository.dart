import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../../core/domain/local_date.dart';
import '../domain/symptoms.dart';

/// Daily symptom check-ins, stored on the phone only.
///
/// A day is a set of rows (one per answer), so a check-in can be changed
/// piece by piece; [saveDay] makes the stored rows match the form: answers
/// that are still there are updated, new ones added, removed ones tombstoned.
class SymptomRepository {
  SymptomRepository(this._db, [RowStamp? stamp]) : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  SimpleSelectStatement<$SymptomCheckinsTable, SymptomCheckinRow> _live() =>
      _db.select(_db.symptomCheckins)..where((t) => t.deletedAt.isNull());

  /// One day's check-in, or null when nothing is recorded.
  Stream<SymptomDay?> watchDay(LocalDate date) =>
      (_live()..where((t) => t.date.equals(date.toString()))).watch().map(
        (rows) => _day(date, rows),
      );

  /// Every day with a check-in, newest first.
  Stream<List<SymptomDay>> watchHistory({int limit = 60}) =>
      (_live()..orderBy([(t) => OrderingTerm.desc(t.date)])).watch().map((
        rows,
      ) {
        final byDay = <LocalDate, List<SymptomCheckinRow>>{};
        for (final r in rows) {
          byDay.putIfAbsent(r.date, () => []).add(r);
        }
        return [
          for (final e in byDay.entries.take(limit)) ?_day(e.key, e.value),
        ];
      });

  Future<SymptomDay?> day(LocalDate date) async => _day(
    date,
    await (_live()..where((t) => t.date.equals(date.toString()))).get(),
  );

  /// Stores [day] as the check-in for its date.
  Future<void> saveDay(SymptomDay day) => _db.transaction(() async {
    final wanted = <(String, String), ({String? severity, String? note})>{
      if (day.energy != null)
        ('energy', day.energy!.key): (severity: null, note: null),
      if (day.sleep != null)
        ('sleep', day.sleep!.key): (severity: null, note: null),
      for (final m in day.moods) ('mood', m.key): (severity: null, note: null),
      for (final e in day.body.entries)
        ('body', e.key.key): (severity: e.value?.key, note: null),
      if (day.note != null && day.note!.trim().isNotEmpty)
        ('note', 'note'): (severity: null, note: day.note!.trim()),
    };
    final existing =
        await (_live()..where((t) => t.date.equals(day.date.toString()))).get();
    final now = _stamp.now();
    final seen = <(String, String)>{};
    for (final row in existing) {
      final key = (row.category, row.symptom);
      final w = wanted[key];
      if (w == null) {
        await _tombstone(row.id, now);
      } else {
        seen.add(key);
        if (w.severity != row.severity || w.note != row.note) {
          await (_db.update(
            _db.symptomCheckins,
          )..where((t) => t.id.equals(row.id))).write(
            SymptomCheckinsCompanion(
              severity: Value(w.severity),
              note: Value(w.note),
              updatedAt: Value(now),
            ),
          );
        }
      }
    }
    for (final e in wanted.entries) {
      if (seen.contains(e.key)) continue;
      await _db
          .into(_db.symptomCheckins)
          .insert(
            SymptomCheckinsCompanion.insert(
              id: _stamp.newId(),
              createdAt: now,
              updatedAt: now,
              date: day.date,
              category: e.key.$1,
              symptom: e.key.$2,
              severity: Value(e.value.severity),
              note: Value(e.value.note),
            ),
          );
    }
  });

  /// Removes the whole check-in for [date].
  Future<void> clearDay(LocalDate date) async {
    final now = _stamp.now();
    await (_db.update(_db.symptomCheckins)
          ..where((t) => t.date.equals(date.toString()) & t.deletedAt.isNull()))
        .write(
          SymptomCheckinsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> _tombstone(String id, DateTime at) =>
      (_db.update(_db.symptomCheckins)..where((t) => t.id.equals(id))).write(
        SymptomCheckinsCompanion(deletedAt: Value(at), updatedAt: Value(at)),
      );

  SymptomDay? _day(LocalDate date, List<SymptomCheckinRow> rows) {
    if (rows.isEmpty) return null;
    EnergyLevel? energy;
    SleepQuality? sleep;
    final moods = <Mood>{};
    final body = <BodySymptom, Strength?>{};
    String? note;
    for (final r in rows) {
      switch (r.category) {
        case 'energy':
          energy = EnergyLevel.parse(r.symptom) ?? energy;
        case 'sleep':
          sleep = SleepQuality.parse(r.symptom) ?? sleep;
        case 'mood':
          if (Mood.parse(r.symptom) case final m?) moods.add(m);
        case 'body':
          if (BodySymptom.parse(r.symptom) case final b?) {
            body[b] = Strength.parse(r.severity);
          }
        case 'note':
          note = r.note;
      }
    }
    // Chip order, not insertion order.
    final orderedBody = {
      for (final b in BodySymptom.values)
        if (body.containsKey(b)) b: body[b],
    };
    final orderedMoods = {
      for (final m in Mood.values)
        if (moods.contains(m)) m,
    };
    final d = SymptomDay(
      date: date,
      energy: energy,
      sleep: sleep,
      moods: orderedMoods,
      body: orderedBody,
      note: note,
    );
    return d.isEmpty ? null : d;
  }
}

final symptomRepositoryProvider = Provider<SymptomRepository>(
  (ref) => SymptomRepository(ref.watch(appDatabaseProvider)),
);
