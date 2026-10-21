import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../../core/domain/phase.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_merger.dart';

/// Done items removed by "Clear all", kept so Undo can bring them back.
final class ClearedItems {
  const ClearedItems({required this.itemIds, required this.at});

  final List<String> itemIds;

  /// The tombstone time of the items and their sources.
  final DateTime at;

  bool get isEmpty => itemIds.isEmpty;
}

/// The one shopping list, stored on the phone.
class ShoppingRepository {
  ShoppingRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  /// Every live item with its live sources, oldest first.
  Stream<List<ShoppingItem>> watchItems() => _liveQuery().watch().map(_group);

  Future<List<ShoppingItem>> items() async => _group(await _liveQuery().get());

  /// Adds one thing, merging with an existing item of the same key.
  Future<AddOutcome> add(AddRequest request) =>
      _db.transaction(() => _add(request));

  /// Adds several things in one transaction (a recipe's ingredients).
  Future<List<AddOutcome>> addAll(List<AddRequest> requests) =>
      _db.transaction(() async {
        final outcomes = <AddOutcome>[];
        for (final r in requests) {
          outcomes.add(await _add(r));
        }
        return outcomes;
      });

  /// Moves an item to Done, or back to To buy.
  Future<void> setDone(String itemId, {required bool done}) {
    final now = _stamp.now();
    return (_db.update(
      _db.shoppingItems,
    )..where((t) => t.id.equals(itemId))).write(
      ShoppingItemsCompanion(
        done: Value(done),
        doneAt: Value(done ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  /// × on a row: gone straight away (no Undo, as designed).
  Future<void> remove(String itemId) =>
      _db.transaction(() => _tombstone([itemId], _stamp.now()));

  /// "Clear all": removes every Done item. Returns them for Undo.
  Future<ClearedItems> clearDone() => _db.transaction(() async {
    final done = await (_db.select(
      _db.shoppingItems,
    )..where((t) => t.done.equals(true) & t.deletedAt.isNull())).get();
    final at = _stamp.now();
    final ids = [for (final row in done) row.id];
    await _tombstone(ids, at);
    return ClearedItems(itemIds: ids, at: at);
  });

  /// Undo for [clearDone]. An item whose key was added again in the
  /// meantime stays cleared (the new one is already on the list).
  Future<void> restore(ClearedItems cleared) => _db.transaction(() async {
    for (final id in cleared.itemIds) {
      final row = await (_db.select(
        _db.shoppingItems,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null || row.deletedAt != cleared.at) continue;
      final clash =
          await (_db.select(_db.shoppingItems)
                ..where((t) => t.key.equals(row.key) & t.deletedAt.isNull()))
              .getSingleOrNull();
      if (clash != null) continue;
      final now = _stamp.now();
      await (_db.update(
        _db.shoppingItems,
      )..where((t) => t.id.equals(id))).write(
        ShoppingItemsCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(
            _db.shoppingSources,
          )..where((t) => t.itemId.equals(id) & t.deletedAt.equals(cleared.at)))
          .write(
            ShoppingSourcesCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
    }
  });

  Future<AddOutcome> _add(AddRequest request) async {
    final now = _stamp.now();
    final live =
        await (_liveQuery()..where(_db.shoppingItems.key.equals(request.key)))
            .get();
    final outcome = addToList(
      _group(live),
      request,
      newId: _stamp.newId,
      now: now,
    );
    switch (outcome) {
      case ItemCreated(:final item):
        await _db
            .into(_db.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                id: item.id,
                createdAt: now,
                updatedAt: now,
                key: item.key,
                foodId: Value(item.foodId),
                name: item.name,
                aisleId: item.aisleId,
              ),
            );
        await _insertSource(item.id, item.sources.single, now);
      case ItemMerged(:final item, :final source, :final reopened):
        if (source != null) await _insertSource(item.id, source, now);
        if (reopened) {
          await (_db.update(
            _db.shoppingItems,
          )..where((t) => t.id.equals(item.id))).write(
            ShoppingItemsCompanion(
              done: const Value(false),
              doneAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
        }
      case ItemUnchanged():
        break;
    }
    return outcome;
  }

  Future<void> _insertSource(String itemId, ShoppingSource s, DateTime now) =>
      _db
          .into(_db.shoppingSources)
          .insert(
            ShoppingSourcesCompanion.insert(
              id: s.id,
              createdAt: now,
              updatedAt: now,
              itemId: itemId,
              type: s.type.name,
              phaseId: Value(s.phase?.name),
              recipeId: Value(s.recipeId),
              amount: Value(s.amount),
              unit: Value(s.unit),
              qtyText: Value(s.qtyText),
            ),
          );

  Future<void> _tombstone(List<String> itemIds, DateTime at) async {
    if (itemIds.isEmpty) return;
    await (_db.update(
      _db.shoppingItems,
    )..where((t) => t.id.isIn(itemIds))).write(
      ShoppingItemsCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
    await (_db.update(
      _db.shoppingSources,
    )..where((t) => t.itemId.isIn(itemIds) & t.deletedAt.isNull())).write(
      ShoppingSourcesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _liveQuery() =>
      _db.select(_db.shoppingItems).join([
          leftOuterJoin(
            _db.shoppingSources,
            _db.shoppingSources.itemId.equalsExp(_db.shoppingItems.id) &
                _db.shoppingSources.deletedAt.isNull(),
          ),
        ])
        ..where(_db.shoppingItems.deletedAt.isNull())
        ..orderBy([
          OrderingTerm.asc(_db.shoppingItems.createdAt),
          OrderingTerm.asc(_db.shoppingSources.createdAt),
        ]);

  List<ShoppingItem> _group(List<TypedResult> rows) {
    final items = <String, ShoppingItemRow>{};
    final sources = <String, List<ShoppingSource>>{};
    for (final row in rows) {
      final item = row.readTable(_db.shoppingItems);
      items[item.id] = item;
      final list = sources.putIfAbsent(item.id, () => []);
      final s = row.readTableOrNull(_db.shoppingSources);
      if (s != null) {
        list.add(
          ShoppingSource(
            id: s.id,
            type: SourceType.values.byName(s.type),
            phase: s.phaseId == null ? null : Phase.values.byName(s.phaseId!),
            recipeId: s.recipeId,
            amount: s.amount,
            unit: s.unit,
            qtyText: s.qtyText,
          ),
        );
      }
    }
    return [
      for (final row in items.values)
        ShoppingItem(
          id: row.id,
          key: row.key,
          foodId: row.foodId,
          name: row.name,
          aisleId: row.aisleId,
          done: row.done,
          doneAt: row.doneAt,
          sources: sources[row.id]!,
          createdAt: row.createdAt,
        ),
    ];
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(appDatabaseProvider)),
);
