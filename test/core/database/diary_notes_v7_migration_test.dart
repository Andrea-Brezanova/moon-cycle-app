import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v6.dart' as v6;
import 'drift/app_database/generated/schema_v7.dart' as v7;

/// Schema 6 to 7 (diary notes): additive. A populated v6 database keeps every
/// diary entry and symptom check-in, and gains an empty notes table.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-18T09:00:00.000';

  test('v6 diary entries and symptoms survive untouched', () async {
    final entries = [
      const v6.DiaryEntriesData(
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
      const v6.DiaryEntriesData(
        id: 'e2',
        createdAt: stamp,
        updatedAt: stamp,
        deletedAt: stamp,
        date: '2026-10-16',
        meal: 'snack',
        kind: 'food',
        itemId: 'almond',
        title: 'Almond',
        amount: 30,
        unit: 'g',
      ),
    ];
    final symptoms = [
      const v6.SymptomCheckinsData(
        id: 's1',
        createdAt: stamp,
        updatedAt: stamp,
        date: '2026-10-17',
        category: 'body',
        symptom: 'cramps',
        severity: 'mild',
      ),
    ];
    await verifier.testWithDataIntegrity(
      oldVersion: 6,
      newVersion: 7,
      createOld: v6.DatabaseAtV6.new,
      createNew: v7.DatabaseAtV7.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.diaryEntries, entries);
        batch.insertAll(oldDb.symptomCheckins, symptoms);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.diaryEntries).get()).map(
            (e) => (e.id, e.title, e.note, e.deletedAt != null),
          ),
          unorderedEquals([
            ('e1', 'Apple', 'a note', false),
            ('e2', 'Almond', null, true),
          ]),
        );
        expect(await newDb.select(newDb.symptomCheckins).get(), hasLength(1));
        expect(await newDb.select(newDb.diaryNotes).get(), isEmpty);
      },
    );
  });

  test('the migrated database accepts notes', () async {
    final schema = await verifier.schemaAt(6);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 7);
    final now = DateTime(2026, 10, 18, 9);
    await db
        .into(db.diaryNotes)
        .insert(
          DiaryNotesCompanion.insert(
            id: 'n1',
            createdAt: now,
            updatedAt: now,
            date: LocalDate(2026, 10, 18),
            body: 'hello',
          ),
        );
    expect(await db.select(db.diaryNotes).get(), hasLength(1));
    await db.close();
  });
}
