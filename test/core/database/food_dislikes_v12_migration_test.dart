import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v11.dart' as v11;
import 'drift/app_database/generated/schema_v12.dart' as v12;

/// Schema 11 to 12 (the food dislikes table for Build a Meal): additive. A new
/// empty table and index; every existing row, including avoidances, survives
/// untouched (docs/build-a-meal-2-data-model.md).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-20T09:00:00.000';

  test('v11 avoidances and routines survive; dislikes start empty', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 11,
      newVersion: 12,
      createOld: v11.DatabaseAtV11.new,
      createNew: v12.DatabaseAtV12.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.foodAvoidances, const [
          v11.FoodAvoidancesData(
            id: 'a1',
            createdAt: stamp,
            updatedAt: stamp,
            kind: 'allergen',
            allergenId: 'peanut',
          ),
        ]);
        batch.insertAll(oldDb.routines, const [
          v11.RoutinesData(
            id: 'r1',
            createdAt: stamp,
            updatedAt: stamp,
            title: 'Morning stretch',
            kind: 'routine',
          ),
        ]);
      },
      validateItems: (newDb) async {
        final avoid = await newDb.select(newDb.foodAvoidances).get();
        expect(avoid.single.allergenId, 'peanut');
        expect(
          (await newDb.select(newDb.routines).get()).single.title,
          'Morning stretch',
        );
        expect(await newDb.select(newDb.foodDislikes).get(), isEmpty);
      },
    );
  });

  test('the migrated database enforces one live dislike per food', () async {
    final schema = await verifier.schemaAt(11);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 12);
    final now = DateTime(2026, 11, 1, 9);
    Future<void> add(String id) => db
        .into(db.foodDislikes)
        .insert(
          FoodDislikesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            foodId: 'cilantro',
          ),
        );
    await add('d1');
    await expectLater(add('d2'), throwsA(isA<Exception>()));
    await (db.update(db.foodDislikes)..where((t) => t.id.equals('d1'))).write(
      FoodDislikesCompanion(deletedAt: Value(now)),
    );
    await add('d3'); // allowed once the first is a tombstone
    expect(await db.select(db.foodDislikes).get(), hasLength(2));
    await db.close();
  });
}
