import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The My recipes dropdown's current option label.
String currentShow(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('my-recipes-filter')),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// The matching count shown above the results ("3 items").
String shownCount(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('my-recipes-count'))).data!;

/// Opens the dropdown, then chooses [label] ("All recipes", "Saved / Favorites",
/// "Added by me" or "Links").
Future<void> chooseShow(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('my-recipes-filter')));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(RegExp('^$label, \\d+\$')));
  await tester.pumpAndSettle();
}

/// Opens the dropdown, checks each option shows its live count, and closes it.
Future<void> expectShowCounts(
  WidgetTester tester,
  Map<String, int> counts,
) async {
  await tester.tap(find.byKey(const ValueKey('my-recipes-filter')));
  await tester.pumpAndSettle();
  for (final MapEntry(key: label, value: n) in counts.entries) {
    expect(find.bySemanticsLabel('$label, $n'), findsOneWidget, reason: label);
  }
  await tester.tapAt(const Offset(10, 60)); // the scrim
  await tester.pumpAndSettle();
}
