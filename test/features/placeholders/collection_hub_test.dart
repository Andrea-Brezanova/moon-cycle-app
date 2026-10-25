import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/collections/presentation/collection_category_page.dart';
import 'package:moon_cycle/features/collections/presentation/collection_link_page.dart';
import 'package:moon_cycle/features/placeholders/presentation/collection_hub_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<ProviderContainer> pumpTab(
    WidgetTester tester,
    String tab, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1000) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(ValueKey('tab-$tab')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionHubPage), findsOneWidget);
    return c;
  }

  for (final (tab, open, add, page) in [
    ('move', 'Your workouts', 'Save a workout link', 'My Workouts'),
    ('relax', 'Your spa', 'Save a meditation or sound link', 'My Spa'),
  ]) {
    testWidgets('$tab: honest about what is coming, and offers only what '
        'works', (tester) async {
      await pumpTab(tester, tab);
      expect(
        find.textContaining('being prepared and reviewed'),
        findsOneWidget,
      );
      expect(find.text('Coming soon'), findsNothing);
      expect(find.text(open), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      // Open what you saved.
      await tester.tap(find.byKey(ValueKey('hub-open-$tab')));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionCategoryPage), findsOneWidget);
      expect(find.text(page), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
      await tester.pumpAndSettle();
      // Save a link: the form starts in the right collection.
      await tester.tap(find.byKey(ValueKey('hub-add-$tab')));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionLinkPage), findsOneWidget);
      expect(find.text(add), findsNothing);
      await tester.tap(find.byKey(const ValueKey('link-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionHubPage), findsOneWidget);
    });
  }

  testWidgets('the count follows what is saved', (tester) async {
    final c = await pumpTab(tester, 'move');
    final done = c
        .read(collectionLinkRepositoryProvider)
        .add(
          category: LinkCategory.workouts,
          address: 'https://www.youtube.com/watch?v=1',
          title: 'Yoga flow',
        );
    await tester.pumpAndSettle();
    await done;
    await tester.pumpAndSettle();
    expect(find.text('1 saved item'), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('fits $width pt at $scale× text', (tester) async {
      await pumpTab(tester, 'move', width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await pumpTab(tester, 'relax', width: width, scale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
