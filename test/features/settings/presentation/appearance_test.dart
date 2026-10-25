import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/preferences/application/preference_providers.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/preferences/domain/appearance.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/settings/presentation/appearance_page.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/me_nav.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Brightness brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  Future<(ProviderContainer, AppDatabase)> pumpAppearance(
    WidgetTester tester, {
    AppDatabase? database,
    Brightness device = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.platformBrightnessTestValue = device;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final db = database ?? testDatabase();
    if (database == null) {
      await seedCycle(tester, db, start: sampleStart);
    }
    // As `main()` does: the saved choice is read before the first frame.
    final saved = await tester.runAsync(
      () => PreferencesRepository(db).appearance(),
    );
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        initialAppearanceProvider.overrideWithValue(saved!),
      ],
    );
    return (container, db);
  }

  Future<void> openAppearance(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await openMeRow(tester, 'Appearance');
    expect(find.byType(AppearancePage), findsOneWidget);
  }

  testWidgets('the default is System', (tester) async {
    final (container, _) = await pumpAppearance(tester);
    expect(container.read(appearanceProvider), AppearanceMode.system);
    expect(AppearanceMode.fromName(null), AppearanceMode.system);
    expect(AppearanceMode.fromName('nonsense'), AppearanceMode.system);
  });

  testWidgets('System follows the device, also while running', (tester) async {
    await pumpAppearance(tester, device: Brightness.dark);
    expect(brightness(tester), Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('Light overrides a dark device, Dark a light device', (
    tester,
  ) async {
    final (container, _) = await pumpAppearance(
      tester,
      device: Brightness.dark,
    );
    final appearance = container.read(appearanceProvider.notifier);
    await appearance.set(AppearanceMode.light);
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await appearance.set(AppearanceMode.dark);
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
    // The device changing does nothing while a fixed mode is chosen.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await appearance.set(AppearanceMode.light);
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);
  });

  testWidgets('Settings: the row, the options and an immediate switch', (
    tester,
  ) async {
    final (container, _) = await pumpAppearance(tester);
    await openAppearance(tester);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
    expect(container.read(appearanceProvider), AppearanceMode.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);
  });

  testWidgets('the selected option is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAppearance(tester);
    await openAppearance(tester);
    bool? selected(String label) => tester
        .getSemantics(find.bySemanticsLabel(RegExp('^$label,')))
        .getSemanticsData()
        .flagsCollection
        .isSelected
        .toBoolOrNull();
    expect(selected('System'), isTrue);
    expect(selected('Light'), isFalse);
    expect(selected('Dark'), isFalse);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(selected('Dark'), isTrue);
    expect(selected('System'), isFalse);
    handle.dispose();
  });

  testWidgets('the choice survives a restart', (tester) async {
    final (container, db) = await pumpAppearance(tester);
    await container.read(appearanceProvider.notifier).set(AppearanceMode.dark);
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);

    // A new app on the same database, on a light device.
    await tester.pumpWidget(const SizedBox());
    final (again, _) = await pumpAppearance(tester, database: db);
    expect(again.read(appearanceProvider), AppearanceMode.dark);
    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('changing it touches no cycle, diet or content state', (
    tester,
  ) async {
    final (container, db) = await pumpAppearance(tester);
    final repo = PreferencesRepository(db);
    await tester.runAsync(() => repo.saveDiet(Diet.vegetarian));
    await tester.pumpAndSettle();
    final before = container.read(cycleStateProvider).value!;
    await container.read(appearanceProvider.notifier).set(AppearanceMode.dark);
    await tester.pumpAndSettle();
    final after = container.read(cycleStateProvider).value!;
    expect(after.lastPeriodStart, before.lastPeriodStart);
    expect(after.cycleDay, before.cycleDay);
    expect(after.phase, before.phase);
    expect(
      await tester.runAsync(() => repo.watchDiet().first),
      Diet.vegetarian,
    );
  });

  testWidgets('large text on a small phone does not overflow', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const AppearancePage(),
      dark: false,
      width: 320,
      textScale: 1.5,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('System'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
