import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/recipes/presentation/recipe_detail_page.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Scrolls Home's own list (not the horizontal recipe row) until [finder]
/// is on screen.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, [
  double step = 200,
]) async {
  await tester.scrollUntilVisible(
    finder,
    step,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    LocalDate? start,
    Future<void> Function(PreferencesRepository prefs)? prefs,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(
      tester,
      db,
      start: start ?? sampleStart,
      more: prefs == null ? null : () => prefs(PreferencesRepository(db)),
    );
    await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    expect(find.byType(HomePage), findsOneWidget);
  }

  testWidgets('the hero shows today: day 7, follicular', (tester) async {
    await pumpHome(tester);
    expect(find.text('Sat 4 Oct'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Inner spring'), findsOneWidget);
    expect(find.text('Follicular'), findsOneWidget);
    // What is happening in the cycle, not food guidance.
    expect(
      find.text(
        'Follicles develop in the ovaries and oestrogen rises as the lining '
        'rebuilds.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Day 2 of 6 in phase · Day 7 of 28 in cycle\nOvulatory in 5 days',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Cycle day 7 of 28, follicular phase, day 2 of 6'),
      findsOneWidget,
    );
  });

  testWidgets('focus, six foods and the phase’s recipes', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Fresh, light and quick'), 200);
    expect(find.text('Fresh, light and quick'), findsOneWidget);
    // Three general principles, no individual foods.
    for (final line in [
      'Balanced, nutrient-dense foods',
      'Lighter, fresh, quick meals',
      'Fresh produce, simple bowls, sautés and salads',
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    await scrollTo(tester, find.text('Foods for this phase'), 200);
    for (final food in [
      'Farro',
      'Arugula',
      'Avocado',
      'Black-eyed pea',
      'Brazil nut',
      'Chicken',
    ]) {
      expect(find.text(food), findsOneWidget, reason: food);
    }
    await scrollTo(tester, find.text('Zucchini & Feta Herb Frittata'), 200);
    expect(find.text('Zucchini & Feta Herb Frittata'), findsOneWidget);
    await scrollTo(tester, find.text('Your shopping list'), 200);
    expect(find.text('0 to buy'), findsOneWidget);
  });

  testWidgets('preferences shape the foods and recipes', (tester) async {
    await pumpHome(
      tester,
      prefs: (prefs) async {
        await prefs.saveDiet(Diet.vegetarian);
        await prefs.avoidAllergen('gluten');
      },
    );
    await scrollTo(tester, find.text('Foods for this phase'), 200);
    // Farro and oat bran may carry gluten, so Grains gives way; vegetarians
    // get eggs in place of chicken.
    expect(find.text('Farro'), findsNothing);
    expect(find.text('Chicken'), findsNothing);
    expect(find.text('Eggs'), findsOneWidget);
    await scrollTo(tester, find.text('Zucchini & Feta Herb Frittata'), 200);
    expect(find.text('Lemon Chicken & Green Bean Tray Bake'), findsNothing);
    expect(find.text('Zucchini & Feta Herb Frittata'), findsOneWidget);
  });

  testWidgets('no recipe fits: the empty line and the way out', (tester) async {
    await pumpHome(
      tester,
      prefs: (prefs) async {
        await prefs.avoidAllergen('gluten');
        await prefs.avoidAllergen('dairy');
        await prefs.avoidAllergen('fish');
        await prefs.avoidFood('chicken');
      },
    );
    await scrollTo(tester, find.text('Review food preferences'), 200);
    expect(
      find.text('No recipes for this phase fit your food preferences.'),
      findsOneWidget,
    );
  });

  testWidgets('dragging the orbit previews a day; back to today', (
    tester,
  ) async {
    await pumpHome(tester);
    final orbit = find.bySemanticsLabel(
      'Cycle day 7 of 28, follicular phase, day 2 of 6',
    );
    final centre = tester.getCenter(orbit);
    // From the bottom of the ring (half a turn: day 14 or 15 of 28) a
    // little further round.
    final ring = tester.getSize(orbit).width * 136 / 300;
    await tester.dragFrom(centre + Offset(0, ring), const Offset(-2, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Previewing day 1'), findsOneWidget);
    expect(find.text('Ovulatory'), findsOneWidget);
    // Scroll from below the moon: a drag on the ring would preview instead.
    await tester.drag(find.text('Ovulatory'), const Offset(0, -300));
    await tester.pumpAndSettle();
    // The content below follows the phase being browsed.
    expect(find.text('Your focus'.toUpperCase()), findsOneWidget);
    expect(find.text('Fresh, hydrating, crisp and colourful'), findsOneWidget);

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      4000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to today · Day 7'));
    await tester.pumpAndSettle();
    expect(find.text('Follicular'), findsOneWidget);
    await scrollTo(tester, find.text('Fresh, light and quick'));
    expect(find.text('Fresh, light and quick'), findsOneWidget);
  });

  testWidgets('screen readers adjust the preview', (tester) async {
    await pumpHome(tester);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Cycle day 7 of 28, follicular phase, day 2 of 6'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(find.text('Previewing day 8 · in 1 day'), findsOneWidget);
  });

  testWidgets('late: the card, then logging a period restarts the cycle', (
    tester,
  ) async {
    // 31 days ago: day 32 of 28, four days late.
    await pumpHome(tester, start: LocalDate(2025, 9, 3));
    expect(find.text('32'), findsOneWidget);
    expect(find.text('Luteal'), findsOneWidget);
    expect(find.text('Period 4 days late · Day 32 in cycle'), findsOneWidget);
    expect(find.text('Has your period started?'), findsOneWidget);

    await scrollTo(tester, find.text('Log my period'));
    await tester.tap(find.text('Log my period'));
    await tester.pumpAndSettle();
    expect(find.text('When did it start?'), findsOneWidget);
    expect(find.text('Day 1 · Saturday 4 October'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      4000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Menstrual'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Has your period started?'), findsNothing);
  });

  testWidgets('one or two days late: no card yet', (tester) async {
    await pumpHome(tester, start: LocalDate(2025, 9, 5)); // day 30
    expect(find.text('Period 2 days late · Day 30 in cycle'), findsOneWidget);
    expect(find.text('Has your period started?'), findsNothing);
  });

  testWidgets('a recipe opens its detail in Recipes; the block opens Shop', (
    tester,
  ) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Zucchini & Feta Herb Frittata'));
    await tester.tap(find.text('Zucchini & Feta Herb Frittata'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Your shopping list'), 200);
    await tester.tap(find.text('Your shopping list'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopPage), findsOneWidget);
  });
}
