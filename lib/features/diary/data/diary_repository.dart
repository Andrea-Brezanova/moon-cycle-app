import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../../core/domain/local_date.dart';
import '../domain/diary_entry.dart';

/// The food diary, stored on the phone only.
class DiaryRepository {
  DiaryRepository(this._db, [RowStamp? stamp]) : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  SimpleSelectStatement<$DiaryEntriesTable, DiaryEntryRow> _live() =>
      _db.select(_db.diaryEntries)..where((t) => t.deletedAt.isNull());

  /// One day's entries, oldest first within the day.
  Stream<List<DiaryEntry>> watchDay(LocalDate date) =>
      (_live()
            ..where((t) => t.date.equals(date.toString()))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  /// Every day that has entries, newest day first (the history).
  Stream<List<DiaryDay>> watchHistory({int limit = 60}) =>
      (_live()..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
          .watch()
          .map((rows) {
            final byDay = <LocalDate, List<DiaryEntry>>{};
            for (final r in rows) {
              byDay.putIfAbsent(r.date, () => []).add(_toDomain(r));
            }
            return [
              for (final e in byDay.entries.take(limit))
                DiaryDay(e.key, e.value),
            ];
          });

  /// One live entry by id, or null.
  Future<DiaryEntry?> entry(String id) async {
    final r = await (_live()..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  Future<List<DiaryEntry>> all() async => [
    for (final r
        in await (_live()..orderBy([(t) => OrderingTerm.asc(t.date)])).get())
      _toDomain(r),
  ];

  /// Adds [draft]. If the same item is already logged in that meal and unit,
  /// its amount grows instead. Returns the resulting entry.
  Future<DiaryEntry> add(DiaryDraft draft) => _db.transaction(() async {
    if (draft.kind == DiaryItemKind.custom) return _addCustom(draft);
    final existing =
        await (_live()..where(
              (t) =>
                  t.date.equals(draft.date.toString()) &
                  t.meal.equals(draft.meal.name) &
                  t.kind.equals(draft.kind.name) &
                  t.itemId.equals(draft.itemId) &
                  t.unit.equals(draft.unit.id),
            ))
            .getSingleOrNull();
    final now = _stamp.now();
    if (existing != null) {
      final total = existing.amount + draft.amount;
      await (_db.update(
        _db.diaryEntries,
      )..where((t) => t.id.equals(existing.id))).write(
        DiaryEntriesCompanion(
          amount: Value(total),
          // A note on the new log is kept; an earlier note is never erased.
          note: draft.note == null ? const Value.absent() : Value(draft.note),
          updatedAt: Value(now),
        ),
      );
      return _toDomain(
        existing.copyWith(
          amount: total,
          note: Value(draft.note ?? existing.note),
        ),
      );
    }
    final id = _stamp.newId();
    await _db
        .into(_db.diaryEntries)
        .insert(
          DiaryEntriesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            date: draft.date,
            meal: draft.meal.name,
            kind: draft.kind.name,
            itemId: draft.itemId,
            title: draft.title,
            amount: draft.amount,
            unit: draft.unit.id,
            note: Value(draft.note),
          ),
        );
    return _toDomain((await _live().get()).firstWhere((r) => r.id == id));
  });

  /// A typed meal: never merged with another (its item id is its own row id).
  Future<DiaryEntry> _addCustom(DiaryDraft draft) async {
    final id = _stamp.newId();
    final now = _stamp.now();
    await _db
        .into(_db.diaryEntries)
        .insert(
          DiaryEntriesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            date: draft.date,
            meal: draft.meal.name,
            kind: DiaryItemKind.custom.name,
            itemId: id,
            title: draft.title.trim(),
            amount: draft.amount,
            unit: draft.unit.id,
            note: Value(draft.note),
          ),
        );
    return _toDomain((await _live().get()).firstWhere((r) => r.id == id));
  }

  /// Changes an entry's amount, meal or day. If that lands on another entry
  /// with the same item and unit, the two are merged.
  Future<void> update(
    String id, {
    double? amount,
    DiaryMeal? meal,
    LocalDate? date,
    DiaryUnit? unit,
    Value<String?> note = const Value.absent(),
    String? title,
  }) => _db.transaction(() async {
    final row = await (_live()..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final target = (
      date: date ?? row.date,
      meal: meal?.name ?? row.meal,
      unit: unit?.id ?? row.unit,
      amount: amount ?? row.amount,
    );
    final clash = row.kind == DiaryItemKind.custom.name
        ? null
        : await (_live()..where(
                (t) =>
                    t.id.isNotValue(id) &
                    t.date.equals(target.date.toString()) &
                    t.meal.equals(target.meal) &
                    t.kind.equals(row.kind) &
                    t.itemId.equals(row.itemId) &
                    t.unit.equals(target.unit),
              ))
              .getSingleOrNull();
    final now = _stamp.now();
    if (clash != null) {
      await (_db.update(
        _db.diaryEntries,
      )..where((t) => t.id.equals(clash.id))).write(
        DiaryEntriesCompanion(
          amount: Value(clash.amount + target.amount),
          note: note.present && note.value != null
              ? note
              : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      await _tombstone(id, now);
      return;
    }
    await (_db.update(_db.diaryEntries)..where((t) => t.id.equals(id))).write(
      DiaryEntriesCompanion(
        amount: Value(target.amount),
        meal: Value(target.meal),
        date: Value(target.date),
        unit: Value(target.unit),
        note: note,
        title: title == null ? const Value.absent() : Value(title.trim()),
        updatedAt: Value(now),
      ),
    );
  });

  /// A tombstone, not a hard delete (the same rule as every user table).
  Future<void> delete(String id) => _tombstone(id, _stamp.now());

  Future<void> _tombstone(String id, DateTime at) =>
      (_db.update(_db.diaryEntries)..where((t) => t.id.equals(id))).write(
        DiaryEntriesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
      );

  DiaryEntry _toDomain(DiaryEntryRow r) => DiaryEntry(
    id: r.id,
    date: r.date,
    meal: DiaryMeal.values.byName(r.meal),
    kind: DiaryItemKind.values.byName(r.kind),
    itemId: r.itemId,
    title: r.title,
    amount: r.amount,
    unit: DiaryUnit.parse(r.unit),
    createdAt: r.createdAt,
    note: r.note,
  );
}

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(ref.watch(appDatabaseProvider)),
);
