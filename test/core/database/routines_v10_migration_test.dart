import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v10.dart' as v10;
import 'drift/app_database/generated/schema_v9.dart' as v9;

/// Schema 9 to 10 (My Routines, DRAFT): additive. A populated v9 database keeps
/// its saved links and recipes and gains two empty routine tables.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-20T09:00:00.000';

  test('v9 links and saved recipes survive untouched', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 9,
      newVersion: 10,
      createOld: v9.DatabaseAtV9.new,
      createNew: v10.DatabaseAtV10.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.collectionLinks, const [
          v9.CollectionLinksData(
            id: 'l1',
            createdAt: stamp,
            updatedAt: stamp,
            category: 'workouts',
            url: 'https://www.youtube.com/watch?v=x',
            title: 'Morning flow',
            platform: 'youtube',
          ),
        ]);
        batch.insertAll(oldDb.savedRecipeRefs, const [
          v9.SavedRecipeRefsData(
            id: 's1',
            createdAt: stamp,
            updatedAt: stamp,
            providerId: 'moon-cycle',
            refId: 'frittata',
            title: 'Frittata',
          ),
        ]);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.collectionLinks).get()).map((r) => r.title),
          ['Morning flow'],
        );
        expect(await newDb.select(newDb.savedRecipeRefs).get(), hasLength(1));
        expect(await newDb.select(newDb.routines).get(), isEmpty);
        expect(await newDb.select(newDb.routineSteps).get(), isEmpty);
      },
    );
  });

  test('the migrated database accepts routines', () async {
    final schema = await verifier.schemaAt(9);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);
    final now = DateTime(2026, 10, 20, 9);
    await db
        .into(db.routines)
        .insert(
          RoutinesCompanion.insert(
            id: 'r1',
            createdAt: now,
            updatedAt: now,
            title: 'Morning stretch',
          ),
        );
    expect(await db.select(db.routines).get(), hasLength(1));
    await db.close();
  });
}
