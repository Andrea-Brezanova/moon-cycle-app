import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/presentation/collection_category_page.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/generation/data/saved_recipe_repository.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

const frittata = 'Zucchini & Feta Herb Frittata';

void main() {
  Future<ProviderContainer> pumpMe(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1100) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('the fifth tab is Me, with My Collections first', (tester) async {
    await pumpMe(tester);
    expect(find.text('Me'), findsWidgets);
    expect(find.text('More'), findsNothing);
    final card = find.byKey(const ValueKey('my-collections-card'));
    expect(card, findsOneWidget);
    // First section, above My Diary; the rest stays.
    expect(
      tester.getTopLeft(card).dy,
      lessThan(tester.getTopLeft(find.text('My Diary')).dy),
    );
    for (final t in ['My Diary', 'Shopping list']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('the landing page: three categories, recently saved, links to '
      'the existing My recipes', (tester) async {
    await pumpMe(tester);
    await tester.tap(find.byKey(const ValueKey('my-collections-card')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsPage), findsOneWidget);
    for (final t in ['My Recipes', 'My Workouts', 'My Sounds']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Saved Links'), findsNothing); // links are not a category
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('collection-recipes')));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget); // the existing screen
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();

    for (final key in ['collection-workouts', 'collection-sounds']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionCategoryPage), findsOneWidget, reason: key);
      expect(find.textContaining('No '), findsWidgets);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a hearted recipe appears under recently saved and counts once, '
      'with no second copy', (tester) async {
    final c = await pumpMe(tester);
    final repo = c.read(savedRecipeRepositoryProvider);
    await tester.runAsync(
      () => repo.save(providerId: 'moon-cycle', refId: 'x', title: frittata),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-collections-card')));
    await tester.pumpAndSettle();
    expect(find.text(frittata), findsOneWidget);
    expect(find.text('Saved recipe'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget); // My Recipes
    expect(find.text('Nothing yet'), findsNWidgets(2)); // workouts, sounds
    await tester.tap(find.text(frittata));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('Me and My Collections fit at ${width}pt, $scale× text', (
      tester,
    ) async {
      await pumpMe(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('my-collections-card')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CollectionsPage), findsOneWidget);
    });
  }
}
