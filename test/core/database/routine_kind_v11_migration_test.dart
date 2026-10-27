import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';

import 'drift/app_database/generated/schema.dart';
import 'drift/app_database/generated/schema_v10.dart' as v10;
import 'drift/app_database/generated/schema_v11.dart' as v11;

/// Schema 10 to 11 (a `kind` column on routines, so built workouts can be kept
/// beside routines): additive with a default. Every existing routine and step
/// survives untouched and stays a routine.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const stamp = '2026-10-20T09:00:00.000';

  test('v10 routines and steps survive and become routines', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 10,
      newVersion: 11,
      createOld: v10.DatabaseAtV10.new,
      createNew: v11.DatabaseAtV11.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.routines, const [
          v10.RoutinesData(
            id: 'r1',
            createdAt: stamp,
            updatedAt: stamp,
            title: 'Morning stretch',
            note: 'Gentle',
          ),
        ]);
        batch.insertAll(oldDb.routineSteps, const [
          v10.RoutineStepsData(
            id: 's1',
            createdAt: stamp,
            updatedAt: stamp,
            routineId: 'r1',
            position: 0,
            kind: 'text',
            body: 'Five slow breaths',
          ),
        ]);
      },
      validateItems: (newDb) async {
        final routines = await newDb.select(newDb.routines).get();
        expect(routines.single.title, 'Morning stretch');
        expect(routines.single.note, 'Gentle');
        expect(routines.single.kind, 'routine');
        final steps = await newDb.select(newDb.routineSteps).get();
        expect(steps.single.body, 'Five slow breaths');
      },
    );
  });

  test('the migrated database accepts a workout', () async {
    final schema = await verifier.schemaAt(10);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 11);
    final now = DateTime(2026, 10, 20, 9);
    await db
        .into(db.routines)
        .insert(
          RoutinesCompanion.insert(
            id: 'w1',
            createdAt: now,
            updatedAt: now,
            title: 'Basics',
            kind: const Value('workout'),
          ),
        );
    expect((await db.select(db.routines).getSingle()).kind, 'workout');
    await db.close();
  });
}
