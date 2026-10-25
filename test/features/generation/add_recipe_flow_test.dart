import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';
import 'package:moon_cycle/features/generation/presentation/add_recipe_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
import '../../helpers/my_recipes_filter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpMyRecipes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1500) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    unawaited(container.read(appRouterProvider).push(Routes.myRecipes));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String? title,
    String? ingredients,
    String? steps,
  }) async {
    final fields = find.byType(EditableText);
    if (title != null) await tester.enterText(fields.at(0), title);
    // fields: name, time, serves, about, ingredients, steps
    if (ingredients != null) await tester.enterText(fields.at(4), ingredients);
    if (steps != null) await tester.enterText(fields.at(5), steps);
    await tester.pumpAndSettle();
  }

  Future<void> saveRecipe(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Save recipe'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10)); // the toast goes away
  }

  testWidgets('write a recipe: it is saved under Added by me', (tester) async {
    await pumpMyRecipes(tester);
    expect(shownCount(tester), '0 items');
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    expect(find.byType(AddRecipePage), findsOneWidget);
    expect(find.text('Add a recipe'), findsWidgets);

    // Nothing to save yet: a gentle reason, no recipe.
    await tester.ensureVisible(find.text('Save recipe'));
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Give the recipe a name.'), findsOneWidget);

    await fill(
      tester,
      title: 'Gran’s lentil soup',
      ingredients: '150 g green lentils\nA handful of moon dust',
      steps: 'Simmer.\nServe warm.',
    );
    await saveRecipe(tester);
    expect(find.byType(MyRecipesPage), findsOneWidget);
    await expectShowCounts(tester, {'All recipes': 1, 'Added by me': 1});
    expect(shownCount(tester), '1 item');
    expect(find.text('Gran’s lentil soup'), findsOneWidget);

    final mine = await tester.runAsync(
      () => container.read(personalRecipeRepositoryProvider).allFor([
        localRecipeOwnerId,
      ]),
    );
    expect(mine!.single.isManual, isTrue);
    expect(mine.single.ownerId, localRecipeOwnerId);
    expect(mine.single.lifecycle, RecipeLifecycle.privateSaved);
    expect(mine.single.remoteId, isNull); // never sent anywhere
  });

  testWidgets('open it, edit it, then delete it', (tester) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.text('Add a recipe').last);
    await tester.pumpAndSettle();
    await fill(tester, title: 'Toast', steps: 'Toast the bread.');
    await saveRecipe(tester);

    await tester.tap(find.text('Toast'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    expect(find.textContaining('Added by you'), findsOneWidget);
    expect(find.text('Toast the bread.'), findsOneWidget);
    // Not offered to anyone else.
    expect(find.text('Suggest to Moon Cycle'), findsNothing);

    await tester.ensureVisible(find.text('Edit this recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit this recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Edit recipe'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Toast', // the field starts with what was saved
    );
    await tester.enterText(find.byType(EditableText).at(0), 'Better toast');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    expect(find.text('Better toast'), findsWidgets);

    await tester.ensureVisible(find.text('Delete this recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete this recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(find.text('Better toast'), findsNothing);
  });

  testWidgets('the trash on a list card asks first, then deletes it at once; '
      'saved built-in recipes only get Remove', (tester) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.text('Add a recipe').last);
    await tester.pumpAndSettle();
    await fill(tester, title: 'Toast', steps: 'Toast the bread.');
    await saveRecipe(tester);
    await tester.tap(find.text('Add a recipe').last);
    await tester.pumpAndSettle();
    await fill(tester, title: 'Soup', steps: 'Heat.');
    await saveRecipe(tester);
    await expectShowCounts(tester, {'Added by me': 2});

    // Keep it: nothing is deleted.
    await tester.tap(find.bySemanticsLabel('Delete Toast'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this recipe?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(shownCount(tester), '2 items');

    // Delete: gone from the list immediately; the other stays.
    await tester.tap(find.bySemanticsLabel('Delete Toast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Toast'), findsNothing);
    expect(find.text('Soup'), findsOneWidget);
    await expectShowCounts(tester, {'All recipes': 1, 'Added by me': 1});
    final left = await tester.runAsync(
      () => container.read(personalRecipeRepositoryProvider).allFor([
        localRecipeOwnerId,
      ]),
    );
    expect(left!.map((r) => r.recipe.title), ['Soup']);
  });

  testWidgets('Add a recipe has three tabs; the third saves a link, and the '
      'old separate link action is gone', (tester) async {
    await pumpMyRecipes(tester);
    expect(find.text('Add a link to a recipe'), findsNothing);
    expect(find.byKey(const ValueKey('add-recipe-plus')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    for (final t in ['Write my own', 'Paste text', 'Add a link']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.text('Add a link'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AddRecipePage),
      matching: find.byType(EditableText),
    );

    // Unsafe or empty: refused with a reason, nothing saved.
    await tester.enterText(fields.at(0), 'javascript:alert(1)');
    await tester.enterText(fields.at(1), '  ');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-recipe-link')));
    await tester.tap(find.byKey(const ValueKey('save-recipe-link')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('web address that starts with http'),
      findsOneWidget,
    );
    expect(find.text('Give it a name.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'https://www.youtube.com/watch?v=abc');
    await tester.enterText(fields.at(1), 'Lentil soup video');
    await tester.enterText(fields.at(2), 'Sam');
    await tester.enterText(fields.at(3), 'Try with lemon');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-recipe-link')));
    await tester.tap(find.byKey(const ValueKey('save-recipe-link')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10)); // the toast goes away

    expect(find.byType(MyRecipesPage), findsOneWidget);
    await expectShowCounts(tester, {'All recipes': 1, 'Links': 1});
    expect(find.text('Lentil soup video'), findsOneWidget);
    await chooseShow(tester, 'Links');
    expect(shownCount(tester), '1 item');
    final links = await tester.runAsync(
      () => container.read(collectionLinkRepositoryProvider).all(),
    );
    expect(links!.single.category, LinkCategory.recipes);
    expect(links.single.creator, 'Sam');
  });

  testWidgets('the dropdown: All recipes first, the chosen option marked, a '
      'count above the results, and it keeps working after changes', (
    tester,
  ) async {
    await pumpMyRecipes(tester);
    expect(currentShow(tester), 'All recipes');
    await tester.tap(find.text('Add a recipe').last);
    await tester.pumpAndSettle();
    await fill(tester, title: 'Toast', steps: 'Toast the bread.');
    await saveRecipe(tester);
    expect(shownCount(tester), '1 item');
    await chooseShow(tester, 'Added by me');
    expect(currentShow(tester), 'Added by me');
    // The chosen option is marked as selected in the sheet.
    await tester.tap(find.byKey(const ValueKey('my-recipes-filter')));
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Added by me, 1'))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    handle.dispose();
    await tester.tapAt(const Offset(10, 60));
    await tester.pumpAndSettle();

    // Delete it: the filter stays on Added by me and the count follows.
    await tester.tap(find.bySemanticsLabel('Delete Toast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(currentShow(tester), 'Added by me');
    expect(shownCount(tester), '0 items');
    expect(find.text('Nothing added by you yet'), findsOneWidget);
  });

  testWidgets('going back with unsaved writing asks first', (tester) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    await fill(tester, title: 'Half a recipe');
    await back(tester);
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Half a recipe'), findsOneWidget);
    await back(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(shownCount(tester), '0 items');
  });

  testWidgets('a recipe you wrote can be chosen when logging a meal', (
    tester,
  ) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    await fill(tester, title: 'Moonlight stew', steps: 'Stir.');
    await saveRecipe(tester);

    unawaited(container.read(appRouterProvider).push(Routes.logMeal()));
    await tester.pumpAndSettle();
    expect(find.byType(LogMealPage), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, 'Moonlight');
    await tester.pumpAndSettle();
    expect(find.text('Moonlight stew'), findsWidgets);
  });

  const pasted = '''
Gran’s Lentil Soup
Serves 4
Prep time: 10 minutes
Cook time: 30 minutes

Ingredients
150 g green lentils
A handful of moon dust

Method
1. Simmer the lentils.
2. Serve warm.
''';

  testWidgets('paste text: a draft to review; nothing is saved until Save', (
    tester,
  ) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste text'));
    await tester.pumpAndSettle();
    expect(find.textContaining('never sent anywhere'), findsOneWidget);
    // Nothing pasted: nothing to review.
    await tester.tap(find.text('Review recipe'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Paste your recipe here'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, pasted);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Review recipe'));
    await tester.tap(find.text('Review recipe'));
    await tester.pumpAndSettle();

    // The editor, filled in, with what was found and what wasn't.
    expect(find.byKey(const ValueKey('import-note')), findsOneWidget);
    expect(
      find.textContaining('Found: a name, 2 ingredients, 2 steps'),
      findsOneWidget,
    );
    final fields = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((e) => e.controller.text)
        .toList();
    expect(fields[0], 'Gran’s Lentil Soup');
    expect(fields[1], '40'); // prep + cook
    expect(fields[2], '4');
    expect(fields[4], '150 g green lentils\nA handful of moon dust');
    expect(fields[5], 'Simmer the lentils.\nServe warm.');
    // The line we don't recognise is named as unchecked.
    expect(find.byKey(const ValueKey('unchecked-note')), findsOneWidget);
    expect(find.text('• A handful of moon dust'), findsOneWidget);
    expect(find.text('• 150 g green lentils'), findsNothing);

    // Not saved yet.
    var mine = await tester.runAsync(
      () => container.read(personalRecipeRepositoryProvider).allFor([
        localRecipeOwnerId,
      ]),
    );
    expect(mine, isEmpty);

    // The user edits the draft, then saves explicitly.
    await tester.enterText(find.byType(EditableText).at(0), 'Gran’s soup');
    await saveRecipe(tester);
    expect(find.byType(MyRecipesPage), findsOneWidget);
    expect(find.text('Gran’s soup'), findsOneWidget);
    mine = await tester.runAsync(
      () => container.read(personalRecipeRepositoryProvider).allFor([
        localRecipeOwnerId,
      ]),
    );
    final r = mine!.single;
    expect((r.isManual, r.recipe.minutes, r.recipe.serves), (true, 40, 4));
    expect(r.recipe.ingredients.map((i) => i.label), [
      '150 g green lentils',
      'A handful of moon dust',
    ]);
    expect(r.recipe.ingredients.last.foodId, isNull); // kept as written
    expect(r.recipe.steps, ['Simmer the lentils.', 'Serve warm.']);
  });

  testWidgets('pasting over writing asks before replacing it', (tester) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    await fill(tester, title: 'My own start');
    await tester.tap(find.text('Paste text'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, pasted);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Review recipe'));
    await tester.tap(find.text('Review recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Replace what you’ve written?'), findsOneWidget);
    await tester.tap(find.text('Keep mine'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('import-note')), findsNothing);
    await tester.ensureVisible(find.text('Review recipe'));
    await tester.tap(find.text('Review recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('import-note')), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Gran’s Lentil Soup',
    );
  });

  testWidgets('typing an unrecognised ingredient names it as unchecked', (
    tester,
  ) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    await fill(tester, ingredients: '150 g green lentils\nunicorn tears');
    expect(
      find.text(
        '1 of 2 ingredients can’t be checked against your food '
        'preferences or allergens:',
      ),
      findsOneWidget,
    );
    expect(find.text('• unicorn tears'), findsOneWidget);
    await fill(tester, ingredients: '150 g green lentils');
    expect(find.byKey(const ValueKey('unchecked-note')), findsNothing);
    expect(
      find.text('Every ingredient was matched to a Moon Cycle food.'),
      findsOneWidget,
    );
  });

  testWidgets('editing a saved recipe has no paste tab', (tester) async {
    await pumpMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('add-recipe-plus')));
    await tester.pumpAndSettle();
    await fill(tester, title: 'Soup', steps: 'Heat.');
    await saveRecipe(tester);
    await tester.tap(find.text('Soup'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit this recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit this recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Edit recipe'), findsOneWidget);
    expect(find.text('Paste text'), findsNothing);
  });

  group('layout', () {
    for (final dark in [false, true]) {
      for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
        testWidgets(
          '${dark ? 'dark' : 'light'}, ${width}pt at $scale×: fits, 44 pt '
          'targets',
          (tester) async {
            final handle = tester.ensureSemantics();
            for (final page in const [AddRecipePage(), MyRecipesPage()]) {
              await pumpScreen(
                tester,
                page,
                dark: dark,
                width: width,
                textScale: scale,
                height: 3600,
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
