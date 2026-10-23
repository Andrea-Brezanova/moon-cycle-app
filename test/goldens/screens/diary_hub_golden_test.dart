@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

void main() {
  setUpAll(loadMoonFonts);

  for (final (name, dark, width, scale) in [
    ('light', false, 390.0, 1.0),
    ('dark', true, 390.0, 1.0),
    ('narrow-large-text', false, 320.0, 1.5),
  ]) {
    testWidgets('diary hub, $name', (tester) async {
      await pumpScreen(
        tester,
        const DiaryHubPage(),
        dark: dark,
        width: width,
        textScale: scale,
        height: scale > 1 ? 2200 : 900,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiaryHubPage),
        matchesGoldenFile('goldens/diary-hub-$name.png'),
      );
    });
  }
}
