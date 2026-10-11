import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/app.dart';
import 'package:moon_cycle/app/config/app_config.dart';

void main() {
  testWidgets('the app starts with the given flavour', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(flavor: Flavor.dev),
          ),
        ],
        child: const MoonCycleApp(),
      ),
    );

    expect(find.text('Moon Cycle'), findsOneWidget);
    expect(find.text('Flavour: dev'), findsOneWidget);
  });
}
