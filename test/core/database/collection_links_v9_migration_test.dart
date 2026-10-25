import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v8.dart' as v8;
import 'drift/app_database/generated/schema_v9.dart' as v9;

/// Schema 8 to 9 (links in My Collections): additive. A populated v8 database
/// keeps every saved recipe, diary entry and activity, and gains an empty
/// links table.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-20T09:00:00.000';

  test(
    'v8 saved recipes, diary entries and activities survive untouched',
    () async {
      const saved = [
        v8.SavedRecipeRefsData(
          id: 's1',
          createdAt: stamp,
          updatedAt: stamp,
          providerId: 'moon-cycle',
          refId: 'frittata',
          title: 'Frittata',
        ),
      ];
      const entries = [
        v8.DiaryEntriesData(
          id: 'e1',
          createdAt: stamp,
          updatedAt: stamp,
          date: '2026-10-19',
          meal: 'lunch',
          kind: 'food',
          itemId: 'apple',
          title: 'Apple',
          amount: 1,
          unit: 'serving',
        ),
      ];
      const activities = [
        v8.DiaryActivitiesData(
          id: 'a1',
          createdAt: stamp,
          updatedAt: stamp,
          date: '2026-10-19',
          type: 'walk',
          minutes: 30,
        ),
      ];
      await verifier.testWithDataIntegrity(
        oldVersion: 8,
        newVersion: 9,
        createOld: v8.DatabaseAtV8.new,
        createNew: v9.DatabaseAtV9.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.savedRecipeRefs, saved);
          batch.insertAll(oldDb.diaryEntries, entries);
          batch.insertAll(oldDb.diaryActivities, activities);
        },
        validateItems: (newDb) async {
          expect(
            (await newDb.select(newDb.savedRecipeRefs).get()).map(
              (r) => r.title,
            ),
            ['Frittata'],
          );
          expect(await newDb.select(newDb.diaryEntries).get(), hasLength(1));
          expect(await newDb.select(newDb.diaryActivities).get(), hasLength(1));
          expect(await newDb.select(newDb.collectionLinks).get(), isEmpty);
        },
      );
    },
  );

  test('the migrated database accepts links', () async {
    final schema = await verifier.schemaAt(8);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);
    final now = DateTime(2026, 10, 20, 9);
    await db
        .into(db.collectionLinks)
        .insert(
          CollectionLinksCompanion.insert(
            id: 'l1',
            createdAt: now,
            updatedAt: now,
            category: 'workouts',
            url: 'https://www.youtube.com/watch?v=x',
            title: 'Morning flow',
            platform: 'youtube',
            note: const Value('Gentle'),
          ),
        );
    expect(await db.select(db.collectionLinks).get(), hasLength(1));
    await db.close();
  });
}
