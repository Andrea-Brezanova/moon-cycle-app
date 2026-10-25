import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/application/collections_providers.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/collections/presentation/collection_category_page.dart';
import 'package:moon_cycle/features/collections/presentation/collection_link_detail_page.dart';
import 'package:moon_cycle/features/collections/presentation/collection_link_page.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/application/recipe_list.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

/// The form's own text fields (the page underneath has a search field too).
Finder formFields() => find.descendant(
  of: find.byType(CollectionLinkPage),
  matching: find.byType(EditableText),
);

void main() {
  late List<Uri> opened;
  late bool canOpen;

  Future<ProviderContainer> pumpCollections(WidgetTester tester) async {
    opened = [];
    canOpen = true;
    tester.view.physicalSize = const Size(390, 1500) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return canOpen;
        }),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-collections-card')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsPage), findsOneWidget);
    return container;
  }

  Future<void> fillAndSave(
    WidgetTester tester, {
    required String address,
    required String title,
    String? creator,
    String? note,
    String? category,
  }) async {
    if (category != null) {
      await tester.tap(find.bySemanticsLabel(category));
      await tester.pumpAndSettle();
    }
    final fields = formFields();
    await tester.enterText(fields.at(0), address);
    await tester.enterText(fields.at(1), title);
    if (creator != null) await tester.enterText(fields.at(2), creator);
    if (note != null) await tester.enterText(fields.at(3), note);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('link-save')));
    await tester.pumpAndSettle();
  }

  Future<void> addFromLanding(
    WidgetTester tester, {
    required String address,
    required String title,
    String? creator,
    String? note,
    required String category,
  }) async {
    await tester.tap(find.byKey(const ValueKey('add-to-collections')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionLinkPage), findsOneWidget);
    await fillAndSave(
      tester,
      address: address,
      title: title,
      creator: creator,
      note: note,
      category: category,
    );
  }

  testWidgets('one Add flow: pick Workouts, save; it lands in My Workouts and '
      'in Recently saved', (tester) async {
    final c = await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'instagram.com/reel/abc',
      title: 'Morning flow',
      creator: 'Sam',
      note: 'Gentle',
      category: 'Workouts',
    );
    expect(find.byType(CollectionsPage), findsOneWidget);
    expect(find.text('Morning flow'), findsOneWidget); // recently saved
    expect(find.text('Instagram'), findsWidgets); // the badge
    expect(find.text('Sam'), findsWidgets);
    expect(find.text('1 saved link'), findsOneWidget);
    final saved = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(saved!.single.category, LinkCategory.workouts);
    expect(saved.single.url.toString(), 'https://instagram.com/reel/abc');

    await tester.tap(find.byKey(const ValueKey('collection-workouts')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionCategoryPage), findsOneWidget);
    expect(find.text('Morning flow'), findsOneWidget);
    expect(find.text('Instagram'), findsWidgets); // the source badge
    expect(find.text('Sam'), findsWidgets);
    expect(find.text('“Gentle”'), findsOneWidget);
  });

  testWidgets('an unsafe or malformed address is refused with a reason and '
      'nothing is saved', (tester) async {
    final c = await pumpCollections(tester);
    await tester.tap(find.byKey(const ValueKey('add-to-collections')));
    await tester.pumpAndSettle();
    await fillAndSave(tester, address: 'javascript:alert(1)', title: 'x');
    expect(find.byType(CollectionLinkPage), findsOneWidget);
    expect(
      find.textContaining('web address that starts with http'),
      findsOneWidget,
    );
    await tester.enterText(formFields().at(0), 'https://ok.com/a');
    await tester.enterText(formFields().at(1), '   ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('link-save')));
    await tester.pumpAndSettle();
    expect(find.text('Give it a name.'), findsOneWidget);
    final saved = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(saved, isEmpty);
  });

  testWidgets('the open button opens the original; if nothing can open it, '
      'it says so', (tester) async {
    await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'https://www.youtube.com/watch?v=abc',
      title: 'Evening calm',
      category: 'Spa',
    );
    await tester.tap(find.byKey(const ValueKey('collection-spa')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open Evening calm on YouTube'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://www.youtube.com/watch?v=abc');
    canOpen = false;
    await tester.tap(find.bySemanticsLabel('Open Evening calm on YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t open that link.'), findsOneWidget);
  });

  testWidgets('a row opens the saved-link details: source, creator, note, '
      'collection, saved date and address, with Open', (tester) async {
    await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'https://www.youtube.com/watch?v=abc',
      title: '15-minute gentle yoga flow',
      creator: 'Slow Flow Studio',
      note: 'Good for slower evenings.',
      category: 'Workouts',
    );
    await tester.tap(find.byKey(const ValueKey('collection-workouts')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15-minute gentle yoga flow'));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionLinkDetailPage), findsOneWidget);
    expect(find.text('Saved link'), findsOneWidget);
    expect(find.text('Video on YouTube'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('15-minute gentle yoga flow'), findsOneWidget);
    expect(find.textContaining('Original creator: '), findsOneWidget);
    expect(find.textContaining('Slow Flow Studio'), findsOneWidget);
    expect(find.text('Good for slower evenings.'), findsOneWidget);
    expect(find.text('My Workouts'), findsOneWidget); // the collection row
    expect(find.text('youtube.com'), findsOneWidget);
    expect(find.text('Open in YouTube'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('link-open')));
    await tester.pumpAndSettle();
    expect(opened.single.host, 'www.youtube.com');
  });

  testWidgets('edit from the details, then move it to Spa from More actions, '
      'then remove it with confirmation', (tester) async {
    final c = await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'https://example.com/a',
      title: 'A walk',
      category: 'Workouts',
    );
    await tester.tap(find.byKey(const ValueKey('collection-workouts')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A walk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('link-edit')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionLinkPage), findsOneWidget);
    expect(
      tester.widget<EditableText>(formFields().at(1)).controller.text,
      'A walk',
    );
    await tester.enterText(formFields().at(1), 'A calm walk');
    await tester.enterText(formFields().at(3), 'Slowly');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('link-save')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionLinkDetailPage), findsOneWidget);
    expect(find.text('A calm walk'), findsOneWidget);
    expect(find.text('Slowly'), findsOneWidget);

    // Move it: More actions, then My Spa.
    await tester.tap(find.byKey(const ValueKey('link-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-sounds')));
    await tester.pumpAndSettle();
    expect(find.text('My Spa'), findsOneWidget); // the collection row
    var links = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(links!.single.category, LinkCategory.sounds);

    // Remove: asked first.
    await tester.ensureVisible(find.byKey(const ValueKey('link-remove')));
    await tester.tap(find.byKey(const ValueKey('link-remove')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this link?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    links = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(links, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('link-remove')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CollectionLinkDetailPage), findsNothing);
    links = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(links, isEmpty);
  });

  testWidgets('the form recognises the platform from the address, including '
      'Spotify, and says nothing is downloaded', (tester) async {
    await pumpCollections(tester);
    await tester.tap(find.byKey(const ValueKey('add-to-collections')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('platform-note')), findsNothing);
    for (final (address, expected) in [
      ('https://open.spotify.com/episode/x', 'Spotify link. It will open in '),
      ('instagram.com/reel/abc', 'Instagram link. It will open in '),
      ('https://www.tiktok.com/@a/video/1', 'TikTok link. It will open in '),
      ('https://www.pinterest.com/pin/1', 'Pinterest link. It will open in '),
      ('https://example.com/recipe', 'Website link. It will open in your '),
    ]) {
      await tester.enterText(formFields().at(0), address);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('platform-note'))).data,
        startsWith(expected),
        reason: address,
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('platform-note'))).data,
        contains('nothing is downloaded'),
      );
    }
  });

  testWidgets('My Workouts filters by source, with live counts', (
    tester,
  ) async {
    await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'https://www.youtube.com/watch?v=1',
      title: 'Yoga flow',
      category: 'Workouts',
    );
    await addFromLanding(
      tester,
      address: 'https://www.instagram.com/reel/2',
      title: 'Pilates basics',
      category: 'Workouts',
    );
    await addFromLanding(
      tester,
      address: 'https://www.youtube.com/watch?v=3',
      title: 'Strength circuit',
      category: 'Workouts',
    );
    await tester.tap(find.byKey(const ValueKey('collection-workouts')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('All, 3'), findsOneWidget);
    expect(find.bySemanticsLabel('YouTube, 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Instagram, 1'), findsOneWidget);
    for (final t in ['Yoga flow', 'Pilates basics', 'Strength circuit']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('YouTube, 2'));
    await tester.pumpAndSettle();
    expect(find.text('Pilates basics'), findsNothing);
    expect(find.text('Yoga flow'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Instagram, 1'));
    await tester.pumpAndSettle();
    expect(find.text('Yoga flow'), findsNothing);
    expect(find.text('Pilates basics'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('All, 3'));
    await tester.pumpAndSettle();
    expect(find.text('Strength circuit'), findsOneWidget);
  });

  testWidgets('a recipe link sits in My Recipes under All and Links, and '
      'changes no recipe search', (tester) async {
    final c = await pumpCollections(tester);
    final before = c.read(recipeListProvider).recipes.length;
    await addFromLanding(
      tester,
      address: 'https://www.pinterest.com/pin/1',
      title: 'Pin: lentil dal',
      category: 'Recipes',
    );
    await tester.tap(find.byKey(const ValueKey('collection-recipes')));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(find.text('All 1'), findsOneWidget);
    expect(find.text('Links 1'), findsOneWidget);
    expect(find.text('Pin: lentil dal'), findsOneWidget);
    await tester.tap(find.text('Saved 0'));
    await tester.pumpAndSettle();
    expect(find.text('Pin: lentil dal'), findsNothing);
    await tester.tap(find.text('Added by me 0'));
    await tester.pumpAndSettle();
    expect(find.text('Pin: lentil dal'), findsNothing);
    await tester.tap(find.text('Links 1'));
    await tester.pumpAndSettle();
    expect(find.text('Pin: lentil dal'), findsOneWidget);
    // It is a link, not a recipe: no search or list changes.
    expect(c.read(recipeListProvider).recipes.length, before);
  });
}
