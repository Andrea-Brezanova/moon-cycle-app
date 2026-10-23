import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/diary_coming_soon_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
import 'package:moon_cycle/features/diary/presentation/log_symptoms_page.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<ProviderContainer> pumpHub(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1100) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    unawaited(container.read(appRouterProvider).push(Routes.diary));
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(Routes.diary);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryHubPage), findsOneWidget);
    return container;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
  }

  testWidgets('the hub: title, subtitle, Today and the five cards in order', (
    tester,
  ) async {
    await pumpHub(tester);
    expect(find.text('My Diary'), findsOneWidget);
    expect(
      find.text(
        'A gentle place to track your meals, symptoms and daily patterns.',
      ),
      findsOneWidget,
    );
    expect(find.text('Today'), findsOneWidget);
    expect(
      find.text('Check in with how you feel and what you did today.'),
      findsOneWidget,
    );
    final order = [
      'Log symptoms',
      'Log a meal',
      'Log activities',
      'Notes',
      'View my entries',
    ];
    double? last;
    for (final t in order) {
      final y = tester.getTopLeft(find.text(t)).dy;
      if (last != null) expect(y, greaterThan(last), reason: t);
      last = y;
    }
    expect(find.text('Log cycle details'), findsNothing);
  });

  testWidgets('Log symptoms and Log a meal open the existing forms', (
    tester,
  ) async {
    await pumpHub(tester);
    await tester.tap(find.text('Log symptoms'));
    await tester.pumpAndSettle();
    expect(find.byType(LogSymptomsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DiaryHubPage), findsOneWidget);

    await tester.tap(find.text('Log a meal'));
    await tester.pumpAndSettle();
    expect(find.byType(LogMealPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DiaryHubPage), findsOneWidget);
  });

  testWidgets('Today and View my entries open the existing history; Back '
      'returns to the hub', (tester) async {
    await pumpHub(tester);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPage), findsOneWidget);
    expect(find.text('Meals'), findsWidgets);
    await back(tester);
    expect(find.byType(DiaryHubPage), findsOneWidget);

    await tester.ensureVisible(find.text('View my entries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View my entries'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPage), findsOneWidget);
    await back(tester);
    expect(find.byType(DiaryHubPage), findsOneWidget);
  });

  testWidgets('Log activities and Notes are honest Coming soon pages', (
    tester,
  ) async {
    await pumpHub(tester);
    for (final (card, headline) in const [
      ('Log activities', 'Activity logging is on its way.'),
      ('Notes', 'Notes are on their way.'),
    ]) {
      await tester.tap(find.text(card));
      await tester.pumpAndSettle();
      expect(find.byType(DiaryComingSoonPage), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text(headline), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // no fake editor or form
      await back(tester);
      expect(find.byType(DiaryHubPage), findsOneWidget);
    }
  });

  testWidgets('the direct links to history and the forms still work', (
    tester,
  ) async {
    final container = await pumpHub(tester);
    final router = container.read(appRouterProvider);
    router.go(Routes.diaryEntries);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPage), findsOneWidget);
    router.go(Routes.diaryOn(symptoms: true));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPage), findsOneWidget);
    unawaited(router.push(Routes.logMeal()));
    await tester.pumpAndSettle();
    expect(find.byType(LogMealPage), findsOneWidget);
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: fits, 44 pt '
          'targets',
          (tester) async {
            final handle = tester.ensureSemantics();
            await pumpScreen(
              tester,
              const DiaryHubPage(),
              dark: dark,
              width: width,
              textScale: scale,
              height: 3000,
              overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            handle.dispose();
          },
        );
      }
    }
  });
}
