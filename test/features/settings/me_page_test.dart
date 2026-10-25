import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';
import 'package:moon_cycle/features/settings/presentation/account_plus_page.dart';
import 'package:moon_cycle/features/settings/presentation/delete_data_page.dart';
import 'package:moon_cycle/features/settings/presentation/settings_hub_page.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<void> pumpMe(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1400) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
  }

  testWidgets('Me shows My Collections on top, then the four rows in order, '
      'with Delete my data kept below', (tester) async {
    await pumpMe(tester);
    double top(Finder f) => tester.getTopLeft(f).dy;
    final order = [
      find.byKey(const ValueKey('my-collections-card')),
      find.byKey(const ValueKey('me-diary')),
      find.byKey(const ValueKey('me-shopping')),
      find.byKey(const ValueKey('me-settings')),
      find.byKey(const ValueKey('me-account')),
    ];
    for (final f in order) {
      expect(f, findsOneWidget);
    }
    for (var i = 0; i < order.length - 1; i++) {
      expect(top(order[i]), lessThan(top(order[i + 1])));
    }
    expect(find.text('What you ate, did and felt'), findsOneWidget);
    expect(find.text('Nothing to buy'), findsOneWidget);
    expect(find.text('Cycle, food preferences, notifications'), findsOneWidget);
    expect(find.text('Subscription, privacy and data'), findsOneWidget);
    expect(find.text('Delete my data'), findsOneWidget);
    // The old groups moved into the two hubs.
    for (final t in ['PERSONALISATION', 'APP', 'SUPPORT', 'ACCOUNT']) {
      expect(find.text(t), findsNothing, reason: t);
    }
  });

  testWidgets('each row opens its page; Settings and Account & Plus hold the '
      'rows that used to sit on Me', (tester) async {
    await pumpMe(tester);
    await tester.tap(find.byKey(const ValueKey('my-collections-card')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('me-diary')));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryHubPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('me-shopping')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('me-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsHubPage), findsOneWidget);
    for (final t in [
      'My Cycle',
      'Food Preferences',
      'Allergies / Foods to Avoid',
      'Notifications',
      'Appearance',
      'Help',
      'Credits & Sources',
    ]) {
      await tester.ensureVisible(find.text(t));
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.bySemanticsLabel('Back to Me'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('me-account')));
    await tester.pumpAndSettle();
    expect(find.byType(AccountPlusPage), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Privacy & Data'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back to Me'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete my data'));
    await tester.tap(find.text('Delete my data'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteDataPage), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('Me fits at ${width}pt with $scale× text', (tester) async {
      await pumpMe(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('me-account')));
      expect(tester.takeException(), isNull);
    });
  }
}
