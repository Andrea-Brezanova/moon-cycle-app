@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/hubs/presentation/hub_home_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';

void main() {
  setUpAll(loadMoonFonts);

  final screens = <String, Widget>{
    'move': const HubHomePage.move(),
    'relax': const HubHomePage.relax(),
  };

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$name hub, $theme', (tester) async {
        await pumpScreen(tester, screen, dark: dark, height: 700);
        await expectLater(
          find.byWidget(screen),
          matchesGoldenFile('goldens/$theme-hub-$name.png'),
        );
      });
    }
  }
}
