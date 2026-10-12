import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';

import '../../helpers/pump_app.dart';

/// Text that only appears on a tab's first screen.
Finder rootOf(int milestone) =>
    find.text('Placeholder. The real screen arrives in Milestone $milestone.');
final homeRoot = find.byType(HomePage);

/// The Foods H1 (the tab bar has a "Foods" label too).
final foodsRoot = find.descendant(
  of: find.byType(FoodsPage),
  matching: find.text('Foods'),
);
final recipesRoot = find.byType(RecipesPage);
final recipeDetail = find.byType(RecipeDetailPage);

/// The first recipe card on the Recipes list.
final firstRecipe = find.text('Zesty Lentil & Broccoli Bowl');
final settingsRoot = rootOf(13);

/// Text that only appears on a pushed placeholder page.
Finder subPage(int milestone) => find.text(
  'Placeholder page. The real page arrives in Milestone $milestone.',
);

Finder tab(String name) => find.byKey(ValueKey('tab-$name'));

Future<void> tapTab(WidgetTester tester, String name) async {
  await tester.tap(tab(name));
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
    await tapTab(tester, 'foods');
    expect(foodsRoot, findsOneWidget);
    await tapTab(tester, 'shop');
    expect(rootOf(12), findsOneWidget);
    await tapTab(tester, 'settings');
    expect(settingsRoot, findsOneWidget);
    await tapTab(tester, 'home');
    expect(homeRoot, findsOneWidget);
  });

  testWidgets('each tab keeps its own stack', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'recipes');
    await openRecipe(tester);
    await tester.pumpAndSettle();
    expect(recipeDetail, findsOneWidget);

    await tapTab(tester, 'foods');
    expect(foodsRoot, findsOneWidget);
    await tapTab(tester, 'recipes');
    expect(find.byType(RecipeDetailPage, skipOffstage: false), findsOneWidget);
    expect(
      find.text('25 min · Serves 2').hitTestable(),
      findsOneWidget,
    ); // still open
    expect(recipesRoot.hitTestable(), findsNothing);
  });

  testWidgets('tapping the active tab returns to its first screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'recipes');
    await openRecipe(tester);
    await tester.pumpAndSettle();
    await tapTab(tester, 'recipes');
    expect(recipesRoot.hitTestable(), findsOneWidget);
    expect(recipeDetail, findsNothing);
  });

  testWidgets('tapping the active tab on its first screen scrolls to the top', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'foods');
    final top = tester.getTopLeft(foodsRoot).dy;
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(foodsRoot.hitTestable(), findsNothing); // scrolled away

    await tapTab(tester, 'foods');
    expect(tester.getTopLeft(foodsRoot).dy, top);
  });

  testWidgets('Settings sub-pages open inside Settings and go back', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'settings');
    await tester.tap(find.text('My Cycle'));
    await tester.pumpAndSettle();
    expect(find.text('My Cycle').hitTestable(), findsOneWidget);
    expect(settingsRoot.hitTestable(), findsNothing);
    expect(tab('settings').hitTestable(), findsOneWidget); // tab bar visible
    await tester.tap(find.bySemanticsLabel('Back to Settings'));
    await tester.pumpAndSettle();
    expect(settingsRoot.hitTestable(), findsOneWidget);
  });

  testWidgets('Delete my data covers the tab bar; back returns to Settings', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'settings');
    await tester.ensureVisible(find.text('Delete my data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete my data').hitTestable(), findsOneWidget);
    expect(tab('settings').hitTestable(), findsNothing); // no tab bar
    await systemBack(tester);
    expect(subPage(13), findsNothing);
    expect(tab('settings').hitTestable(), findsOneWidget);
  });

  group('Android back', () {
    testWidgets('inside a tab: one screen back', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'recipes');
      await openRecipe(tester);
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(recipesRoot, findsOneWidget);
    });

    testWidgets('on the first screen of another tab: to Home', (tester) async {
      await pumpApp(tester);
      for (final name in ['foods', 'recipes', 'shop', 'settings']) {
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
      await tapTab(tester, 'shop');
      await systemBack(tester);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });
  });
}
