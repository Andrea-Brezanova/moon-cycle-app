import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rows on Me › My App, with "Delete my data" at its bottom.
const _myAppRows = {
  'My Cycle',
  'Food Preferences',
  'Allergies / dietary exclusions',
  'Appearance',
  'Notifications',
  'Subscription',
  'Privacy & Data',
  'Help',
  'Credits & Sources',
  'About',
  'Delete my data',
};

/// Whether [row] is a row on My App (reached from Me through it).
bool isNestedSettingsRow(String row) => _myAppRows.contains(row);

/// From the Me page, opens a settings row through My App (or "Delete my data"
/// at the bottom of My App).
Future<void> openMeRow(WidgetTester tester, String row) async {
  Future<void> tapVisible(Finder f) async {
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

  await tapVisible(find.byKey(const ValueKey('me-app')));
  await tapVisible(
    row == 'Delete my data'
        ? find.byKey(const ValueKey('app-delete-data'))
        : find.text(row),
  );
}
