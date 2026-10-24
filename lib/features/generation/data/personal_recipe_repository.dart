import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../../content/domain/recipe.dart';
import '../domain/generation_result.dart';
import '../domain/personal_recipe.dart';
import '../domain/recipe_image_service.dart';
import '../domain/recipe_json.dart';

/// The user's generated recipes, stored on the phone. Every query is for one
/// owner: recipes of another account on the same phone are never returned.
class PersonalRecipeRepository {
  PersonalRecipeRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  /// The recipes of any of [ownerIds] (the local owner and the signed-in user),
  /// newest first.
  Stream<List<PersonalRecipe>> watchAllFor(List<String> ownerIds) =>
      (_db.select(_db.personalRecipes)
            ..where((t) => t.ownerId.isIn(ownerIds) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  Future<List<PersonalRecipe>> allFor(List<String> ownerIds) =>
      watchAllFor(ownerIds).first;

  /// One recipe by id, if it belongs to any of [ownerIds].
  Stream<PersonalRecipe?> watchByIdFor(List<String> ownerIds, String id) =>
      (_db.select(_db.personalRecipes)..where(
            (t) =>
                t.id.equals(id) &
                t.ownerId.isIn(ownerIds) &
                t.deletedAt.isNull(),
          ))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toDomain(row));

  /// One recipe by id, if it belongs to any of [ownerIds].
  Future<PersonalRecipe?> byIdFor(List<String> ownerIds, String id) async {
    final row =
        await (_db.select(_db.personalRecipes)..where(
              (t) =>
                  t.id.equals(id) &
                  t.ownerId.isIn(ownerIds) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Replaces what a recipe says (the user edited it). Its owner, origin and
  /// lifecycle stay as they were.
  Future<void> updateRecipe(String ownerId, String id, Recipe recipe) =>
      (_db.update(_db.personalRecipes)..where(
            (t) =>
                t.id.equals(id) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull(),
          ))
          .write(
            PersonalRecipesCompanion(
              title: Value(recipe.title),
              phase: Value(recipe.phase.name),
              recipeJson: Value(jsonEncode(recipeToJson(recipe))),
              updatedAt: Value(_stamp.now()),
            ),
          );

  /// Newest first.
  Stream<List<PersonalRecipe>> watchAll(String ownerId) =>
      (_db.select(_db.personalRecipes)
            ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  Future<List<PersonalRecipe>> all(String ownerId) => watchAll(ownerId).first;

  Future<PersonalRecipe?> byId(String ownerId, String id) async {
    final row =
        await (_db.select(_db.personalRecipes)..where(
              (t) =>
                  t.id.equals(id) &
                  t.ownerId.equals(ownerId) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Stream<PersonalRecipe?> watchById(String ownerId, String id) =>
      (_db.select(_db.personalRecipes)..where(
            (t) =>
                t.id.equals(id) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull(),
          ))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toDomain(row));

  Future<PersonalRecipe?> byIdempotencyKey(String ownerId, String key) async {
    final row =
        await (_db.select(_db.personalRecipes)..where(
              (t) =>
                  t.ownerId.equals(ownerId) &
                  t.idempotencyKey.equals(key) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// The newest saved recipe made from the same selection, if any.
  Future<PersonalRecipe?> byFingerprint(
    String ownerId,
    String fingerprint,
  ) async {
    final rows =
        await (_db.select(_db.personalRecipes)
              ..where(
                (t) =>
                    t.ownerId.equals(ownerId) &
                    t.fingerprint.equals(fingerprint) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : _toDomain(rows.single);
  }

  /// Saves [recipe]. Saving the same idempotency key again returns the row
  /// that is already there and changes nothing, so a retry never duplicates.
  Future<PersonalRecipe> save(PersonalRecipe recipe) =>
      _db.transaction(() async {
        final existing = await byIdempotencyKey(
          recipe.ownerId,
          recipe.idempotencyKey,
        );
        if (existing != null) return existing;
        final now = _stamp.now();
        await _db
            .into(_db.personalRecipes)
            .insert(
              PersonalRecipesCompanion.insert(
                id: recipe.id,
                createdAt: recipe.createdAt,
                updatedAt: now,
                ownerId: recipe.ownerId,
                idempotencyKey: recipe.idempotencyKey,
                fingerprint: recipe.fingerprint,
                title: recipe.recipe.title,
                phase: recipe.recipe.phase.name,
                recipeJson: jsonEncode(recipeToJson(recipe.recipe)),
                origin: recipe.provenance.origin.name,
                provenanceJson: jsonEncode(recipe.provenance.toJson()),
                lifecycle: Value(recipe.lifecycle.name),
                remoteId: Value(recipe.remoteId),
                imageStatus: Value(recipe.imageStatus.name),
                imageRefJson: Value(
                  recipe.imageRef == null
                      ? null
                      : jsonEncode(recipe.imageRef!.toJson()),
                ),
              ),
            );
        return recipe;
      });

  Future<void> setImage(
    String ownerId,
    String id, {
    required ImageStatus status,
    RecipeImageRef? ref,
  }) =>
      (_db.update(_db.personalRecipes)..where(
            (t) =>
                t.id.equals(id) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull(),
          ))
          .write(
            PersonalRecipesCompanion(
              imageStatus: Value(status.name),
              imageRefJson: ref == null
                  ? const Value.absent()
                  : Value(jsonEncode(ref.toJson())),
              updatedAt: Value(_stamp.now()),
            ),
          );

  /// Records where the recipe is in review (set from the server's answer).
  Future<void> setLifecycle(
    String ownerId,
    String id,
    RecipeLifecycle lifecycle,
  ) =>
      (_db.update(_db.personalRecipes)..where(
            (t) =>
                t.id.equals(id) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull(),
          ))
          .write(
            PersonalRecipesCompanion(
              lifecycle: Value(lifecycle.name),
              updatedAt: Value(_stamp.now()),
            ),
          );

  /// A tombstone, not a hard delete (the same rule as every user table).
  Future<void> delete(String ownerId, String id) {
    final now = _stamp.now();
    return (_db.update(_db.personalRecipes)..where(
          (t) =>
              t.id.equals(id) &
              t.ownerId.equals(ownerId) &
              t.deletedAt.isNull(),
        ))
        .write(
          PersonalRecipesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  PersonalRecipe _toDomain(PersonalRecipeRow r) => PersonalRecipe(
    recipe: recipeFromJson(jsonDecode(r.recipeJson) as Map<String, Object?>),
    ownerId: r.ownerId,
    idempotencyKey: r.idempotencyKey,
    fingerprint: r.fingerprint,
    provenance: Provenance.fromJson(
      jsonDecode(r.provenanceJson) as Map<String, Object?>,
    ),
    createdAt: r.createdAt,
    lifecycle: RecipeLifecycle.values.byName(r.lifecycle),
    imageStatus: ImageStatus.values.byName(r.imageStatus),
    remoteId: r.remoteId,
    imageRef: r.imageRefJson == null
        ? null
        : RecipeImageRef.fromJson(
            jsonDecode(r.imageRefJson!) as Map<String, Object?>,
          ),
  );
}

final personalRecipeRepositoryProvider = Provider<PersonalRecipeRepository>(
  (ref) => PersonalRecipeRepository(ref.watch(appDatabaseProvider)),
);
