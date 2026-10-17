import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';
import 'package:moon_cycle/core/design/tokens/moon_colors.dart';
import 'package:moon_cycle/core/design/widgets/recipe_photo.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/recipes/presentation/widgets/recipe_widgets.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/test_catalogue.dart';

/// A 1×1 PNG, so a "real" image decodes in tests.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

void main() {
  final recipes = testCatalogue.recipes;

  // The first 40 recipes have approved photos; the other 72 use the fallback
  // until their photos exist.
  final photographed = recipes.take(40).toList();
  final unphotographed = recipes.skip(40).toList();

  test('there are 112 recipes, each id mapping to its own image path', () {
    expect(recipes, hasLength(112));
    expect({for (final r in recipes) r.imageAsset}, hasLength(112));
    for (final r in recipes) {
      expect(r.imageAsset, 'assets/images/recipes/${r.id}.jpg');
    }
  });

  test('the original 40 recipes still resolve to their photos', () {
    expect(photographed, hasLength(40));
    final missing = [
      for (final r in photographed)
        if (!File(r.imageAsset).existsSync()) r.imageAsset,
    ];
    expect(missing, isEmpty, reason: 'missing: $missing');
  });

  test('the other 72 recipes have no photo and use the fallback', () {
    expect(unphotographed, hasLength(72));
    for (final r in unphotographed) {
      expect(File(r.imageAsset).existsSync(), isFalse, reason: r.id);
    }
  });

  test('no two recipes share the same image file', () {
    final seen = <String, String>{};
    for (final r in recipes) {
      final file = File(r.imageAsset);
      if (!file.existsSync()) continue; // covered by the test above
      final key = base64Encode(file.readAsBytesSync());
      expect(
        seen.containsKey(key),
        isFalse,
        reason: '${r.id} duplicates ${seen[key]}',
      );
      seen[key] = r.id;
    }
  });

  test('every bundled image belongs to a recipe', () {
    final dir = Directory('assets/images/recipes');
    final ids = {for (final r in recipes) r.id};
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith('.')) continue;
      expect(name, endsWith('.jpg'));
      expect(ids, contains(name.substring(0, name.length - 4)), reason: name);
    }
  });

  testWidgets('a recipe without a photo renders the fallback in a card', (
    tester,
  ) async {
    final r = unphotographed.first;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: GridRecipeCard(
            recipe: r,
            palette: context.moon.phase(r.phase),
            onTap: () {},
          ),
        ),
      ),
      dark: false,
      overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
    );
    await tester.pumpAndSettle();
    // The placeholder's organic shape shows where the photo would be.
    expect(find.byType(OrganicShape), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing image falls back to the placeholder', (tester) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: RecipePhoto(
            height: 170,
            radius: 24,
            palette: context.moon.phase(testCatalogue.recipes.first.phase),
            image: const AssetImage('assets/images/recipes/does-not-exist.jpg'),
          ),
        ),
      ),
      dark: false,
      overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Recipe photo placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('cards and detail at 320 pt, 1.5× text', () {
    Future<void> pump(
      WidgetTester tester,
      Widget Function(PhasePalette) build,
    ) => pumpScreen(
      tester,
      Builder(
        builder: (context) =>
            Scaffold(body: build(context.moon.phase(recipes.first.phase))),
      ),
      dark: false,
      width: 320,
      textScale: 1.5,
      height: 1200,
      overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
    );

    testWidgets('feature and grid cards', (tester) async {
      final r = recipes.first;
      await pump(
        tester,
        (palette) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FeatureRecipeCard(
                recipe: r,
                keyIngredients: 'Green lentil, broccoli, zucchini',
                palette: palette,
                onTap: () {},
              ),
              const SizedBox(height: 20),
              GridRecipeCard(recipe: r, palette: palette, onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Without the file the placeholder shows, filling the same box.
      expect(find.byType(RecipePhoto), findsNWidgets(2));
    });

    testWidgets('a real image fills the box without overflow', (tester) async {
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                RecipePhoto(
                  height: 170,
                  radius: 24,
                  palette: context.moon.phase(recipes.first.phase),
                  image: MemoryImage(_png),
                ),
              ],
            ),
          ),
        ),
        dark: false,
        width: 320,
        textScale: 1.5,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect(tester.getSize(find.byType(RecipePhoto)).height, 170);
    });

    testWidgets('detail hero', (tester) async {
      await pumpScreen(
        tester,
        RecipeDetailPage(recipeId: recipes.first.id),
        dark: false,
        width: 320,
        textScale: 1.5,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(RecipePhoto), findsOneWidget);
    });
  });
}
