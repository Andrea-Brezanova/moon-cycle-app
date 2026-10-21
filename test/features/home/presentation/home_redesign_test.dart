import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/diary/presentation/diary_page.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/learn_more_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_editorial.dart';
import 'package:moon_cycle/features/plants/application/plant_providers.dart';
import 'package:moon_cycle/features/plants/presentation/three_plants_page.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/settings/presentation/subscription_page.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

const premium = EntitlementState(tier: Tier.premium);

void main() {
  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    List<Override> more = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final container = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow), ...more],
    );
    expect(find.byType(HomePage), findsOneWidget);
    return container;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

  /// A card's title (the tab bar also says "Shop" and "Foods").
  Finder card(String title) =>
      find.descendant(of: find.byType(GoToSection), matching: find.text(title));

  Finder create() => find.text('Create my meal');

  test('Premium features are not unlocked by the promo’s Plus', () {
    const promo = EntitlementState(tier: Tier.plus);
    const gatePromo = FeatureGate(promo);
    expect(gatePromo.canUse(Feature.buildMeal), isFalse);
    expect(gatePromo.canUse(Feature.logDiary), isTrue);
    expect(gatePromo.canUse(Feature.shoppingList), isTrue);
    const gateFree = FeatureGate(EntitlementState.free);
    expect(gateFree.canUse(Feature.buildMeal), isFalse);
    expect(gateFree.canUse(Feature.shoppingList), isTrue);
    const gatePremium = FeatureGate(premium);
    expect(gatePremium.canUse(Feature.buildMeal), isTrue);
    expect(gatePremium.canUse(Feature.logDiary), isTrue);
  });

  testWidgets('hierarchy: hero, focus, 3 plants, build a meal, go to', (
    tester,
  ) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    final order = [
      find.text('Follicular'),
      find.text('YOUR FOCUS'),
      find.text('TODAY’S INSPIRATION'),
      find.text('MAKE SOMETHING GOOD'),
      find.text('GO TO'),
    ];
    for (var i = 0; i < order.length - 1; i++) {
      expect(top(tester, order[i]), lessThan(top(tester, order[i + 1])));
    }
    expect(find.text('Learn more →'), findsOneWidget);
    expect(find.textContaining('3 plants'), findsOneWidget);
  });

  testWidgets('three equal square-ish tiles with names, and the caption', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    final plants = container.read(threePlantsProvider);
    expect(plants, hasLength(3));
    final lefts = <double>[];
    for (final f in plants) {
      final t = find.text(f.displayName);
      expect(t, findsOneWidget);
      lefts.add(tester.getTopLeft(t).dx);
    }
    expect(lefts[0], lessThan(lefts[1]));
    expect(lefts[1], lessThan(lefts[2]));
    expect(
      find.text('Three plants for your follicular phase, new every day.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a plant opens its food page', (tester) async {
    final container = await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    final first = container.read(threePlantsProvider).first;
    await tester.tap(find.text(first.displayName));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
  });

  testWidgets('the arrow opens the 3 Plants a Day page', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    final arrow = find.bySemanticsLabel('Find recipes with today’s plants');
    await scrollTo(tester, arrow);
    await tester.tap(arrow);
    await tester.pumpAndSettle();
    expect(find.byType(ThreePlantsPage), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the old Home sections and instruction pills are gone', (
    tester,
  ) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    for (final gone in [
      'YOUR CHOICES',
      'Try something new',
      '3 Plants a Day',
      'Protein',
      'Base',
      'TODAY’S FOOD',
      'Browse Foods',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });

  testWidgets('Learn more opens the phase page and follows the viewed phase', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Learn more →'));
    await tester.tap(find.text('Learn more →'));
    await tester.pumpAndSettle();
    expect(find.byType(LearnMorePage), findsOneWidget);
    expect(find.text('YOUR FOCUS · LUTEAL'), findsOneWidget);
    expect(find.text('WHAT YOUR BODY MAY NEED'), findsOneWidget);
    expect(find.text('WHY THESE FOODS'), findsOneWidget);
    expect(find.text('HOW TO EAT THIS PHASE'), findsOneWidget);
    expect(find.textContaining('Appetite and energy intake'), findsOneWidget);
    expect(
      find.textContaining('These are suggestions, not rules'),
      findsOneWidget,
    );
    await tester.tap(find.text('Home').first);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  group('entitlements', () {
    testWidgets('free: Create my meal goes to the subscription page', (
      tester,
    ) async {
      await pumpHome(tester);
      await scrollTo(tester, create());
      await tester.tap(create());
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionPage), findsOneWidget);
    });

    testWidgets('Premium: Create my meal opens the builder', (tester) async {
      await pumpHome(
        tester,
        more: [entitlementStateProvider.overrideWithValue(premium)],
      );
      await scrollTo(tester, create());
      await tester.tap(create());
      await tester.pumpAndSettle();
      expect(find.byType(MealBuilderPage), findsOneWidget);
      expect(find.text('Proteins'), findsOneWidget);
    });

    testWidgets('Go to cards show no Plus lock and open shop and diary', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      await scrollTo(tester, card('Log diary'));
      expect(
        find.bySemanticsLabel('Log diary, Remember what you ate'),
        findsOneWidget,
      );
      expect(find.textContaining('Plus'), findsNothing);
      expect(find.textContaining('Coming with'), findsNothing);
      // The diary page applies its own (unchanged) rule.
      await tester.tap(card('Log diary'));
      await tester.pumpAndSettle();
      expect(find.byType(DiaryPage), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the meal builder page is locked for a free user', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const MealBuilderPage(),
        dark: false,
        overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
      );
      expect(find.text('Proteins'), findsNothing);
      expect(find.text('See Premium'), findsOneWidget);
    });
  });

  testWidgets('Explore foods, Explore recipes and Shopping list work', (
    tester,
  ) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Explore foods'));
    await tester.tap(find.text('Explore foods'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Explore recipes'));
    await tester.tap(find.text('Explore recipes'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(find.text('29 follicular recipes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await scrollTo(tester, card('Shopping list'));
    await tester.tap(card('Shopping list'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopPage), findsOneWidget);
  });

  testWidgets('browsing leaves the real cycle alone; Back to today works', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    final before = container.read(cycleStateProvider).value!;
    container.read(homePreviewProvider.notifier).preview(22);
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.luteal);
    expect(find.text('Back to today · Day 7'), findsOneWidget);
    final after = container.read(cycleStateProvider).value!;
    expect(after.lastPeriodStart, before.lastPeriodStart);
    expect(after.phase, before.phase);
    expect(after.cycleDay, before.cycleDay);
    await tester.tap(find.text('Back to today · Day 7'));
    await tester.pumpAndSettle();
    expect(container.read(viewingPhaseProvider), Phase.follicular);
  });

  group('large text keeps words whole', () {
    for (final scale in [1.5, 2.0, 3.0]) {
      testWidgets('plant names and card links stay on one line at $scale×', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          const HomePage(),
          dark: false,
          width: 390,
          textScale: scale,
          height: 6000,
          overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
        );
        Future<double> heightOf(String text) async {
          await tester.scrollUntilVisible(
            find.text(text),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          return tester.getSize(find.text(text).first).height;
        }

        // One-word names are shrunk to fit, never broken: one line tall.
        for (final f in container.read(threePlantsProvider)) {
          if (f.displayName.contains(' ')) continue;
          expect(
            await heightOf(f.displayName),
            lessThan(15 * scale * 1.3 * 1.5),
            reason: f.displayName,
          );
        }
        for (final l in ['Explore foods', 'Explore recipes']) {
          expect(await heightOf(l), lessThan(15 * scale * 1.5), reason: l);
        }
      });
    }
  });

  group('small phone, large text', () {
    for (final (name, tier) in [
      ('free', EntitlementState.free),
      ('premium', premium),
    ]) {
      testWidgets('$name: 320 pt at 1.5× has no overflow', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          const HomePage(),
          dark: false,
          width: 320,
          textScale: 1.5,
          height: 4200,
          overrides: [
            cycleStateProvider.overrideWithValue(stateOnDay(21)),
            entitlementStateProvider.overrideWithValue(tier),
          ],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('GO TO'), findsOneWidget);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}
