import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_catalogue.dart';

void main() {
  Future<(ProviderContainer, AppDatabase)> pumpShop(WidgetTester tester) async {
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
    await tester.tap(find.byKey(const ValueKey('tab-shop')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopPage), findsOneWidget);
    return (container, db);
  }

  /// Runs a list change the way a tap would: in the test's fake time, then
  /// pumps until it (and the streams it updates) are done. (Mixing real
  /// async with the database's fake-time queue can deadlock.)
  Future<void> run(WidgetTester tester, Future<void> Function() action) async {
    final done = action();
    await tester.pumpAndSettle();
    await done;
    await tester.pumpAndSettle();
  }

  ShoppingController controller(ProviderContainer c) =>
      c.read(shoppingControllerProvider.notifier);

  testWidgets('empty: the designed empty state, and a way to Foods', (
    tester,
  ) async {
    await pumpShop(tester);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('to buy'), findsOneWidget);
    expect(find.text('Your list is empty'), findsOneWidget);
    await tester.tap(find.text('Browse foods'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);
  });

  testWidgets('typed items: free text in Other, synonyms become foods', (
    tester,
  ) async {
    await pumpShop(tester);
    await tester.enterText(find.byType(TextField), 'kitchen paper');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'courgette');
    await tester.tap(find.bySemanticsLabel('Add item'));
    await tester.pumpAndSettle();
    expect(find.text('OTHER'), findsOneWidget);
    expect(find.text('Kitchen paper'), findsOneWidget);
    expect(find.text('PRODUCE'), findsOneWidget);
    expect(find.text('Zucchini'), findsOneWidget);
    expect(find.text('Added by you'), findsNWidgets(2));
    // Produce comes before Other.
    expect(
      tester.getTopLeft(find.text('PRODUCE')).dy,
      lessThan(tester.getTopLeft(find.text('OTHER')).dy),
    );
  });

  testWidgets('olive oil is grouped under Pantry, not Other', (tester) async {
    final (container, _) = await pumpShop(tester);
    await run(
      tester,
      () =>
          controller(container)
              .addFood(testCatalogue.food('olive-oil')!, Phase.follicular),
    );
    expect(find.text('PANTRY'), findsOneWidget);
    expect(find.text('OTHER'), findsNothing);
    expect(find.text('Olive oil'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('PANTRY')).dy,
      lessThan(tester.getTopLeft(find.text('Olive oil')).dy),
    );
  });

  testWidgets('tick into Done, open Done, untick back', (tester) async {
    final (container, _) = await pumpShop(tester);
    await run(
      tester,
      () =>
          controller(container)
              .addFood(testCatalogue.food('lemon')!, Phase.follicular),
    );
    expect(find.text('1'), findsOneWidget); // 1 to buy
    await tester.tap(find.text('Lemon'));
    await tester.pumpAndSettle();
    expect(find.text('1 done'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Lemon'), findsNothing); // Done starts collapsed
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Lemon'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Lemon')),
      isSemantics(
        isChecked: true,
        hasCheckedState: true,
        hasTapAction: true,
        label: 'Lemon, Phase staple',
      ),
    );
    await tester.tap(find.text('Lemon'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('× removes at once', (tester) async {
    final (container, _) = await pumpShop(tester);
    await run(
      tester,
      () =>
          controller(container)
              .addFood(testCatalogue.food('kale')!, Phase.menstrual),
    );
    await tester.tap(find.bySemanticsLabel('Remove Kale'));
    await tester.pumpAndSettle();
    expect(find.text('Kale'), findsNothing);
    expect(find.text('Your list is empty'), findsOneWidget);
  });

  testWidgets('Clear all, then Undo; the offer ends after 8 seconds', (
    tester,
  ) async {
    final (container, _) = await pumpShop(tester);
    final c = controller(container);
    await run(tester, () async {
      await c.addFood(testCatalogue.food('lemon')!, Phase.follicular);
      await c.addFood(testCatalogue.food('kale')!, Phase.menstrual);
    });
    await tester.tap(find.text('Lemon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('1 done item cleared'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('1 done item cleared'), findsNothing);
    expect(find.text('1 done'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.text('1 done item cleared'), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('a food from a phase and a recipe: merged', (tester) async {
    final (container, _) = await pumpShop(tester);
    final c = controller(container);
    await run(tester, () async {
      await c.addFood(testCatalogue.food('lemon')!, Phase.follicular);
      await c.addRecipe(testCatalogue.recipe('lemon-chicken-green-bean-tray')!);
    });
    expect(find.text('Merged'), findsOneWidget);
    expect(
      find.text('Phase staple + Lemon Chicken & Green Bean Tray Bake'),
      findsOneWidget,
    );
  });

  testWidgets('Home’s shopping block follows the list', (tester) async {
    final (container, _) = await pumpShop(tester);
    await run(
      tester,
      () =>
          controller(container)
              .addRecipe(testCatalogue.recipe('avocado-egg-arugula-toast')!),
    );
    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('7 to buy · 7 from recipes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('7 to buy · 7 from recipes'), findsOneWidget);
  });
}
