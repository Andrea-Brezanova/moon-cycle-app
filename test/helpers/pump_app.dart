import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/app.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/onboarding/application/onboarding_status.dart';

import 'test_catalogue.dart';

/// A fresh in-memory database, closed when the test ends. Query streams
/// close synchronously, so widget tests don't end with drift's clean-up
/// timer pending.
AppDatabase testDatabase() {
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  return db;
}

/// Pumps the whole app (dev flavour) on an in-memory database and returns
/// its provider container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
  AppDatabase? database,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev),
        ),
        appDatabaseProvider.overrideWithValue(database ?? testDatabase()),
        initialOnboardingCompletedProvider.overrideWithValue(onboarded),
        catalogueProvider.overrideWithValue(testCatalogue),
        ...overrides,
      ],
      child: const MoonCycleApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MoonCycleApp)));
}
