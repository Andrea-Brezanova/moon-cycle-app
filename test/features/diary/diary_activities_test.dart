import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_activity_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_activity.dart';
import 'package:moon_cycle/features/diary/presentation/diary_activities_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_activity_editor_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  late AppDatabase db;

  Future<void> pumpActivities(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1300) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(Routes.diary);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log activities'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryActivitiesPage), findsOneWidget);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
  }

  Future<List<DiaryActivity>> stored(WidgetTester tester) async =>
      (await tester.runAsync(DiaryActivityRepository(db).all))!;

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save activity'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10)); // the toast goes away
  }

  testWidgets('empty first; the hub card opens the list', (tester) async {
    await pumpActivities(tester);
    expect(find.text('No activities yet'), findsOneWidget);
    expect(find.text('Log an activity'), findsOneWidget);
    expect(find.textContaining('goals'), findsOneWidget); // gentle, no targets
    await back(tester);
    expect(find.byType(DiaryHubPage), findsOneWidget);
  });

  testWidgets('log with only a type; then with everything; both listed', (
    tester,
  ) async {
    await pumpActivities(tester);
    await tester.tap(find.text('Log an activity'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryActivityEditorPage), findsOneWidget);
    // Nothing chosen: Save is disabled.
    await tester.ensureVisible(find.text('Save activity'));
    await tester.tap(find.text('Save activity'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryActivityEditorPage), findsOneWidget);
    expect(await stored(tester), isEmpty);

    await tester.tap(find.text('Walk'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(find.byType(DiaryActivitiesPage), findsOneWidget);
    expect((await stored(tester)).single.type, ActivityType.walk);

    await tester.tap(find.text('Log an activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yoga'));
    await tester.enterText(
      find.byKey(const ValueKey('activity-minutes')),
      '45',
    );
    await tester.tap(find.text('Light'));
    await tester.enterText(
      find.byKey(const ValueKey('activity-note')),
      'Slow morning.',
    );
    await tester.pumpAndSettle();
    await save(tester);
    expect(find.text('45 min · Light'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    final yoga = (await stored(tester))
        .firstWhere((a) => a.type == ActivityType.yoga);
    expect(
      (yoga.minutes, yoga.intensity, yoga.note),
      (45, ActivityIntensity.light, 'Slow morning.'),
    );
  });

  testWidgets('Other takes a name; a bad duration blocks saving', (
    tester,
  ) async {
    await pumpActivities(tester);
    await tester.tap(find.text('Log an activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('activity-name')),
      'Gardening',
    );
    await tester.enterText(
      find.byKey(const ValueKey('activity-minutes')),
      '9999',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('minutes-error')), findsOneWidget);
    await tester.ensureVisible(find.text('Save activity'));
    await tester.tap(find.text('Save activity'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(await stored(tester), isEmpty);

    await tester.enterText(find.byKey(const ValueKey('activity-minutes')), '');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('minutes-error')), findsNothing);
    await save(tester);
    expect(find.text('Gardening'), findsOneWidget);
  });

  testWidgets('edit an activity, take back the feeling, then delete it', (
    tester,
  ) async {
    await pumpActivities(tester);
    await tester.tap(find.text('Log an activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run'));
    await tester.tap(find.text('Vigorous'));
    await tester.pumpAndSettle();
    await save(tester);

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(find.text('Activity'), findsOneWidget);
    await tester.tap(find.text('Vigorous')); // tap again: take it back
    await tester.tap(find.text('Hike'));
    await tester.pumpAndSettle();
    await save(tester);
    final a = (await stored(tester)).single;
    expect((a.type, a.intensity), (ActivityType.hike, null));

    await tester.tap(find.text('Hike'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete activity'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this activity?'), findsOneWidget);
    await tester.tap(find.text('Keep activity'));
    await tester.pumpAndSettle();
    expect(await stored(tester), hasLength(1)); // kept
    await tester.tap(find.text('Delete activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete activity').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('No activities yet'), findsOneWidget);
    expect(await stored(tester), isEmpty);
  });

  testWidgets('going back with unsaved changes asks first', (tester) async {
    await pumpActivities(tester);
    await tester.tap(find.text('Log an activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swim'));
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryActivityEditorPage), findsOneWidget);
    await back(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryActivitiesPage), findsOneWidget);
    expect(await stored(tester), isEmpty);
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
              DiaryActivitiesPage(),
              DiaryActivityEditorPage(),
            ]) {
              await pumpScreen(
                tester,
                page,
                dark: dark,
                width: width,
                textScale: scale,
                height: 3200,
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
