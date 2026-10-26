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
import 'package:moon_cycle/features/settings/presentation/my_cycle_page.dart';
import 'package:moon_cycle/features/settings/presentation/notifications_page.dart';
import 'package:moon_cycle/features/settings/presentation/personalization_page.dart';
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

  const sections = {
    'YOUR SPACE': ['me-collections', 'me-diary', 'me-shopping'],
    'YOUR APP': ['me-personalization', 'me-appearance', 'me-notifications'],
    'YOUR ACCOUNT': ['me-subscription', 'me-privacy'],
    'SUPPORT': ['me-help', 'me-credits', 'me-about'],
  };

  testWidgets('Me has exactly four sections with their rows in order', (
    tester,
  ) async {
    await pumpMe(tester);
    double top(Finder f) => tester.getTopLeft(f).dy;
    final ordered = <Finder>[];
    for (final MapEntry(key: title, value: keys) in sections.entries) {
      ordered.add(find.text(title));
      for (final k in keys) {
        ordered.add(find.byKey(ValueKey(k)));
      }
    }
    for (final f in ordered) {
      await tester.ensureVisible(f);
      expect(f, findsOneWidget);
    }
    await tester.pumpAndSettle();
    // Top to bottom in the order of the list: sample a scroll offset-free
    // check through the list's own children.
    final tops = <double>[];
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
    for (final f in ordered) {
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      tops.add(top(f) + scrollable.position.pixels);
    }
    for (var i = 0; i < tops.length - 1; i++) {
      expect(tops[i], lessThan(tops[i + 1]), reason: 'row $i');
    }
    // My Cycle and the old hubs are not on Me.
    for (final t in [
      'My Cycle',
      'Settings',
      'Account & Plus',
      'Delete my data',
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

  testWidgets('every row opens its page and goes back to Me', (tester) async {
    await pumpMe(tester);
    final pages = <String, Finder>{
      'me-collections': find.byType(CollectionsPage),
      'me-diary': find.byType(DiaryHubPage),
      'me-shopping': find.byType(ShopPage),
      'me-personalization': find.byType(PersonalizationPage),
      'me-appearance': find.byType(AppearancePage),
      'me-notifications': find.byType(NotificationsPage),
      'me-subscription': find.byType(SubscriptionPage),
      'me-privacy': find.byType(PrivacyDataPage),
      'me-help': find.byType(HelpPage),
      'me-credits': find.byType(CreditsPage),
      'me-about': find.byType(AboutPage),
    };
    for (final MapEntry(key: key, value: page) in pages.entries) {
      await openRow(tester, key);
      expect(page, findsOneWidget, reason: key);
      await back(tester);
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: 'back $key');
    }
  });

  testWidgets('Personalization holds My Cycle, Food Preferences and '
      'allergies, each reachable', (tester) async {
    await pumpMe(tester);
    await openRow(tester, 'me-personalization');
    expect(find.text('Movement'), findsNothing);
    expect(find.text('Relaxation'), findsNothing);
    final pages = {
      'My Cycle': find.byType(MyCyclePage),
      'Food Preferences': find.byType(FoodPreferencesSettingsPage),
      'Allergies / Foods to Avoid': find.byType(AllergiesPage),
    };
    for (final MapEntry(key: label, value: page) in pages.entries) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(page, findsOneWidget, reason: label);
      await tester.tap(find.bySemanticsLabel('Back to Personalization'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalizationPage), findsOneWidget);
    }
  });

  testWidgets('Delete my data sits under Privacy & Data and opens the '
      'confirmation page', (tester) async {
    await pumpMe(tester);
    await openRow(tester, 'me-privacy');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('privacy-delete-data')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('privacy-delete-data')));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteDataPage), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('Me fits at ${width}pt with $scale× text', (tester) async {
      await pumpMe(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('me-about')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
