import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/eat/presentation/eat_page.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/hubs/presentation/hub_home_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/settings/presentation/delete_data_page.dart';
import 'package:moon_cycle/features/settings/presentation/personalization_page.dart';
import 'package:moon_cycle/features/settings/presentation/settings_home_page.dart';

import '../../helpers/pump_app.dart';

final homeRoot = find.byType(HomePage);

/// Eat's Foods half ("Today's food" shows only there).
final foodsRoot = find.byType(FoodsPage);
final eatRoot = find.byType(EatPage);
final recipesRoot = find.byType(RecipesPage);
final recipeDetail = find.byType(RecipeDetailPage);

/// The first recipe card on the Recipes list.
final firstRecipe = find.text('Zucchini & Feta Herb Frittata');
final settingsRoot = find.byType(SettingsHomePage);

Finder tab(String name) => find.byKey(ValueKey('tab-$name'));

Future<void> tapTab(WidgetTester tester, String name) async {
  await tester.tap(tab(name));
  await tester.pumpAndSettle();
}

/// Eat's Recipes half.
Future<void> showRecipes(WidgetTester tester) async {
  await tapTab(tester, 'eat');
  await tester.ensureVisible(find.text('Recipes'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Recipes'));
  await tester.pumpAndSettle();
}

/// Opens the first recipe on the Recipes list.
Future<void> openRecipe(WidgetTester tester) async {
  await tester.ensureVisible(firstRecipe);
  await tester.pumpAndSettle();
  await tester.tap(firstRecipe);
}

/// The Android back button.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Home', (tester) async {
    await pumpApp(tester);
    expect(homeRoot, findsOneWidget);
  });

  testWidgets('switching tabs shows each tab', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'eat');
    expect(eatRoot, findsOneWidget);
    expect(find.text('Nourish your cycle'), findsOneWidget);
    await tapTab(tester, 'move');
    expect(find.byType(HubHomePage), findsOneWidget);
    expect(find.text('Build Your Routine'), findsOneWidget);
    await tapTab(tester, 'relax');
    expect(find.text('Meditations'), findsOneWidget);
    await tapTab(tester, 'more');
    expect(settingsRoot, findsOneWidget);
    await tapTab(tester, 'home');
    expect(homeRoot, findsOneWidget);
  });

  testWidgets('each tab keeps its own stack', (tester) async {
    await pumpApp(tester);
    await showRecipes(tester);
    await openRecipe(tester);
    await tester.pumpAndSettle();
    expect(recipeDetail, findsOneWidget);

    await tapTab(tester, 'more');
    expect(settingsRoot, findsOneWidget);
    await tapTab(tester, 'eat');
    expect(find.byType(RecipeDetailPage, skipOffstage: false), findsOneWidget);
    expect(
      find.text('25 min · Serves 4').hitTestable(),
      findsOneWidget,
    ); // still open
  });

  testWidgets('tapping the active tab returns to its first screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await showRecipes(tester);
    await openRecipe(tester);
    await tester.pumpAndSettle();
    await tapTab(tester, 'eat');
    expect(eatRoot.hitTestable(), findsOneWidget); // the Eat hub
    expect(recipeDetail, findsNothing);
  });

  testWidgets('tapping the active tab on its first screen scrolls to the top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 520) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tapTab(tester, 'eat');
    final intro = find.text('Nourish your cycle');
    final top = tester.getTopLeft(intro).dy;
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(intro).dy, lessThan(top)); // scrolled

    await tapTab(tester, 'eat');
    expect(tester.getTopLeft(intro).dy, top);
  });

  testWidgets('Me sub-pages open inside Me and go back', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'more');
    await tester.ensureVisible(
      find.byKey(const ValueKey('me-personalization')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-personalization')));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalizationPage), findsOneWidget);
    await tester.tap(find.text('My Cycle'));
    await tester.pumpAndSettle();
    expect(find.text('My Cycle').hitTestable(), findsOneWidget);
    expect(settingsRoot.hitTestable(), findsNothing);
    expect(tab('more').hitTestable(), findsOneWidget); // tab bar visible
    await tester.tap(find.bySemanticsLabel('Back to Personalization'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalizationPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back to Me'));
    await tester.pumpAndSettle();
    expect(settingsRoot.hitTestable(), findsOneWidget);
  });

  testWidgets(
    'Delete my data covers the tab bar; back returns to Privacy & Data',
    (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'more');
      for (final key in ['me-privacy', 'privacy-delete-data']) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(key)),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }
      expect(find.text('Delete my data').hitTestable(), findsOneWidget);
      expect(tab('more').hitTestable(), findsNothing); // no tab bar
      await systemBack(tester);
      expect(find.byType(DeleteDataPage), findsNothing);
      expect(tab('more').hitTestable(), findsOneWidget);
    },
  );

  group('Android back', () {
    testWidgets('inside a tab: one screen back', (tester) async {
      await pumpApp(tester);
      await showRecipes(tester);
      await openRecipe(tester);
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(recipesRoot, findsOneWidget);
    });

    testWidgets('on the first screen of another tab: to Home', (tester) async {
      await pumpApp(tester);
      for (final name in ['eat', 'move', 'relax', 'more']) {
        await tapTab(tester, name);
        await systemBack(tester);
        expect(homeRoot, findsOneWidget, reason: name);
      }
    });

    testWidgets('on Home: the app may close', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester);
      await systemBack(tester);
      expect(calls, contains('SystemNavigator.pop'));
    });

    testWidgets('on another tab the app does not close', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester);
      await tapTab(tester, 'relax');
      await systemBack(tester);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });
  });
}
