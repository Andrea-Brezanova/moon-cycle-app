import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v7.dart' as v7;
import 'drift/app_database/generated/schema_v8.dart' as v8;

/// Schema 7 to 8 (activity logging): additive. A populated v7 database keeps
/// every diary entry and note, and gains an empty activities table.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-18T09:00:00.000';

  test('v7 diary entries and notes survive untouched', () async {
    const entries = [
      v7.DiaryEntriesData(
        id: 'e1',
        createdAt: stamp,
        updatedAt: stamp,
        date: '2026-10-17',
        meal: 'breakfast',
        kind: 'food',
        itemId: 'apple',
        title: 'Apple',
        amount: 1,
        unit: 'serving',
        note: 'a note',
      ),
    ];
    const notes = [
      v7.DiaryNotesData(
        id: 'n1',
        createdAt: stamp,
        updatedAt: stamp,
        date: '2026-10-17',
        title: 'Sunday',
        body: 'Walked by the river.',
      ),
      v7.DiaryNotesData(
        id: 'n2',
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: stamp,
        date: '2026-10-16',
        body: '',
      ),
    ];
    await verifier.testWithDataIntegrity(
      oldVersion: 7,
      newVersion: 8,
      createOld: v7.DatabaseAtV7.new,
      createNew: v8.DatabaseAtV8.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.diaryEntries, entries);
        batch.insertAll(oldDb.diaryNotes, notes);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.diaryEntries).get(), hasLength(1));
        expect(
          (await newDb.select(newDb.diaryNotes).get()).map(
            (n) => (n.id, n.title, n.body, n.deletedAt != null),
          ),
          unorderedEquals([
            ('n1', 'Sunday', 'Walked by the river.', false),
            ('n2', null, '', true),
          ]),
        );
        expect(await newDb.select(newDb.diaryActivities).get(), isEmpty);
      },
    );
  });

  test('the migrated database accepts activities', () async {
    final schema = await verifier.schemaAt(7);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    final now = DateTime(2026, 10, 18, 9);
    await db
        .into(db.diaryActivities)
        .insert(
          DiaryActivitiesCompanion.insert(
            id: 'a1',
            createdAt: now,
            updatedAt: now,
            date: LocalDate(2026, 10, 18),
            type: 'walk',
            minutes: const Value(30),
          ),
        );
    expect(await db.select(db.diaryActivities).get(), hasLength(1));
    await db.close();
  });
}
