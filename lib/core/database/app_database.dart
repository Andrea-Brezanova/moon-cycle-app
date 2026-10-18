import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_date.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // 2: Settings › Appearance.
      if (from < 2) {
        await m.addColumn(userPreferences, userPreferences.appearance);
      }
      // 3: personal (generated) recipes. Additive: nothing existing changes.
      if (from < 3) {
        await m.createTable(personalRecipes);
        await m.createIndex(personalRecipesOwnerKey);
      }
      // 4: the food diary. Additive.
      if (from < 4) {
        await m.createTable(diaryEntries);
        await m.createIndex(diaryEntriesItemLive);
      }
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// The open database. Set in `main()` once the encrypted file is open;
/// tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider is set in main()'),
);
