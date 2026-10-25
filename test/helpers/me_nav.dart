import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rows that live under Me › Account & Plus.
const _accountRows = {'Subscription', 'Privacy & Data'};

/// Rows that live under Me › Settings.
const _settingsRows = {
  'My Cycle',
  'Food Preferences',
  'Allergies / Foods to Avoid',
  'Notifications',
  'Appearance',
  'Help',
  'Credits & Sources',
};

/// Whether [row] is one of the settings rows that moved off the Me page.
bool isNestedSettingsRow(String row) =>
    _accountRows.contains(row) || _settingsRows.contains(row);

/// From the Me page, opens a settings row through its hub (Settings or Account
/// & Plus), or "Delete my data" directly at the bottom of Me.
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

  if (row == 'Delete my data') return tapVisible(find.text(row));
  await tapVisible(
    find.byKey(
      ValueKey(_accountRows.contains(row) ? 'me-account' : 'me-settings'),
    ),
  );
  await tapVisible(find.text(row));
}
