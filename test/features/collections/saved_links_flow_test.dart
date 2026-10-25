import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/application/collections_providers.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/collections/presentation/collection_category_page.dart';
import 'package:moon_cycle/features/collections/presentation/collection_link_page.dart';
import 'package:moon_cycle/features/collections/presentation/collections_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/application/recipe_list.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

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
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), address);
    await tester.enterText(fields.at(1), title);
    if (creator != null) await tester.enterText(fields.at(2), creator);
    if (note != null) await tester.enterText(fields.at(3), note);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save link'));
    await tester.tap(find.text('Save link'));
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
    expect(find.text('Workout link · Instagram'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    final saved = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(saved!.single.category, LinkCategory.workouts);
    expect(saved.single.url.toString(), 'https://instagram.com/reel/abc');

    await tester.tap(find.byKey(const ValueKey('collection-workouts')));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionCategoryPage), findsOneWidget);
    expect(find.text('Morning flow'), findsOneWidget);
    expect(find.text('Instagram · Sam'), findsOneWidget);
    expect(find.text('Gentle'), findsOneWidget);
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
    await tester.enterText(find.byType(EditableText).at(0), 'https://ok.com/a');
    await tester.enterText(find.byType(EditableText).at(1), '   ');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save link'));
    await tester.tap(find.text('Save link'));
    await tester.pumpAndSettle();
    expect(find.text('Give it a name.'), findsOneWidget);
    final saved = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(saved, isEmpty);
  });

  testWidgets('tapping a link opens the original; if nothing can open it, '
      'it says so', (tester) async {
    await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'https://www.youtube.com/watch?v=abc',
      title: 'Evening calm',
      category: 'Sounds',
    );
    await tester.tap(find.byKey(const ValueKey('collection-sounds')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening calm'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://www.youtube.com/watch?v=abc');
    canOpen = false;
    await tester.tap(find.text('Evening calm'));
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t open that link.'), findsOneWidget);
  });

  testWidgets('edit, change the category, then delete with confirmation', (
    tester,
  ) async {
    final c = await pumpCollections(tester);
    await addFromLanding(
      tester,
      address: 'https://example.com/a',
      title: 'A walk',
      category: 'Workouts',
    );
    await tester.tap(find.byKey(const ValueKey('collection-workouts')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Edit A walk'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(1))
          .controller
          .text,
      'A walk',
    );
    await tester.tap(find.bySemanticsLabel('Sounds'));
    await tester.enterText(find.byType(EditableText).at(1), 'A calm walk');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    // It left My Workouts and is now in My Sounds.
    expect(find.text('A calm walk'), findsNothing);
    expect(find.text('No workouts saved yet'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-sounds')));
    await tester.pumpAndSettle();
    expect(find.text('A calm walk'), findsOneWidget);

    // Delete: asked first.
    await tester.tap(find.bySemanticsLabel('Edit A calm walk'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete this link'));
    await tester.tap(find.text('Delete this link'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this link?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    var links = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(links, hasLength(1));
    await tester.tap(find.text('Delete this link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('A calm walk'), findsNothing);
    links = await tester.runAsync(
      () => c.read(collectionLinkRepositoryProvider).all(),
    );
    expect(links, isEmpty);
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
