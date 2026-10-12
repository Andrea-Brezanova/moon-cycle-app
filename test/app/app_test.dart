import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/routes.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('the app starts on Home with the given flavour', (tester) async {
    await pumpApp(tester);
    expect(find.text(AppTab.home.label), findsWidgets);
    expect(find.text('Flavour: dev'), findsOneWidget);
  });
}
