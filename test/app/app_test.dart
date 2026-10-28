import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('the app starts on Home; My App shows the version and flavour', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    // Not on Me itself any more: the footer is at the bottom of My App.
    expect(find.text('Version 1.0.0 · dev'), findsNothing);
    // The hero image pushes the fourth card below the first screen.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('me-app')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-app')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Version 1.0.0 · dev'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Version 1.0.0 · dev'), findsOneWidget);
  });
}
