import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rows that live under Me › Personalization; the rest are on Me itself.
const _personalizationRows = {
  'My Cycle',
  'Food Preferences',
  'Allergies / Foods to Avoid',
};

/// Whether [row] is one of the pages that sits under Personalization.
bool isNestedSettingsRow(String row) => _personalizationRows.contains(row);

/// From the Me page, opens a settings row: directly for the rows on Me, through
/// Personalization for My Cycle, Food Preferences and allergies, and through
/// Privacy & Data for "Delete my data".
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

  if (row == 'Delete my data') {
    await tapVisible(find.byKey(const ValueKey('me-privacy')));
    return tapVisible(find.byKey(const ValueKey('privacy-delete-data')));
  }
  if (_personalizationRows.contains(row)) {
    await tapVisible(find.byKey(const ValueKey('me-personalization')));
  }
  await tapVisible(find.text(row));
}
