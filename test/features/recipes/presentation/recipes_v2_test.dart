import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/widgets/moon_icon.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/generation/data/saved_recipe_repository.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/application/recipe_filter.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/my_recipes_filter.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

const frittata = 'Zucchini & Feta Herb Frittata';

void main() {
  Future<(ProviderContainer, SavedRecipeRepository)> pumpRecipes(
    WidgetTester tester,
  ) async {
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
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    return (container, container.read(savedRecipeRepositoryProvider));
  }

  testWidgets('the heart saves a recipe to My recipes and removes it again', (
    tester,
  ) async {
    final (_, repo) = await pumpRecipes(tester);
    await tester.tap(find.bySemanticsLabel('Save $frittata to My recipes'));
    await tester.pumpAndSettle();
    var saved = await tester.runAsync(repo.all);
    expect(saved!.map((r) => r.title), [frittata]);
    expect(saved.single.providerId, 'moon-cycle');
    expect(
      find.bySemanticsLabel('Remove $frittata from My recipes'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Remove $frittata from My recipes'));
    await tester.pumpAndSettle();
    saved = await tester.runAsync(repo.all);
    expect(saved, isEmpty);
  });

  testWidgets('a My recipes link beside the count opens My recipes', (
    tester,
  ) async {
    await pumpRecipes(tester);
    expect(find.byKey(const ValueKey('my-recipes-link')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my-recipes-link')));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget);
  });

  testWidgets('a saved heart is filled and an unsaved one is an outline', (
    tester,
  ) async {
    await pumpRecipes(tester);
    bool filled(String label) => tester
        .widget<MoonIcon>(
          find.descendant(
            of: find.bySemanticsLabel(label),
            matching: find.byType(MoonIcon),
          ),
        )
        .filled;
    expect(filled('Save $frittata to My recipes'), isFalse);
    await tester.tap(find.bySemanticsLabel('Save $frittata to My recipes'));
    await tester.pumpAndSettle();
    expect(filled('Remove $frittata from My recipes'), isTrue);
  });

  testWidgets('entering Recipes from Eat is plain browsing, not an earlier '
      'search; the search survives a trip to a recipe and back', (
    tester,
  ) async {
    final (c, _) = await pumpRecipes(tester);
    c.read(recipeFilterProvider.notifier).cookWith('chicken');
    await tester.pumpAndSettle();
    expect(find.text('3 recipes with chicken'), findsOneWidget);

    // Into a recipe and back: the context is kept.
    await tester.tap(find.text('Lemon Chicken & Green Bean Tray Bake'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(find.text('3 recipes with chicken'), findsOneWidget);

    // Leave Recipes and enter it again from Eat, twice: normal browsing.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
      await tester.pumpAndSettle();
      expect(find.byType(RecipesPage), findsNothing);
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();
      expect(find.byType(RecipesPage), findsOneWidget);
      expect(c.read(recipeFilterProvider).foodId, isNull);
      expect(find.textContaining('recipes with'), findsNothing);
      c.read(recipeFilterProvider.notifier).cookWith('chicken');
      await tester.pumpAndSettle();
    }
  });

  testWidgets('My recipes: filters with counts, hearts remove, empty states', (
    tester,
  ) async {
    await pumpRecipes(tester);
    // Nothing saved yet: the button says so and the page explains.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('my-recipes-button')),
      400,
      maxScrolls: 100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-recipes-button')));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(find.text('My recipes'), findsWidgets);
    expect(currentShow(tester), 'All recipes');
    await expectShowCounts(tester, {
      'All recipes': 0,
      'Saved / Favorites': 0,
      'Added by me': 0,
      'Links': 0,
    });
    expect(find.text('No recipes yet'), findsOneWidget);

    // Back to Recipes, save one, and open My recipes again.
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 6000));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Save $frittata to My recipes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('my-recipes-button')),
      400,
      maxScrolls: 100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('My recipes (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my-recipes-button')));
    await tester.pumpAndSettle();
    await expectShowCounts(tester, {'All recipes': 1, 'Saved / Favorites': 1});
    expect(shownCount(tester), '1 item');
    expect(find.text(frittata), findsOneWidget);

    await chooseShow(tester, 'Added by me');
    expect(currentShow(tester), 'Added by me');
    expect(shownCount(tester), '0 items');
    expect(find.text('Nothing added by you yet'), findsOneWidget);
    expect(find.text(frittata), findsNothing);
    await chooseShow(tester, 'Saved / Favorites');
    expect(find.text(frittata), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Remove $frittata from My recipes'));
    await tester.pumpAndSettle();
    expect(find.text('No saved recipes yet'), findsOneWidget);
  });

  testWidgets('Cook with opens the ingredient sheet; still offered under All '
      'phases', (tester) async {
    await pumpRecipes(tester);
    await tester.tap(find.bySemanticsLabel('Cook with, choose an ingredient'));
    await tester.pumpAndSettle();
    expect(find.text('Foods for your follicular phase'), findsOneWidget);
    await tester.tapAt(const Offset(10, 60)); // the scrim
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('phase-pill')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All phases'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Cook with, choose an ingredient'),
      findsOneWidget,
    );
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: Recipes and My '
          'recipes fit and keep 44 pt targets',
          (tester) async {
            final handle = tester.ensureSemantics();
            for (final page in const [RecipesPage(), MyRecipesPage()]) {
              await pumpScreen(
                tester,
                page,
                dark: dark,
                width: width,
                textScale: scale,
                height: 2400,
                overrides: [
                  cycleStateProvider.overrideWithValue(stateOnDay(7)),
                ],
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
            }
            handle.dispose();
          },
        );
      }
    }
  });
}
