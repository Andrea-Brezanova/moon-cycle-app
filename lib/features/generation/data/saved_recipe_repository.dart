import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../domain/saved_recipe_ref.dart';

/// References to recipes the user saved (see [SavedRecipeRef]).
class SavedRecipeRepository {
  SavedRecipeRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  SimpleSelectStatement<$SavedRecipeRefsTable, SavedRecipeRefRow> _live() =>
      _db.select(_db.savedRecipeRefs)..where((t) => t.deletedAt.isNull());

  Stream<List<SavedRecipeRef>> watchAll() =>
      (_live()..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch().map(
        (rows) => [for (final r in rows) _toDomain(r)],
      );

  Future<List<SavedRecipeRef>> all() => watchAll().first;

  /// Saves a reference (once: saving it again changes nothing).
  Future<void> save({
    required String providerId,
    required String refId,
    required String title,
    String? externalId,
    String? sourceUrl,
  }) => _db.transaction(() async {
    final existing = await (_live()..where((t) => t.refId.equals(refId)))
        .getSingleOrNull();
    if (existing != null) return;
    final now = _stamp.now();
    await _db
        .into(_db.savedRecipeRefs)
        .insert(
          SavedRecipeRefsCompanion.insert(
            id: _stamp.newId(),
            createdAt: now,
            updatedAt: now,
            providerId: providerId,
            refId: refId,
            title: title,
            externalId: Value(externalId),
            sourceUrl: Value(sourceUrl),
          ),
        );
  });

  /// A tombstone, not a hard delete.
  Future<void> remove(String refId) {
    final now = _stamp.now();
    return (_db.update(
      _db.savedRecipeRefs,
    )..where((t) => t.refId.equals(refId) & t.deletedAt.isNull())).write(
      SavedRecipeRefsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  SavedRecipeRef _toDomain(SavedRecipeRefRow r) => SavedRecipeRef(
    id: r.id,
    providerId: r.providerId,
    refId: r.refId,
    externalId: r.externalId,
    title: r.title,
    sourceUrl: r.sourceUrl,
    savedAt: r.createdAt,
  );
}

final savedRecipeRepositoryProvider = Provider<SavedRecipeRepository>(
  (ref) => SavedRecipeRepository(ref.watch(appDatabaseProvider)),
);

/// Every saved reference, newest first.
final savedRecipeRefsProvider = StreamProvider<List<SavedRecipeRef>>(
  (ref) => ref.watch(savedRecipeRepositoryProvider).watchAll(),
);
