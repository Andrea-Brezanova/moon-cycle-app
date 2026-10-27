import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/app/config/build_info.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/settings/presentation/about_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<void> openAbout(WidgetTester tester, BuildInfo info) async {
    tester.view.physicalSize = const Size(390, 1400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        buildInfoProvider.overrideWithValue(info),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-app')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('app-about')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('app-about')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
  }

  String shown(WidgetTester tester, String key) =>
      tester.widget<SelectableText>(find.byKey(ValueKey(key))).data!;

  testWidgets('About shows the version, commit, build date and flavor', (
    tester,
  ) async {
    await openAbout(
      tester,
      BuildInfo(
        version: '0.1.0',
        buildNumber: '1',
        commit: 'a3dd5e3',
        builtAt: DateTime.utc(2026, 10, 25, 20, 5),
        flavor: Flavor.dev,
      ),
    );
    expect(shown(tester, 'about-version'), '0.1.0 (1)');
    expect(shown(tester, 'about-commit'), 'a3dd5e3');
    expect(shown(tester, 'about-built'), '25 Oct 2026, 20:05 UTC');
    expect(shown(tester, 'about-flavor'), 'Development');
  });

  testWidgets('a build without the values says unknown', (tester) async {
    await openAbout(
      tester,
      const BuildInfo(
        version: '0.1.0',
        buildNumber: '1',
        commit: 'unknown',
        builtAt: null,
        flavor: Flavor.prod,
      ),
    );
    expect(shown(tester, 'about-commit'), 'unknown');
    expect(shown(tester, 'about-built'), 'Unknown');
    expect(shown(tester, 'about-flavor'), 'Production');
  });
}
