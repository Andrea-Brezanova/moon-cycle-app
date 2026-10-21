import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v5.dart' as v5;
import 'drift/app_database/generated/schema_v6.dart' as v6;

/// Schema 5 to 6 (My Diary): a populated v5 database keeps every diary entry,
/// including a deleted one, and gains an empty note and the symptom table.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-18T09:00:00.000';

  v5.DiaryEntriesData old(
    String id,
    String date,
    String meal,
    String kind,
    String itemId,
    String title, {
    double amount = 1,
    String unit = 'serving',
    String? deletedAt,
  }) => v5.DiaryEntriesData(
    id: id,
    createdAt: stamp,
    updatedAt: stamp,
    deletedAt: deletedAt,
    date: date,
    meal: meal,
    kind: kind,
    itemId: itemId,
    title: title,
    amount: amount,
    unit: unit,
  );

  test('v5 diary entries survive with a null note', () async {
    final before = [
      old('a', '2026-10-17', 'breakfast', 'food', 'apple', 'Apple'),
      old(
        'b',
        '2026-10-17',
        'dinner',
        'recipe',
        'lentil-spinach-tomato-stew',
        'Lentil stew',
        amount: 1.5,
      ),
      old(
        'c',
        '2026-10-16',
        'snack',
        'food',
        'almond',
        'Almond',
        amount: 30,
        unit: 'g',
      ),
      old('d', '2026-10-16', 'lunch', 'food', 'kale', 'Kale', deletedAt: stamp),
    ];
    final expected = [
      for (final e in before)
        v6.DiaryEntriesData(
          id: e.id,
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
          deletedAt: e.deletedAt,
          date: e.date,
          meal: e.meal,
          kind: e.kind,
          itemId: e.itemId,
          title: e.title,
          amount: e.amount,
          unit: e.unit,
          note: null,
        ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 5,
      newVersion: 6,
      createOld: v5.DatabaseAtV5.new,
      createNew: v6.DatabaseAtV6.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) =>
          batch.insertAll(oldDb.diaryEntries, before),
      validateItems: (newDb) async {
        expect(
          await newDb.select(newDb.diaryEntries).get(),
          unorderedEquals(expected),
        );
      },
    );
  });

  test('the migrated database accepts symptoms, notes and own meals', () async {
    final schema = await verifier.schemaAt(5);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    final now = DateTime(2026, 10, 18, 9);
    await db
        .into(db.symptomCheckins)
        .insert(
          SymptomCheckinsCompanion.insert(
            id: 's1',
            createdAt: now,
            updatedAt: now,
            date: LocalDate(2026, 10, 18),
            category: 'body',
            symptom: 'cramps',
          ),
        );
    expect(await db.select(db.symptomCheckins).get(), hasLength(1));
    await db.close();
  });
}
