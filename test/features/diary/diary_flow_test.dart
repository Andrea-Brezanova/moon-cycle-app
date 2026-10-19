import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool premium = true,
  }) async {
    tester.view.physicalSize = const Size(390, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow), // 4 Oct 2025, 09:00
        if (premium)
          entitlementStateProvider.overrideWithValue(
            const EntitlementState(tier: Tier.premium),
          ),
      ],
    );
    c.read(appRouterProvider).go(Routes.diary);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> addFood(WidgetTester tester, String query, String title) async {
    await tester.tap(find.text('Add a food or recipe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, query);
    await tester.pumpAndSettle();
    await tester.tap(find.text(title).last);
    await tester.pumpAndSettle();
  }

  testWidgets('free users see the diary is Premium', (tester) async {
    await pump(tester, premium: false);
    expect(find.text('Log Diary is part of Moon Cycle Premium.'), findsOne);
    expect(find.text('Add a food or recipe'), findsNothing);
  });

  testWidgets('log a food: meal defaults to the time of day, then changes', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(DiaryPage), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.byKey(const ValueKey('diary-empty')), findsOneWidget);

    await addFood(tester, 'salm', 'Salmon');
    expect(find.text('Add to your diary'), findsOneWidget);
    // 09:00 is breakfast; pick dinner and 1½ servings.
    await tester.tap(find.text('Dinner'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('More').last);
    await tester.pump();
    expect(find.text('1½ servings'), findsOneWidget);
    await tester.tap(find.text('Add to diary'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('diary-empty')), findsNothing);
    expect(find.text('DINNER'), findsOneWidget);
    expect(find.text('Salmon'), findsOneWidget);
    expect(find.text('1½ servings'), findsOneWidget);
  });

  testWidgets('logging the same food in the same meal merges, not duplicates', (
    tester,
  ) async {
    await pump(tester);
    for (var i = 0; i < 2; i++) {
      await addFood(tester, 'salm', 'Salmon');
      await tester.tap(find.text('Dinner'));
      await tester.pump();
      await tester.tap(find.text('Add to diary'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Salmon'), findsOneWidget);
    expect(find.text('2 servings'), findsOneWidget);
  });

  testWidgets('edit the amount and move it, then delete', (tester) async {
    final c = await pump(tester);
    await addFood(tester, 'salm', 'Salmon');
    await tester.tap(find.text('Add to diary'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 serving'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);
    await tester.tap(find.text('g')); // count it in grams
    await tester.pump();
    expect(find.text('100 g'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('More').last);
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('125 g'), findsOneWidget);

    await tester.tap(find.text('125 g'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete this entry'));
    await tester.pumpAndSettle();
    expect(find.text('Salmon'), findsNothing);
    expect(find.byKey(const ValueKey('diary-empty')), findsOneWidget);
    expect(await c.read(diaryRepositoryProvider).all(), isEmpty);
  });

  testWidgets('daily history: other days, and back to today', (tester) async {
    final c = await pump(tester);
    final repo = c.read(diaryRepositoryProvider);
    await tester.runAsync(() async {
      await repo.add(
        DiaryDraft(
          date: c.read(todayProvider).addDays(-1),
          meal: DiaryMeal.lunch,
          kind: DiaryItemKind.food,
          itemId: 'lentils',
          title: 'Lentils',
          amount: 2,
          unit: DiaryUnit.serving,
        ),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('EARLIER DAYS'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(find.text('Lentils'), findsOneWidget);
    expect(find.text('2 servings'), findsOneWidget);
    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();
    expect(find.text('Lentils'), findsNothing);
    // The next-day button is off on today: the diary is never in the future.
    await tester.tap(find.bySemanticsLabel('Next day'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diary-day')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('diary-day'))).data,
      'Today',
    );
  });

  testWidgets('Food Detail and Recipe detail add to the diary', (tester) async {
    final c = await pump(tester);
    c.read(appRouterProvider).go(Routes.food('broccoli'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add to logged meals'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add to logged meals'));
    await tester.pumpAndSettle();
    expect(find.text('Broccoli'), findsWidgets);
    await tester.tap(find.text('Add to diary'));
    await tester.pumpAndSettle();
    final entries = await c.read(diaryRepositoryProvider).all();
    expect(entries.single.itemId, 'broccoli');
    expect(entries.single.kind, DiaryItemKind.food);

    c.read(appRouterProvider).go(Routes.recipe('lentil-spinach-tomato-stew'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add to my diary'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add to my diary'));
    await tester.pumpAndSettle();
    // A recipe is counted in servings only.
    expect(find.text('Servings'), findsNothing);
    await tester.tap(find.text('Add to diary'));
    await tester.pumpAndSettle();
    final all = await c.read(diaryRepositoryProvider).all();
    expect(all.map((e) => e.kind).toSet(), {
      DiaryItemKind.food,
      DiaryItemKind.recipe,
    });
  });

  testWidgets('a free user does not see the diary button on a recipe', (
    tester,
  ) async {
    final c = await pump(tester, premium: false);
    c.read(appRouterProvider).go(Routes.recipe('lentil-spinach-tomato-stew'));
    await tester.pumpAndSettle();
    expect(find.text('Add to my diary'), findsNothing);
  });
}
