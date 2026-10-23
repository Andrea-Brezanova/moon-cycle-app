@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/diary_activities_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_activity_editor_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

void main() {
  setUpAll(loadMoonFonts);

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    testWidgets('diary activities empty, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryActivitiesPage(),
        dark: dark,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiaryActivitiesPage),
        matchesGoldenFile('goldens/$theme-diary-activities-empty.png'),
      );
    });

    testWidgets('diary activity editor, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryActivityEditorPage(),
        dark: dark,
        height: 1100,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiaryActivityEditorPage),
        matchesGoldenFile('goldens/$theme-diary-activity-editor.png'),
      );
    });
  }
}
