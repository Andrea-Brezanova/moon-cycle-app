import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../domain/routine.dart';

/// My Routines (DRAFT, schema 10): reusable ordered lists of steps. A step is
/// a saved link, by reference, or a line of the user's own text. No schedule,
/// no reminders, no recommendations. Local only, in the encrypted database.
class RoutineRepository {
  RoutineRepository(this._db, [RowStamp? stamp]) : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  Future<String?> create(String title, {String? note}) async {
    final name = _clean(title);
    if (name == null) return null;
    final now = _stamp.now();
    final id = _stamp.newId();
    await _db
        .into(_db.routines)
        .insert(
          RoutinesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            title: name,
            note: Value(_clean(note)),
          ),
        );
    return id;
  }

  /// Every routine with its steps, newest first.
  Future<List<Routine>> all() async => _toDomain(await _liveRows());

  Stream<List<Routine>> watchAll() => _db
      .select(_db.routines)
      .watch()
      .asyncMap((_) async => _toDomain(await _liveRows()));

  Future<List<RoutineRow>> _liveRows() =>
      (_db.select(_db.routines)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Routine>> _toDomain(List<RoutineRow> rows) async => [
    for (final r in rows)
      Routine(
        id: r.id,
        title: r.title,
        note: r.note,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        steps: await steps(r.id),
      ),
  ];

  Future<Routine?> byId(String id) async {
    final row = await (_db.select(
      _db.routines,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : (await _toDomain([row])).single;
  }

  /// Changes a routine's note (empty clears it).
  Future<void> setNote(String id, String? note) =>
      (_db.update(
        _db.routines,
      )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
        RoutinesCompanion(
          note: Value(_clean(note)),
          updatedAt: Value(_stamp.now()),
        ),
      );

  Future<bool> rename(String id, String title) async {
    final name = _clean(title);
    if (name == null) return false;
    final n =
        await (_db.update(
          _db.routines,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          RoutinesCompanion(title: Value(name), updatedAt: Value(_stamp.now())),
        );
    return n > 0;
  }

  /// The live steps of a routine, in order.
  Future<List<RoutineStep>> steps(String routineId) async {
    final rows =
        await (_db.select(_db.routineSteps)
              ..where(
                (t) => t.routineId.equals(routineId) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        RoutineStep(
          id: r.id,
          position: r.position,
          linkId: r.kind == 'link' ? r.linkId : null,
          text: r.kind == 'text' ? r.body : null,
        ),
    ];
  }

  Future<String?> addLinkStep(String routineId, String linkId) =>
      _addStep(routineId, kind: 'link', linkId: linkId);

  Future<String?> addTextStep(String routineId, String text) {
    final body = _clean(text);
    return body == null
        ? Future.value()
        : _addStep(routineId, kind: 'text', body: body);
  }

  Future<String?> _addStep(
    String routineId, {
    required String kind,
    String? linkId,
    String? body,
  }) async {
    final exists =
        await (_db.select(_db.routines)
              ..where((t) => t.id.equals(routineId) & t.deletedAt.isNull()))
            .getSingleOrNull();
    if (exists == null) return null;
    final next = (await steps(routineId)).length;
    final now = _stamp.now();
    final id = _stamp.newId();
    await _db
        .into(_db.routineSteps)
        .insert(
          RoutineStepsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            routineId: routineId,
            position: next,
            kind: kind,
            linkId: Value(linkId),
            body: Value(body),
          ),
        );
    return id;
  }

  /// Removes a step (tombstone, text emptied) and closes the gap in order.
  Future<void> removeStep(String routineId, String stepId) async {
    final now = _stamp.now();
    await (_db.update(_db.routineSteps)..where(
          (t) =>
              t.id.equals(stepId) &
              t.routineId.equals(routineId) &
              t.deletedAt.isNull(),
        ))
        .write(
          RoutineStepsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            body: const Value(null),
            linkId: const Value(null),
          ),
        );
    await _renumber(routineId);
  }

  /// Moves a step to [newIndex] among the live steps.
  Future<void> moveStep(String routineId, String stepId, int newIndex) async {
    final live = await steps(routineId);
    final from = live.indexWhere((s) => s.id == stepId);
    if (from < 0) return;
    final ids = [for (final s in live) s.id]..removeAt(from);
    ids.insert(newIndex.clamp(0, ids.length), stepId);
    await _write(ids);
  }

  Future<void> _renumber(String routineId) async =>
      _write([for (final s in await steps(routineId)) s.id]);

  Future<void> _write(List<String> ids) async {
    final now = _stamp.now();
    for (final (i, id) in ids.indexed) {
      await (_db.update(_db.routineSteps)..where((t) => t.id.equals(id))).write(
        RoutineStepsCompanion(position: Value(i), updatedAt: Value(now)),
      );
    }
  }

  /// Deletes a routine and its steps: rows are tombstoned and the title, note
  /// and step text are emptied so they are not kept.
  Future<void> delete(String id) async {
    final now = _stamp.now();
    await (_db.update(
      _db.routineSteps,
    )..where((t) => t.routineId.equals(id) & t.deletedAt.isNull())).write(
      RoutineStepsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        body: const Value(null),
        linkId: const Value(null),
      ),
    );
    await (_db.update(
      _db.routines,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
      RoutinesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        title: const Value(''),
        note: const Value(null),
      ),
    );
  }

  String? _clean(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(ref.watch(appDatabaseProvider)),
);

/// Every routine, newest first, live.
final routinesProvider = StreamProvider.autoDispose<List<Routine>>(
  (ref) => ref.watch(routineRepositoryProvider).watchAll(),
);
