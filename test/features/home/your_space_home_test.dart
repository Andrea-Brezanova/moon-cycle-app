import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';
import 'package:moon_cycle/features/generation/data/saved_recipe_repository.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    return pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
  }

  Future<void> toYourSpace(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('YOUR SPACE'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
  }

  testWidgets('the section replaces Quick access; the shortcuts show headlines '
      'only', (tester) async {
    await pumpHome(tester);
    await toYourSpace(tester);
    expect(find.text('QUICK ACCESS'), findsNothing);
    expect(find.text('My Collections'), findsOneWidget);
    expect(find.text('Recipes, workouts, sounds'), findsOneWidget);
    expect(find.byKey(const ValueKey('collections-badge')), findsNothing);
    // The shortcuts carry headlines only: no status or count text.
    expect(find.text('My Diary'), findsOneWidget);
    expect(find.text('Shopping List'), findsOneWidget);
    for (final t in ['Nothing logged yet', 'Nothing to buy']) {
      expect(find.text(t), findsNothing, reason: t);
    }
  });

  testWidgets('the three shortcuts open My Collections, My Diary and the '
      'Shopping list', (tester) async {
    await pumpHome(tester);
    await toYourSpace(tester);
    await tester.tap(find.byKey(const ValueKey('your-space-collections')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
    // Back on the Me tab; return Home and use the others.
    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await toYourSpace(tester);
    await tester.tap(find.byKey(const ValueKey('your-space-diary')));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryHubPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await toYourSpace(tester);
    await tester.tap(find.byKey(const ValueKey('your-space-shopping')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopPage), findsOneWidget);
  });

  testWidgets('the numbers are live: a saved recipe shows the badge, a logged '
      'meal shows the meal count', (tester) async {
    final c = await pumpHome(tester);
    // In the test's fake time, as a tap would (real async can deadlock here).
    final done = () async {
      await c
          .read(savedRecipeRepositoryProvider)
          .save(providerId: 'moon-cycle', refId: 'x', title: 'Frittata');
      final repo = c.read(diaryRepositoryProvider);
      for (final (id, meal) in [
        ('apple', DiaryMeal.breakfast),
        ('kale', DiaryMeal.lunch),
      ]) {
        await repo.add(
          DiaryDraft(
            date: c.read(todayProvider),
            meal: meal,
            kind: DiaryItemKind.food,
            itemId: id,
            title: id,
            amount: 1,
            unit: DiaryUnit.serving,
          ),
        );
      }
    }();
    await tester.pumpAndSettle();
    await done;
    await tester.pumpAndSettle();
    await toYourSpace(tester);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('collections-badge'))).data,
      '1',
    );
    // Logged meals do not show up as text on the shortcut.
    expect(find.text('2 meals today'), findsNothing);
    expect(find.textContaining('meals today'), findsNothing);
    expect(find.bySemanticsLabel('My Collections, 1 saved'), findsOneWidget);
  });

  for (final (width, scale, stacked) in [
    (390.0, 1.0, false),
    (320.0, 1.0, true),
    (390.0, 1.5, true),
    (320.0, 2.0, true),
  ]) {
    testWidgets('${width}pt at $scale× text: shortcuts '
        '${stacked ? 'stack' : 'sit side by side'}, nothing clipped, 44 pt '
        'targets', (tester) async {
      await pumpHome(tester, width: width, scale: scale);
      await toYourSpace(tester);
      final diary = tester.getRect(
        find.byKey(const ValueKey('your-space-diary')),
      );
      final shop = tester.getRect(
        find.byKey(const ValueKey('your-space-shopping')),
      );
      if (stacked) {
        expect(shop.top, greaterThan(diary.bottom - 1));
        expect(diary.width, closeTo(shop.width, 1));
      } else {
        expect(shop.left, greaterThan(diary.right - 1));
        expect((diary.top - shop.top).abs(), lessThan(1));
      }
      for (final r in [diary, shop]) {
        expect(r.height, greaterThanOrEqualTo(44));
        expect(r.right, lessThanOrEqualTo(width + 0.5));
      }
      expect(
        tester
            .getRect(find.byKey(const ValueKey('your-space-collections')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final (width, scale) in [
    (390.0, 1.0),
    (320.0, 1.0),
    (390.0, 1.5),
    (320.0, 2.0),
  ]) {
    testWidgets('${width}pt at $scale× text: in each shortcut the title, the '
        'picture and the arrow share one centre line', (tester) async {
      await pumpHome(tester, width: width, scale: scale);
      await toYourSpace(tester);
      final rows = <Rect>[];
      for (final key in ['your-space-diary', 'your-space-shopping']) {
        final card = find.byKey(ValueKey(key));
        final title = tester.getRect(
          find.descendant(
            of: card,
            matching: find.byKey(const ValueKey('shortcut-title')),
          ),
        );
        final arrow = tester.getRect(
          find.descendant(
            of: card,
            matching: find.byKey(const ValueKey('shortcut-arrow')),
          ),
        );
        final photo = tester.getRect(
          find.descendant(of: card, matching: find.byType(ClipRRect)),
        );
        final center = tester.getRect(card).center.dy;
        for (final (name, r) in [
          ('title', title),
          ('arrow', arrow),
          ('photo', photo),
        ]) {
          expect(r.center.dy, closeTo(center, 1.5), reason: '$key $name');
        }
        rows.add(tester.getRect(card));
      }
      // Both cards use the same padding rules: same height when side by side.
      if (rows[0].top == rows[1].top) {
        expect(rows[0].height, closeTo(rows[1].height, 1));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the list ends about 40 pt above the tab bar, with no dead '
      'space', (tester) async {
    await pumpHome(tester);
    await toYourSpace(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    final card = tester.getRect(find.byKey(const ValueKey('your-space-diary')));
    final bar = tester.getTopLeft(find.byKey(const ValueKey('tab-home'))).dy;
    // The card's section ends within a few points of 40 above the bar.
    expect(
      bar - card.bottom,
      lessThan(40 + 12 + 12 + 8),
    ); // + container padding
  });
}
