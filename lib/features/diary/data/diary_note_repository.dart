import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../../core/domain/local_date.dart';
import '../domain/diary_note.dart';

/// Free-writing diary notes, stored on the phone only (encrypted database).
///
/// The text of a note is never logged or sent anywhere.
class DiaryNoteRepository {
  DiaryNoteRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  SimpleSelectStatement<$DiaryNotesTable, DiaryNoteRow> _live() =>
      _db.select(_db.diaryNotes)..where((t) => t.deletedAt.isNull());

  /// Every note, newest day first, and within a day the latest written first.
  Stream<List<DiaryNote>> watchAll() =>
      (_live()..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  /// One day's notes, oldest first (the order they were written).
  Stream<List<DiaryNote>> watchDay(LocalDate date) =>
      (_live()
            ..where((t) => t.date.equals(date.toString()))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  Stream<DiaryNote?> watchById(String id) =>
      (_live()..where((t) => t.id.equals(id))).watchSingleOrNull().map(
        (r) => r == null ? null : _toDomain(r),
      );

  Future<DiaryNote?> byId(String id) async {
    final r = await (_live()..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  Future<List<DiaryNote>> all() => watchAll().first;

  /// A new note. Returns it; a note with no title and no writing is not stored
  /// and null comes back.
  Future<DiaryNote?> add({
    required LocalDate date,
    String? title,
    required String body,
  }) async {
    if (isBlankNote(title: title, body: body)) return null;
    final now = _stamp.now();
    final id = _stamp.newId();
    await _db
        .into(_db.diaryNotes)
        .insert(
          DiaryNotesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            date: date,
            title: Value(_cleanTitle(title)),
            body: body,
          ),
        );
    return byId(id);
  }

  /// Changes a note's day, title or writing.
  Future<void> update(
    String id, {
    required LocalDate date,
    String? title,
    required String body,
  }) =>
      (_db.update(
        _db.diaryNotes,
      )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
        DiaryNotesCompanion(
          date: Value(date),
          title: Value(_cleanTitle(title)),
          body: Value(body),
          updatedAt: Value(_stamp.now()),
        ),
      );

  /// Deletes a note. The row is tombstoned like every user row, and its title
  /// and writing are emptied, so deleted writing is not kept on the phone.
  Future<void> delete(String id) {
    final now = _stamp.now();
    return (_db.update(
      _db.diaryNotes,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
      DiaryNotesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        title: const Value(null),
        body: const Value(''),
      ),
    );
  }

  String? _cleanTitle(String? title) {
    final t = title?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  DiaryNote _toDomain(DiaryNoteRow r) => DiaryNote(
    id: r.id,
    date: r.date,
    title: r.title,
    body: r.body,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}

final diaryNoteRepositoryProvider = Provider<DiaryNoteRepository>(
  (ref) => DiaryNoteRepository(ref.watch(appDatabaseProvider)),
);

/// Every note, newest first.
final diaryNotesProvider = StreamProvider.autoDispose<List<DiaryNote>>(
  (ref) => ref.watch(diaryNoteRepositoryProvider).watchAll(),
);

/// One day's notes.
final diaryNotesOnProvider = StreamProvider.autoDispose
    .family<List<DiaryNote>, LocalDate>(
      (ref, date) => ref.watch(diaryNoteRepositoryProvider).watchDay(date),
    );

/// One note, or null once it is deleted.
final diaryNoteProvider = StreamProvider.autoDispose.family<DiaryNote?, String>(
  (ref, id) => ref.watch(diaryNoteRepositoryProvider).watchById(id),
);
