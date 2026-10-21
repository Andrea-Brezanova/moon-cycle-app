@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/app/shell/moon_tab_bar.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';

import '../helpers/moon_fonts.dart';

/// The tab bar at the design width, with the iPhone home-indicator inset.
/// Regenerate after an intentional change with:
///   flutter test --tags golden --update-goldens
void main() {
  setUpAll(loadMoonFonts);

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    for (final current in [AppTab.home, AppTab.eat]) {
      testWidgets('tab bar, ${current.name} active, $theme', (tester) async {
        tester.view.physicalSize = const Size(390, 88) * 2;
        tester.view.devicePixelRatio = 2;
        tester.view.padding = const FakeViewPadding(bottom: 34 * 2);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: moonTheme(dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
              bottomNavigationBar: MoonTabBar(
                current: current,
                onSelect: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MoonTabBar),
          matchesGoldenFile('goldens/${theme}_tab_bar_${current.name}.png'),
        );
      });
    }
  }
}
