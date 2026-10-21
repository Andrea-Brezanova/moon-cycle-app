import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';
import '../../helpers/test_catalogue.dart';

/// The design's sample day, as a date.
final designNowDate = LocalDate(2025, 10, 4);

/// Recently logged, Browse all foods, and ranked search on Log a meal.
void main() {
  Future<(ProviderContainer, AppDatabase)> pump(
    WidgetTester tester, {
    AppDatabase? database,
  }) async {
    tester.view.physicalSize = const Size(390, 3000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = database ?? testDatabase();
    if (database == null) await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow), // 4 Oct 2025, 09:00
        entitlementStateProvider.overrideWithValue(
          const EntitlementState(tier: Tier.premium),
        ),
      ],
    );
    c.read(appRouterProvider).go(Routes.diary);
    await tester.pumpAndSettle();
    return (c, db);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).last;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester) async {
    await tapText(tester, '+ Log a meal');
    expect(find.byType(LogMealPage), findsOneWidget);
  }

  Future<void> saveForm(WidgetTester tester) async {
    await tapText(tester, 'Save to diary');
    await tester.pump(const Duration(seconds: 4)); // the toast goes
    await tester.pumpAndSettle();
  }

  Future<List<DiaryEntry>> all(WidgetTester tester, AppDatabase db) async =>
      (await tester.runAsync(DiaryRepository(db).all))!;

  Future<void> logFood(
    WidgetTester tester,
    AppDatabase db,
    String id,
    String title,
    DiaryMeal meal, {
    int daysAgo = 0,
  }) async {
    await tester.runAsync(
      () => DiaryRepository(db).add(
        DiaryDraft(
          date: designNowDate.addDays(-daysAgo),
          meal: meal,
          kind: DiaryItemKind.food,
          itemId: id,
          title: title,
          amount: 1,
          unit: DiaryUnit.serving,
        ),
      ),
    );
  }

  testWidgets('no history, no Recently logged section', (tester) async {
    await pump(tester);
    await openForm(tester);
    expect(find.text('RECENTLY LOGGED'), findsNothing);
    expect(find.text('FROM YOUR PHASE FOODS'), findsOneWidget);
  });

  testWidgets('a food logged before is offered again and can be logged for '
      'lunch on the same day', (tester) async {
    final (_, db) = await pump(tester);
    await logFood(tester, db, 'kale', 'Kale', DiaryMeal.breakfast);
    await tester.pumpAndSettle();
    await openForm(tester);
    expect(find.text('RECENTLY LOGGED'), findsOneWidget);
    await tapText(tester, 'Lunch');
    // Tap the chip in Recently logged (not the diary entry behind).
    final chip = find.descendant(
      of: find.byType(LogMealPage),
      matching: find.text('Kale'),
    );
    await tester.ensureVisible(chip.last);
    await tester.pumpAndSettle();
    await tester.tap(chip.last);
    await tester.pumpAndSettle();
    await saveForm(tester);

    final entries = await all(tester, db);
    expect(entries, hasLength(2));
    expect(
      {for (final e in entries) e.meal},
      {DiaryMeal.breakfast, DiaryMeal.lunch},
    );
    expect(entries.every((e) => e.itemId == 'kale'), isTrue);
    expect(entries.every((e) => e.kind == DiaryItemKind.food), isTrue);
  });

  testWidgets('an item can be logged again on a later date; the original '
      'entry is untouched', (tester) async {
    final (_, db) = await pump(tester);
    await logFood(tester, db, 'kale', 'Kale', DiaryMeal.lunch, daysAgo: 1);
    await tester.pumpAndSettle();
    await openForm(tester); // today
    final chip = find.descendant(
      of: find.byType(LogMealPage),
      matching: find.text('Kale'),
    );
    await tester.ensureVisible(chip.last);
    await tester.pumpAndSettle();
    await tester.tap(chip.last);
    await tester.pumpAndSettle();
    await saveForm(tester);
    final entries = await all(tester, db);
    expect(
      {for (final e in entries) e.date},
      {designNowDate.addDays(-1), designNowDate},
    );
    expect(
      entries.where((e) => e.date == designNowDate.addDays(-1)).single.meal,
      DiaryMeal.lunch,
    );
  });

  testWidgets('a typed meal is reusable, keeps its title, never joins the '
      'catalogue', (tester) async {
    final (_, db) = await pump(tester);
    await tester.runAsync(
      () => DiaryRepository(db).add(
        DiaryDraft(
          date: designNowDate.addDays(-1),
          meal: DiaryMeal.dinner,
          kind: DiaryItemKind.custom,
          itemId: '',
          title: 'Romaine lettuce',
          amount: 1,
          unit: DiaryUnit.serving,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openForm(tester);
    await tapText(tester, 'Lunch');
    final chip = find.descendant(
      of: find.byType(LogMealPage),
      matching: find.text('Romaine lettuce'),
    );
    await tester.ensureVisible(chip.last);
    await tester.pumpAndSettle();
    await tester.tap(chip.last);
    await tester.pumpAndSettle();
    expect(find.text('Your own meal'), findsWidgets);
    await saveForm(tester);

    final entries = await all(tester, db);
    final custom = entries.where((e) => e.kind == DiaryItemKind.custom);
    expect(custom, hasLength(2));
    expect(custom.every((e) => e.title == 'Romaine lettuce'), isTrue);
    expect(
      {for (final e in custom) e.itemId}.length,
      2,
      reason: 'each typed meal keeps its own row id',
    );
  });

  testWidgets('search finds foods from other phases, exact first, canonical '
      'id kept', (tester) async {
    final (_, db) = await pump(tester); // today is follicular; salmon is luteal
    await openForm(tester);
    await tester.enterText(find.byType(EditableText).first, 'salmon');
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsWidgets);
    await tapText(tester, 'Salmon');
    await saveForm(tester);
    final e = (await all(tester, db)).single;
    expect(e.kind, DiaryItemKind.food);
    expect(e.itemId, 'salmon');
  });

  testWidgets('search tolerates a typo and ranks a logged-before item above '
      'other matches', (tester) async {
    final (_, db) = await pump(tester);
    await logFood(tester, db, 'broccoli', 'Broccoli', DiaryMeal.dinner);
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.enterText(find.byType(EditableText).first, 'brocoli');
    await tester.pumpAndSettle();
    expect(find.text('Food · logged before'), findsOneWidget);
  });

  testWidgets('Browse all foods: collapsed, then every category, all phases, '
      'searchable, any food selectable', (tester) async {
    final (_, db) = await pump(tester);
    await openForm(tester);
    expect(find.text('Search all foods'), findsNothing);
    await tapText(tester, 'Browse all foods');
    expect(find.text('Search all foods'), findsOneWidget);
    // Every category of the catalogue is listed (not just this phase's), and
    // collapsed until opened.
    final names = [
      for (final cat in testCatalogue.categories)
        if (testCatalogue.foods.any(
          (f) => testCatalogue.categoryFor(f).id == cat.id,
        ))
          cat.name,
    ];
    expect(names.length, greaterThan(3));
    for (final n in names) {
      expect(find.text(n), findsWidgets, reason: n);
    }
    expect(find.text('Salmon'), findsNothing); // its category is collapsed

    // Search opens the categories with a match; salmon is not a follicular food.
    await tester.enterText(find.byType(EditableText).at(1), 'salmon');
    await tester.pumpAndSettle();
    final chip = find.descendant(
      of: find.byType(LogMealPage),
      matching: find.text('Salmon'),
    );
    expect(chip, findsWidgets);
    await tester.ensureVisible(chip.last);
    await tester.pumpAndSettle();
    await tester.tap(chip.last);
    await tester.pumpAndSettle();
    await saveForm(tester);
    final e = (await all(tester, db)).single;
    expect(e.itemId, 'salmon');
  });

  testWidgets('phase foods stay as suggestions and do not limit anything', (
    tester,
  ) async {
    await pump(tester);
    await openForm(tester);
    expect(find.text('FROM YOUR PHASE FOODS'), findsOneWidget);
    expect(find.text('BROWSE ALL FOODS'), findsNothing); // a row, not a heading
    expect(find.text('Browse all foods'), findsOneWidget);
  });

  testWidgets('recent items and entries survive an app restart', (
    tester,
  ) async {
    final (_, db) = await pump(tester);
    await logFood(tester, db, 'kale', 'Kale', DiaryMeal.breakfast);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());

    // New app, same database.
    await pump(tester, database: db);
    expect(find.text('Kale'), findsOneWidget); // still in the diary
    await openForm(tester);
    expect(find.text('RECENTLY LOGGED'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LogMealPage),
        matching: find.text('Kale'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('existing entries are preserved when logging more', (
    tester,
  ) async {
    final (_, db) = await pump(tester);
    await logFood(tester, db, 'kale', 'Kale', DiaryMeal.breakfast);
    await logFood(tester, db, 'apple', 'Apple', DiaryMeal.snack, daysAgo: 2);
    await tester.pumpAndSettle();
    final before = await all(tester, db);
    await openForm(tester);
    await tester.enterText(find.byType(EditableText).first, 'salmon');
    await tester.pumpAndSettle();
    await tapText(tester, 'Salmon');
    await saveForm(tester);
    final after = await all(tester, db);
    expect(after, hasLength(before.length + 1));
    for (final e in before) {
      final same = after.singleWhere((a) => a.id == e.id);
      expect(same.title, e.title);
      expect(same.meal, e.meal);
      expect(same.date, e.date);
    }
  });

  testWidgets('a recent food that left the catalogue is skipped, not a crash', (
    tester,
  ) async {
    final (_, db) = await pump(tester);
    await logFood(tester, db, 'removed-food', 'Old thing', DiaryMeal.lunch);
    await logFood(tester, db, 'kale', 'Kale', DiaryMeal.lunch);
    await tester.pumpAndSettle();
    await openForm(tester);
    expect(tester.takeException(), isNull);
    final inForm = find.descendant(
      of: find.byType(LogMealPage),
      matching: find.text('Old thing'),
    );
    expect(inForm, findsNothing);
    expect(
      find.descendant(
        of: find.byType(LogMealPage),
        matching: find.text('Kale'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the saved toast is at the top and never covers the new entry', (
    tester,
  ) async {
    await pump(tester);
    await openForm(tester);
    await tester.enterText(find.byType(EditableText).first, 'salmon');
    await tester.pumpAndSettle();
    await tapText(tester, 'Salmon');
    await tapText(tester, 'Save to diary');
    final toast = find.text('Added to your diary');
    expect(toast, findsOneWidget);
    expect(find.byType(DiaryPage), findsOneWidget);
    final entry = find.text('Salmon');
    expect(entry, findsOneWidget);
    final toastBox = tester.getRect(
      find.ancestor(of: toast, matching: find.byType(Material)).first,
    );
    final entryBox = tester.getRect(entry);
    expect(toastBox.bottom, lessThan(entryBox.top));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('the form header stacks Cancel above the title at large text', (
    tester,
  ) async {
    await pump(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openForm(tester);
    final cancel = tester.getTopLeft(find.text('Cancel'));
    final title = tester.getTopLeft(find.text('Log a meal'));
    expect(title.dy, greaterThan(cancel.dy));
    expect(tester.takeException(), isNull);
  });
}
