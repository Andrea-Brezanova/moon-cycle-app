import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/collections/presentation/collection_category_page.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/collections/presentation/my_routines_page.dart';
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
    final card = find.byKey(const ValueKey('me-collections'));
    expect(card, findsOneWidget);
    // First section, above My Diary; the rest stays.
    expect(
      tester.getTopLeft(card).dy,
      lessThan(tester.getTopLeft(find.text('My Diary')).dy),
    );
    for (final t in ['My Diary', 'My Shopping List']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets(
    'the landing page: four equal square tiles, recently saved, links to '
    'the existing My recipes',
    (tester) async {
      await pumpMe(tester);
      await tester.tap(find.byKey(const ValueKey('me-collections')));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionsPage), findsOneWidget);
      for (final t in ['My Recipes', 'My Workouts', 'My Spa', 'My Routines']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('My Sounds'), findsNothing); // renamed
      expect(
        find.text('Saved Links'),
        findsNothing,
      ); // links are not a category
      expect(
        find.text('Things you love, save or want to try.'),
        findsOneWidget,
      );
      expect(find.text('Search your collections'), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsWidgets);
      // Four tiles, all exactly the same size, two per row, with the picture,
      // the divider and the title in the same place on each.
      final sizes = [
        for (final k in [
          'collection-recipes',
          'collection-workouts',
          'collection-spa',
          'collection-routines',
        ])
          tester.getSize(find.byKey(ValueKey(k))),
      ];
      for (final z in sizes) {
        expect(z.width, closeTo(sizes.first.width, 0.5));
        expect(z.height, closeTo(sizes.first.height, 0.5));
      }
      // In every tile the title and the arrow share one horizontal centre
      // line, and that line sits in the same place in all four tiles.
      final lines = <double>[];
      for (final k in [
        'collection-recipes',
        'collection-workouts',
        'collection-spa',
        'collection-routines',
      ]) {
        final tile = find.byKey(ValueKey(k));
        final top = tester.getTopLeft(tile).dy;
        Rect part(String key) => tester.getRect(
          find.descendant(of: tile, matching: find.byKey(ValueKey(key))),
        );
        final title = part('tile-title');
        final arrow = part('tile-arrow');
        expect(title.center.dy, closeTo(arrow.center.dy, 1), reason: k);
        lines.add(arrow.center.dy - top);
      }
      for (final l in lines) {
        expect(l, closeTo(lines.first, 1));
      }
      // Same picture height and divider position in every tile.
      final pictures = <double>[
        for (final k in [
          'collection-recipes',
          'collection-workouts',
          'collection-spa',
          'collection-routines',
        ])
          tester
              .getSize(
                find.descendant(
                  of: find.byKey(ValueKey(k)),
                  matching: find.byType(AspectRatio),
                ),
              )
              .height,
      ];
      for (final h in pictures) {
        expect(h, closeTo(pictures.first, 0.5));
      }

      await tester.tap(find.byKey(const ValueKey('collection-recipes')));
      await tester.pumpAndSettle();
      expect(find.byType(MyRecipesPage), findsOneWidget); // the existing screen
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();

      for (final key in ['collection-workouts', 'collection-spa']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(
          find.byType(CollectionCategoryPage),
          findsOneWidget,
          reason: key,
        );
        expect(find.textContaining('Save a link'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const ValueKey('collection-routines')));
      await tester.pumpAndSettle();
      expect(find.byType(MyRoutinesPage), findsOneWidget);
      expect(find.text('No routines yet'), findsOneWidget);
    },
  );

  testWidgets('a hearted recipe appears under recently saved and counts once, '
      'with no second copy', (tester) async {
    final c = await pumpMe(tester);
    final repo = c.read(savedRecipeRepositoryProvider);
    await tester.runAsync(
      () => repo.save(providerId: 'moon-cycle', refId: 'x', title: frittata),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-collections')));
    await tester.pumpAndSettle();
    expect(find.text(frittata), findsOneWidget);
    expect(find.text('Recipe'), findsOneWidget); // the badge
    expect(find.text('From Moon Cycle'), findsOneWidget);
    // The tiles carry only their titles: no counts or status text.
    for (final t in ['1 saved', 'Nothing yet', '1 link', 'Not available yet']) {
      expect(find.text(t), findsNothing, reason: t);
    }
    await tester.tap(find.text(frittata));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
  });

  testWidgets('search finds items across categories by title, source or '
      'creator', (tester) async {
    final c = await pumpMe(tester);
    final repo = c.read(collectionLinkRepositoryProvider);
    // In the test's fake time, as a tap would (real async can deadlock here).
    final done = () async {
      await repo.add(
        category: LinkCategory.workouts,
        address: 'https://www.youtube.com/watch?v=1',
        title: 'Gentle yoga flow',
        creator: 'Slow Flow Studio',
      );
      await repo.add(
        category: LinkCategory.sounds,
        address: 'https://example.com/tea',
        title: 'Tea ritual',
      );
    }();
    await tester.pumpAndSettle();
    await done;
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-collections')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'slow flow');
    await tester.pumpAndSettle();
    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('Gentle yoga flow'), findsOneWidget);
    expect(find.text('Tea ritual'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing matches'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recently saved'.toUpperCase()), findsOneWidget);
    expect(find.text('Tea ritual'), findsOneWidget);
  });

  testWidgets('the Me card shows no count', (tester) async {
    final c = await pumpMe(tester);
    expect(find.text('Recipes, workouts, spa and routines'), findsOneWidget);
    final done = c
        .read(savedRecipeRepositoryProvider)
        .save(providerId: 'moon-cycle', refId: 'x', title: frittata);
    await tester.pumpAndSettle();
    await done;
    await tester.pumpAndSettle();
    expect(find.text('1 saved'), findsNothing);
    expect(find.text('Recipes, workouts, spa and routines'), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('Me and My Collections fit at ${width}pt, $scale× text', (
      tester,
    ) async {
      await pumpMe(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('me-collections')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CollectionsPage), findsOneWidget);
    });
  }
}
