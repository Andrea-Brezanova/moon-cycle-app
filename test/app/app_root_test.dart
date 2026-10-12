import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/app_root.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/app/config/app_version.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/onboarding/application/onboarding_status.dart';
import 'package:moon_cycle/features/onboarding/presentation/welcome_page.dart';
import 'package:moon_cycle/features/privacy/data/local_data_wiper.dart';
import 'package:moon_cycle/features/reminders/application/reminder_providers.dart';
import 'package:moon_cycle/features/settings/presentation/delete_data_page.dart';

import '../helpers/fake_reminders.dart';
import '../helpers/golden_screen.dart';
import '../helpers/memory_key_store.dart';
import '../helpers/pump_app.dart';
import '../helpers/seed.dart';
import '../helpers/test_catalogue.dart';

/// Records the wipe instead of deleting files.
class FakeWiper extends LocalDataWiper {
  FakeWiper(AppDatabase db)
    : super(
        database: db,
        directory: Directory.systemTemp,
        keys: MemoryKeyStore(),
      );

  bool wiped = false;

  @override
  Future<void> wipe() async => wiped = true;
}

void main() {
  testWidgets('Delete my data wipes, then restarts at onboarding on fresh '
      'data', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final first = testDatabase();
    await seedCycle(tester, first, start: sampleStart);
    final wiper = FakeWiper(first);
    var opened = 0;

    await tester.pumpWidget(
      AppRoot(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(flavor: Flavor.dev),
          ),
          catalogueProvider.overrideWithValue(testCatalogue),
          appVersionProvider.overrideWithValue('1.0.0'),
          clockProvider.overrideWithValue(designNow),
          localDataWiperProvider.overrideWithValue(wiper),
          reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
        ],
        session: [
          appDatabaseProvider.overrideWithValue(first),
          initialOnboardingCompletedProvider.overrideWithValue(true),
        ],
        openSession: () async {
          opened++;
          return [
            appDatabaseProvider.overrideWithValue(testDatabase()),
            initialOnboardingCompletedProvider.overrideWithValue(false),
          ];
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tab-settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete my data'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my data'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteDataPage), findsOneWidget);

    await tester.tap(find.text('Delete my data'));
    await tester.pumpAndSettle();

    expect(wiper.wiped, isTrue);
    expect(opened, 1);
    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
