import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('the app starts on Home; Settings shows the flavour', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Flavour: dev'), findsOneWidget);
  });
}
