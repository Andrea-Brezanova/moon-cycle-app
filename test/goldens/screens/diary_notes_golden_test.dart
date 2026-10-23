@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/diary_note_editor_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_notes_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

void main() {
  setUpAll(loadMoonFonts);

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    testWidgets('diary notes empty, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryNotesPage(),
        dark: dark,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiaryNotesPage),
        matchesGoldenFile('goldens/$theme-diary-notes-empty.png'),
      );
    });

    testWidgets('diary note editor, $theme', (tester) async {
      await pumpScreen(
        tester,
        const DiaryNoteEditorPage(),
        dark: dark,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiaryNoteEditorPage),
        matchesGoldenFile('goldens/$theme-diary-note-editor.png'),
      );
    });
  }
}
