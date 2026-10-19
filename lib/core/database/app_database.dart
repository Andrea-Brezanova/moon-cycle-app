import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_date.dart';
import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The app's one local database: every user table from the technical plan
/// (§8.3). It is encrypted on disk (see `database_opener.dart`).
///
/// Schema changes: bump [schemaVersion], add a step to [migration], then run
/// `dart run drift_dev make-migrations` to snapshot the schema and generate
/// the migration tests.
@DriftDatabase(
  tables: [
    CycleProfiles,
    PeriodLogs,
    UserPreferences,
    FoodAvoidances,
    ShoppingItems,
    ShoppingSources,
    AppStates,
    PersonalRecipes,
    DiaryEntries,
    SymptomCheckins,
    ProviderUsages,
    SavedRecipeRefs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Each step runs against its own version of the schema, so upgrading from
    // any old version builds exactly what that version had.
    onUpgrade: stepByStep(
      // 2: Settings › Appearance.
      from1To2: (m, schema) async {
        await m.addColumn(
          schema.userPreferences,
          schema.userPreferences.appearance,
        );
      },
      // 3: personal (generated) recipes. Additive: nothing existing changes.
      from2To3: (m, schema) async {
        await m.createTable(schema.personalRecipes);
        await m.createIndex(schema.personalRecipesOwnerKey);
      },
      // 4: the food diary. Additive.
      from3To4: (m, schema) async {
        await m.createTable(schema.diaryEntries);
        await m.createIndex(schema.diaryEntriesItemLive);
      },
      // 5: external provider usage and saved recipe references. Additive.
      from4To5: (m, schema) async {
        await m.createTable(schema.providerUsages);
        await m.createTable(schema.savedRecipeRefs);
        await m.createIndex(schema.savedRecipeRefsLive);
      },
      // 6: My Diary. A note on meals and symptom check-ins. Additive: existing
      // diary rows keep every value and get a null note.
      from5To6: (m, schema) async {
        await m.addColumn(schema.diaryEntries, schema.diaryEntries.note);
        await m.createTable(schema.symptomCheckins);
        await m.createIndex(schema.symptomCheckinsLive);
      },
    ),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// The open database. Set in `main()` once the encrypted file is open;
/// tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider is set in main()'),
);
