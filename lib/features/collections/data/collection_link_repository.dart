import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../domain/collection_link.dart';

/// Links saved in My Collections, on the phone only (encrypted database).
/// Nothing is fetched from a link, and nothing is sent anywhere.
class CollectionLinkRepository {
  CollectionLinkRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  SimpleSelectStatement<$CollectionLinksTable, CollectionLinkRow> _live() =>
      _db.select(_db.collectionLinks)..where((t) => t.deletedAt.isNull());

  /// Every link, newest first.
  Stream<List<CollectionLink>> watchAll() =>
      (_live()..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch().map(
        (rows) => [for (final r in rows) ?_toDomain(r)],
      );

  Future<List<CollectionLink>> all() => watchAll().first;

  Future<CollectionLink?> byId(String id) async {
    final r = await (_live()..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  /// Saves a link, or returns null when [address] can't be used (see
  /// [parseLinkAddress]) or [title] is empty.
  Future<CollectionLink?> add({
    required LinkCategory category,
    required String address,
    required String title,
    String? creator,
    String? note,
  }) async {
    final url = parseLinkAddress(address);
    final name = _clean(title);
    if (url == null || name == null) return null;
    final now = _stamp.now();
    final id = _stamp.newId();
    await _db
        .into(_db.collectionLinks)
        .insert(
          CollectionLinksCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            category: category.name,
            url: url.toString(),
            title: name,
            creator: Value(_clean(creator)),
            platform: platformOf(url).name,
            note: Value(_clean(note)),
          ),
        );
    return byId(id);
  }

  /// Changes a link, including its category. Returns false (and changes
  /// nothing) when the address or title can't be used.
  Future<bool> update(
    String id, {
    required LinkCategory category,
    required String address,
    required String title,
    String? creator,
    String? note,
  }) async {
    final url = parseLinkAddress(address);
    final name = _clean(title);
    if (url == null || name == null) return false;
    final changed =
        await (_db.update(
          _db.collectionLinks,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          CollectionLinksCompanion(
            category: Value(category.name),
            url: Value(url.toString()),
            title: Value(name),
            creator: Value(_clean(creator)),
            platform: Value(platformOf(url).name),
            note: Value(_clean(note)),
            updatedAt: Value(_stamp.now()),
          ),
        );
    return changed > 0;
  }

  /// Moves a link to another category.
  Future<void> setCategory(String id, LinkCategory category) =>
      (_db.update(
        _db.collectionLinks,
      )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
        CollectionLinksCompanion(
          category: Value(category.name),
          updatedAt: Value(_stamp.now()),
        ),
      );

  /// Deletes a link: the row is tombstoned like every user row, and its
  /// address, title, creator and note are emptied so they are not kept.
  Future<void> delete(String id) {
    final now = _stamp.now();
    return (_db.update(
      _db.collectionLinks,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
      CollectionLinksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        url: const Value(''),
        title: const Value(''),
        creator: const Value(null),
        note: const Value(null),
      ),
    );
  }

  String? _clean(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// A row with an unknown category (from a future version) or a damaged
  /// address is left out.
  CollectionLink? _toDomain(CollectionLinkRow r) {
    final category = LinkCategory.fromKey(r.category);
    final url = parseLinkAddress(r.url);
    if (category == null || url == null) return null;
    return CollectionLink(
      id: r.id,
      category: category,
      url: url,
      title: r.title,
      platform: LinkPlatform.fromKey(r.platform),
      creator: r.creator,
      note: r.note,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}

final collectionLinkRepositoryProvider = Provider<CollectionLinkRepository>(
  (ref) => CollectionLinkRepository(ref.watch(appDatabaseProvider)),
);

/// Every saved link, newest first.
final collectionLinksProvider =
    StreamProvider.autoDispose<List<CollectionLink>>(
      (ref) => ref.watch(collectionLinkRepositoryProvider).watchAll(),
    );
