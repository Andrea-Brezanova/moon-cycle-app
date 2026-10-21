// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldCycleProfilesData = <v1.CycleProfilesData>[];
    final expectedNewCycleProfilesData = <v2.CycleProfilesData>[];

    final oldPeriodLogsData = <v1.PeriodLogsData>[];
    final expectedNewPeriodLogsData = <v2.PeriodLogsData>[];

    final oldUserPreferencesData = <v1.UserPreferencesData>[];
    final expectedNewUserPreferencesData = <v2.UserPreferencesData>[];

    final oldFoodAvoidancesData = <v1.FoodAvoidancesData>[];
    final expectedNewFoodAvoidancesData = <v2.FoodAvoidancesData>[];

    final oldShoppingItemsData = <v1.ShoppingItemsData>[];
    final expectedNewShoppingItemsData = <v2.ShoppingItemsData>[];

    final oldShoppingSourcesData = <v1.ShoppingSourcesData>[];
    final expectedNewShoppingSourcesData = <v2.ShoppingSourcesData>[];

    final oldAppStatesData = <v1.AppStatesData>[];
    final expectedNewAppStatesData = <v2.AppStatesData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.cycleProfiles, oldCycleProfilesData);
        batch.insertAll(oldDb.periodLogs, oldPeriodLogsData);
        batch.insertAll(oldDb.userPreferences, oldUserPreferencesData);
        batch.insertAll(oldDb.foodAvoidances, oldFoodAvoidancesData);
        batch.insertAll(oldDb.shoppingItems, oldShoppingItemsData);
        batch.insertAll(oldDb.shoppingSources, oldShoppingSourcesData);
        batch.insertAll(oldDb.appStates, oldAppStatesData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewCycleProfilesData,
          await newDb.select(newDb.cycleProfiles).get(),
        );
        expect(
          expectedNewPeriodLogsData,
          await newDb.select(newDb.periodLogs).get(),
        );
        expect(
          expectedNewUserPreferencesData,
          await newDb.select(newDb.userPreferences).get(),
        );
        expect(
          expectedNewFoodAvoidancesData,
          await newDb.select(newDb.foodAvoidances).get(),
        );
        expect(
          expectedNewShoppingItemsData,
          await newDb.select(newDb.shoppingItems).get(),
        );
        expect(
          expectedNewShoppingSourcesData,
          await newDb.select(newDb.shoppingSources).get(),
        );
        expect(
          expectedNewAppStatesData,
          await newDb.select(newDb.appStates).get(),
        );
      },
    );
  });
}
