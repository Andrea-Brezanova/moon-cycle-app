import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/diary/presentation/log_meal_page.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';
import 'package:moon_cycle/features/generation/presentation/add_recipe_page.dart';
import 'package:moon_cycle/features/generation/presentation/my_recipes_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';

import '../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../helpers/golden_screen.dart';
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
    await tester.ensureVisible(find.text('Save recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10)); // the toast goes away
  }

  testWidgets('write a recipe: it is saved under Added by me', (tester) async {
    await pumpMyRecipes(tester);
    expect(find.text('All 0'), findsOneWidget);
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
    expect(find.text('Added by me 1'), findsOneWidget);
    expect(find.text('All 1'), findsOneWidget);
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
    expect(find.text('Added by me 0'), findsOneWidget);
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
