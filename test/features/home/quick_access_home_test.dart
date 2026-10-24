import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/application/diary_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_v2.dart';
import 'package:moon_cycle/features/shopping/application/shopping_summary.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<void> scrollToQuick(WidgetTester tester) => tester.scrollUntilVisible(
    find.text('QUICK ACCESS'),
    300,
    scrollable: find.byType(Scrollable).first,
  );

  testWidgets('empty day and empty list: the quiet wording, icons not photos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await scrollToQuick(tester);
    await tester.pumpAndSettle();
    expect(find.text('Start your daily check-in'), findsOneWidget);
    expect(find.text('Your list is empty'), findsOneWidget);
    for (final name in ['quick_my_diary', 'quick_shopping_list']) {
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName.contains(name),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('logging an entry updates the card without leaving Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await scrollToQuick(tester);
    expect(find.text('Start your daily check-in'), findsOneWidget);
    // A meal is logged today (as the form would), and then a second one.
    final repo = container.read(diaryRepositoryProvider);
    final today = container.read(todayProvider);
    DiaryDraft draft(String id) => DiaryDraft(
      date: today,
      meal: DiaryMeal.lunch,
      kind: DiaryItemKind.food,
      itemId: id,
      title: id,
      amount: 1,
      unit: DiaryUnit.serving,
    );
    await tester.runAsync(() => repo.add(draft('apple')));
    await tester.pumpAndSettle();
    expect(find.text('1 entry today'), findsOneWidget);
    await tester.runAsync(() => repo.add(draft('kale')));
    await tester.pumpAndSettle();
    expect(find.text('2 entries today'), findsOneWidget);
  });

  testWidgets('the cards show the live counts and open the right pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        todayDiaryEntryCountProvider.overrideWithValue(3),
        shoppingSummaryProvider.overrideWithValue(
          const ShoppingSummary(
            toBuy: 8,
            done: 0,
            fromRecipes: 0,
            onListFoodIds: {},
          ),
        ),
      ],
    );
    await scrollToQuick(tester);
    await tester.pumpAndSettle();
    expect(find.text('3 entries today'), findsOneWidget);
    expect(find.text('8 items to buy'), findsOneWidget);
    expect(find.bySemanticsLabel('My Diary. 3 entries today'), findsOneWidget);
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [(390.0, 1.0), (320.0, 1.0), (320.0, 1.5)]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: fits, 44 pt '
          'targets',
          (tester) async {
            final handle = tester.ensureSemantics();
            await pumpScreen(
              tester,
              const HomePage(),
              dark: dark,
              width: width,
              textScale: scale,
              height: 4200,
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
