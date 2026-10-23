import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_note_repository.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_note_editor_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_notes_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  /// The app on the Notes list (More › My Diary › Notes).
  Future<void> pumpNotes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1100) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(Routes.diary);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNotesPage), findsOneWidget);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
  }

  Future<void> write(WidgetTester tester, {String? title, String? body}) async {
    if (title != null) {
      await tester.enterText(find.byKey(const ValueKey('note-title')), title);
    }
    if (body != null) {
      await tester.enterText(find.byKey(const ValueKey('note-body')), body);
    }
    await tester.pumpAndSettle();
  }

  Future<List<String>> bodies(WidgetTester tester) async =>
      (await tester.runAsync(DiaryNoteRepository(db).all))!
          .map((n) => n.body)
          .toList();

  testWidgets('the Notes card opens the list; empty at first', (tester) async {
    await pumpNotes(tester);
    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.text('Write a note'), findsOneWidget);
    expect(find.byType(TextField), findsNothing); // no fake editor yet
    await back(tester);
    expect(find.byType(DiaryHubPage), findsOneWidget);
  });

  testWidgets('write, save and reopen a note; several on one day', (
    tester,
  ) async {
    await pumpNotes(tester);
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNoteEditorPage), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);
    await write(tester, title: 'River walk', body: 'Cold air.\nLong sky.');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNotesPage), findsOneWidget);
    expect(find.text('River walk'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget); // the day heading
    expect(await bodies(tester), ['Cold air.\nLong sky.']);
    await tester.pump(const Duration(seconds: 10)); // the toast goes away

    // A second note on the same day.
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    await write(tester, body: 'Tea at four.');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Tea at four.'), findsOneWidget); // no title: its start
    expect(find.text('River walk'), findsOneWidget);
    expect((await bodies(tester)), hasLength(2));

    // Reopen the first: the title and the writing are there to edit.
    await tester.tap(find.text('River walk'));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Cold air.\nLong sky.'), findsOneWidget);
    await write(tester, body: 'Cold air.\nLong sky.\nHome by six.');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(
      await bodies(tester),
      contains('Cold air.\nLong sky.\nHome by six.'),
    );
    await tester.pump(const Duration(seconds: 10)); // the toast goes away
  });

  testWidgets('a blank note cannot be saved', (tester) async {
    await pumpNotes(tester);
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    await write(tester, body: '   ');
    await tester.tap(find.text('Save note'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNoteEditorPage), findsOneWidget);
    expect(await bodies(tester), isEmpty);
  });

  testWidgets('going back with unsaved writing asks first', (tester) async {
    await pumpNotes(tester);
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    await write(tester, body: 'Half a thought');
    await back(tester);
    expect(find.text('Discard your writing?'), findsOneWidget);
    expect(find.byType(DiaryNoteEditorPage), findsOneWidget);
    await tester.tap(find.text('Keep writing'));
    await tester.pumpAndSettle();
    expect(find.text('Half a thought'), findsOneWidget); // nothing lost
    await back(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNotesPage), findsOneWidget);
    expect(await bodies(tester), isEmpty);
  });

  testWidgets('delete asks first, then removes the note and its writing', (
    tester,
  ) async {
    await pumpNotes(tester);
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    await write(tester, title: 'Gone soon', body: 'private words');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gone soon'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete note'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this note?'), findsOneWidget);
    await tester.tap(find.text('Keep note'));
    await tester.pumpAndSettle();
    expect(await bodies(tester), ['private words']); // kept

    await tester.tap(find.text('Delete note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete note').last);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNotesPage), findsOneWidget);
    expect(find.text('No notes yet'), findsOneWidget);
    final raw = await tester.runAsync(() => db.select(db.diaryNotes).get());
    expect(raw!.single.body, isEmpty);
    expect(raw.single.title, isNull);
    await tester.pump(const Duration(seconds: 10)); // the toast goes away
  });

  testWidgets('the history has a Notes tab for the day', (tester) async {
    await pumpNotes(tester);
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    await write(tester, title: 'Today’s page', body: 'x');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10)); // the toast goes away
    container.read(appRouterProvider).go(Routes.diaryEntries);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPage), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Today’s page'), findsOneWidget);
    await tester.tap(find.text('Today’s page'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryNoteEditorPage), findsOneWidget);
    // Back returns to the history, still on the Notes tab's page.
    await back(tester);
    expect(find.byType(DiaryPage), findsOneWidget);
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: list and editor '
          'fit, 44 pt targets',
          (tester) async {
            final handle = tester.ensureSemantics();
            for (final page in const [
              DiaryNotesPage(),
              DiaryNoteEditorPage(),
            ]) {
              await pumpScreen(
                tester,
                page,
                dark: dark,
                width: width,
                textScale: scale,
                height: 2200,
                overrides: [
                  cycleStateProvider.overrideWithValue(stateOnDay(7)),
                ],
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
            }
            handle.dispose();
          },
        );
      }
    }
  });
}
