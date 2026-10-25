@Tags(['golden'])
library;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/collections/application/collections_providers.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/collections/presentation/collection_category_page.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/generation/data/saved_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/saved_recipe_ref.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';

/// Test data only: made-up links and the app's own recipe ids.
CollectionLink link(
  String id,
  LinkCategory category,
  String url,
  String title, {
  String? creator,
  String? note,
  int minutes = 0,
}) => CollectionLink(
  id: id,
  category: category,
  url: Uri.parse(url),
  title: title,
  platform: platformOf(Uri.parse(url)),
  creator: creator,
  note: note,
  createdAt: DateTime(2026, 10, 20, 9, minutes),
  updatedAt: DateTime(2026, 10, 20, 9, minutes),
);

final saved = [
  SavedRecipeRef(
    id: 's1',
    providerId: 'moon-cycle',
    refId: 'zucchini-feta-herb-frittata',
    title: 'Zucchini & Feta Herb Frittata',
    savedAt: DateTime(2026, 10, 21, 8),
  ),
];

final links = [
  link(
    'l1',
    LinkCategory.workouts,
    'https://www.youtube.com/watch?v=1',
    '15-minute gentle yoga flow',
    creator: 'Slow Flow Studio',
    note: 'Good for slower evenings.',
    minutes: 1,
  ),
  link(
    'l2',
    LinkCategory.workouts,
    'https://www.instagram.com/reel/2',
    'Pilates for beginners',
    creator: '@corestudio.daily',
    minutes: 2,
  ),
  link(
    'l3',
    LinkCategory.sounds,
    'https://www.youtube.com/watch?v=3',
    'Rain on the window',
    creator: 'Quiet Hours',
    note: 'For falling asleep.',
    minutes: 3,
  ),
  link(
    'l4',
    LinkCategory.recipes,
    'https://www.pinterest.com/pin/4',
    'Roasted squash & lentil salad',
    minutes: 4,
  ),
];

void main() {
  setUpAll(loadMoonFonts);

  List<Override> data() => [
    savedRecipeRefsProvider.overrideWith((ref) => Stream.value(saved)),
    collectionLinksProvider.overrideWith((ref) => Stream.value(links)),
  ];

  for (final (name, dark, width, scale) in [
    ('light', false, 390.0, 1.0),
    ('dark', true, 390.0, 1.0),
    ('narrow-large-text', false, 320.0, 1.5),
  ]) {
    testWidgets('collections landing, $name', (tester) async {
      await pumpScreen(
        tester,
        const CollectionsPage(),
        dark: dark,
        width: width,
        textScale: scale,
        height: scale > 1 ? 2400 : 1000,
        overrides: data(),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CollectionsPage),
        matchesGoldenFile('goldens/collections-landing-$name.png'),
      );
    });

    testWidgets('my workouts, $name', (tester) async {
      await pumpScreen(
        tester,
        const CollectionCategoryPage(category: CollectionCategory.workouts),
        dark: dark,
        width: width,
        textScale: scale,
        height: scale > 1 ? 1600 : 800,
        overrides: data(),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CollectionCategoryPage),
        matchesGoldenFile('goldens/collections-workouts-$name.png'),
      );
    });
  }

  testWidgets('my spa, dark', (tester) async {
    await pumpScreen(
      tester,
      const CollectionCategoryPage(category: CollectionCategory.spa),
      dark: true,
      width: 390,
      height: 800,
      overrides: data(),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CollectionCategoryPage),
      matchesGoldenFile('goldens/collections-spa-dark.png'),
    );
  });
}
