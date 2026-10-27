import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/credits/presentation/credits_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';
import 'package:moon_cycle/features/settings/presentation/about_page.dart';
import 'package:moon_cycle/features/settings/presentation/allergies_page.dart';
import 'package:moon_cycle/features/settings/presentation/appearance_page.dart';
import 'package:moon_cycle/features/settings/presentation/delete_data_page.dart';
import 'package:moon_cycle/features/settings/presentation/food_preferences_page.dart';
import 'package:moon_cycle/features/settings/presentation/help_page.dart';
import 'package:moon_cycle/features/settings/presentation/my_app_page.dart';
import 'package:moon_cycle/features/settings/presentation/my_cycle_page.dart';
import 'package:moon_cycle/features/settings/presentation/notifications_page.dart';
import 'package:moon_cycle/features/settings/presentation/privacy_data_page.dart';
import 'package:moon_cycle/features/settings/presentation/subscription_page.dart';
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

  const destinations = ['me-collections', 'me-diary', 'me-shopping', 'me-app'];

  testWidgets('Me has exactly four destinations, in order, and nothing else '
      'to tap', (tester) async {
    await pumpMe(tester);
    final tops = [
      for (final k in destinations)
        tester.getTopLeft(find.byKey(ValueKey(k))).dy,
    ];
    for (var i = 0; i < tops.length - 1; i++) {
      expect(tops[i], lessThan(tops[i + 1]), reason: destinations[i]);
    }
    for (final t in [
      'My Collections',
      'My Diary',
      'My Shopping List',
      'My App',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // The old groupings, settings rows and the delete row are not on Me.
    for (final t in [
      'YOUR SPACE',
      'YOUR APP',
      'YOUR ACCOUNT',
      'SUPPORT',
      'My Cycle',
      'Appearance',
      'Delete my data',
      'Personalization',
    ]) {
      expect(find.text(t), findsNothing, reason: t);
    }
  });

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('each destination opens its page and goes back to Me', (
    tester,
  ) async {
    await pumpMe(tester);
    final pages = <String, Finder>{
      'me-collections': find.byType(CollectionsPage),
      'me-diary': find.byType(DiaryHubPage),
      'me-shopping': find.byType(ShopPage),
      'me-app': find.byType(MyAppPage),
    };
    for (final MapEntry(key: key, value: page) in pages.entries) {
      await openRow(tester, key);
      expect(page, findsOneWidget, reason: key);
      await back(tester);
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: 'back $key');
    }
  });

  testWidgets('My App holds every setting, in four groups, with Delete my '
      'data last', (tester) async {
    await pumpMe(tester);
    await openRow(tester, 'me-app');
    final order = [
      'PERSONALIZATION',
      'My Cycle',
      'Food Preferences',
      'Allergies / dietary exclusions',
      'APP PREFERENCES',
      'Appearance',
      'Notifications',
      'ACCOUNT',
      'Subscription',
      'Privacy & Data',
      'SUPPORT',
      'Help',
      'Credits & Sources',
      'About',
      'Delete my data',
    ];
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final tops = <double>[];
    for (final t in order) {
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(t),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      tops.add(tester.getTopLeft(find.text(t)).dy + scrollable.position.pixels);
    }
    for (var i = 0; i < tops.length - 1; i++) {
      expect(tops[i], lessThan(tops[i + 1]), reason: order[i]);
    }
  });

  testWidgets('every My App row opens its page', (tester) async {
    await pumpMe(tester);
    await openRow(tester, 'me-app');
    final pages = <String, Finder>{
      'app-my-cycle': find.byType(MyCyclePage),
      'app-food-preferences': find.byType(FoodPreferencesSettingsPage),
      'app-allergies': find.byType(AllergiesPage),
      'app-appearance': find.byType(AppearancePage),
      'app-notifications': find.byType(NotificationsPage),
      'app-subscription': find.byType(SubscriptionPage),
      'app-privacy': find.byType(PrivacyDataPage),
      'app-help': find.byType(HelpPage),
      'app-credits': find.byType(CreditsPage),
      'app-about': find.byType(AboutPage),
    };
    for (final MapEntry(key: key, value: page) in pages.entries) {
      await openRow(tester, key);
      expect(page, findsOneWidget, reason: key);
      await back(tester);
      expect(find.byType(MyAppPage), findsOneWidget, reason: 'back $key');
    }
  });

  testWidgets('Delete my data only opens the confirmation page and deletes '
      'nothing by itself', (tester) async {
    await pumpMe(tester);
    await openRow(tester, 'me-app');
    await openRow(tester, 'app-delete-data');
    expect(find.byType(DeleteDataPage), findsOneWidget);
    // Backing out leaves the data and the settings page in place.
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
    expect(find.byType(MyAppPage), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('Me fits at ${width}pt with $scale× text', (tester) async {
      await pumpMe(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('me-app')));
      expect(tester.takeException(), isNull);
    });
  }
}
