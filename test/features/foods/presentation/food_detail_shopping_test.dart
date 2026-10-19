import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Food detail's shopping-list button reads the stored list, never a local
/// flag: it reflects add, remove, changes made on the list page, and a restart.
void main() {
  Future<(ProviderContainer, AppDatabase)> pump(
    WidgetTester tester, {
    AppDatabase? database,
  }) async {
    tester.view.physicalSize = const Size(390, 1800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = database ?? testDatabase();
    if (database == null) await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    c.read(appRouterProvider).go(Routes.food('broccoli'));
    await tester.pumpAndSettle();
    return (c, db);
  }

  final add = find.text('Add to shopping list');
  final remove = find.text('Remove from shopping list');

  Future<List<String>> keys(WidgetTester tester, AppDatabase db) async => [
    for (final i in (await tester.runAsync(ShoppingRepository(db).items))!)
      i.key,
  ];

  testWidgets('add, then remove, reflected by the button and the data', (
    tester,
  ) async {
    final (_, db) = await pump(tester);
    expect(add, findsOneWidget);
    expect(remove, findsNothing);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(remove, findsOneWidget);
    expect(add, findsNothing);
    expect(await keys(tester, db), ['food:broccoli']);

    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(add, findsOneWidget);
    expect(await keys(tester, db), isEmpty);
  });

  testWidgets('repeated taps never duplicate the food', (tester) async {
    final (_, db) = await pump(tester);
    await tester.tap(add);
    await tester.tap(add, warnIfMissed: false); // button already swapped
    await tester.pumpAndSettle();
    expect(await keys(tester, db), ['food:broccoli']);
    expect(remove, findsOneWidget);
  });

  testWidgets('a change made on the list follows to the food page', (
    tester,
  ) async {
    final (c, _) = await pump(tester);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(remove, findsOneWidget);

    // Removed from the Shopping list page's controller.
    final item = (await tester.runAsync(
      c.read(shoppingRepositoryProvider).items,
    ))!.single;
    await tester.runAsync(
      () => c.read(shoppingControllerProvider.notifier).remove(item),
    );
    await tester.pumpAndSettle();
    expect(add, findsOneWidget);
    expect(remove, findsNothing);

    // Ticked off on the list: it is still on the list, so it still says so.
    await tester.tap(add);
    await tester.pumpAndSettle();
    final again = (await tester.runAsync(
      c.read(shoppingRepositoryProvider).items,
    ))!.single;
    await tester.runAsync(
      () => c.read(shoppingControllerProvider.notifier).toggle(again),
    );
    await tester.pumpAndSettle();
    expect(remove, findsOneWidget);
  });

  testWidgets('state survives navigating away and reopening the page', (
    tester,
  ) async {
    final (c, _) = await pump(tester);
    await tester.tap(add);
    await tester.pumpAndSettle();
    c.read(appRouterProvider).go(Routes.home);
    await tester.pumpAndSettle();
    c.read(appRouterProvider).go(Routes.food('broccoli'));
    await tester.pumpAndSettle();
    expect(remove, findsOneWidget);
    expect(add, findsNothing);
  });

  testWidgets('state survives an app restart (same database, new app)', (
    tester,
  ) async {
    final (_, db) = await pump(tester);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());

    await pump(tester, database: db);
    expect(remove, findsOneWidget);
    expect(add, findsNothing);
  });

  testWidgets('the button is enabled and says "shopping list", never cart', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('cart'), findsNothing);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.textContaining('cart'), findsNothing);
    expect(
      tester.getSemantics(remove).flagsCollection.isEnabled.toString(),
      isNot('Tristate.isFalse'),
    );
  });
}
