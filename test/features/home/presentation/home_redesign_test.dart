import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/presentation/foods_page.dart';
import 'package:moon_cycle/features/foods/presentation/learn_more_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/home/application/try_something_new.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_sections.dart';
import 'package:moon_cycle/features/recipes/presentation/recipes_page.dart';
import 'package:moon_cycle/features/settings/presentation/subscription_page.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_catalogue.dart';

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
      find.descendant(of: find.byType(ChoiceCard), matching: find.text(title));

  test('Premium features are not unlocked by the promo’s Plus', () {
    const promo = EntitlementState(tier: Tier.plus);
    const gatePromo = FeatureGate(promo);
    expect(gatePromo.canUse(Feature.buildMeal), isFalse);
    expect(gatePromo.canUse(Feature.logDiary), isFalse);
    expect(gatePromo.canUse(Feature.shoppingList), isTrue);
    const gateFree = FeatureGate(EntitlementState.free);
    expect(gateFree.canUse(Feature.buildMeal), isFalse);
    expect(gateFree.canUse(Feature.shoppingList), isTrue);
    const gatePremium = FeatureGate(premium);
    expect(gatePremium.canUse(Feature.buildMeal), isTrue);
    expect(gatePremium.canUse(Feature.logDiary), isTrue);
  });

  testWidgets('hierarchy: hero, your focus, then your choices', (tester) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    final hero = find.text('Follicular');
    final focus = find.text('YOUR FOCUS');
    final choices = find.text('YOUR CHOICES');
    expect(top(tester, hero), lessThan(top(tester, focus)));
    expect(top(tester, focus), lessThan(top(tester, choices)));
    // The compact focus, with its Learn more link.
    expect(find.text('Fresh variety'), findsOneWidget);
    expect(find.text('Learn more →'), findsOneWidget);
  });

  testWidgets('six cards, two columns, three rows, equal height', (
    tester,
  ) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    const titles = [
      'Explore foods',
      'Explore recipes',
      'Build a meal',
      'Try something new',
      'Shop',
      'Log diary',
    ];
    final tops = [for (final t in titles) top(tester, card(t))];
    final lefts = [for (final t in titles) tester.getTopLeft(card(t)).dx];
    for (var i = 0; i < 6; i += 2) {
      expect(tops[i], tops[i + 1], reason: 'row ${i ~/ 2}');
      expect(lefts[i], lessThan(lefts[i + 1]));
    }
    expect(tops[0], lessThan(tops[2]));
    expect(tops[2], lessThan(tops[4]));
    // Equal card heights within a row.
    final cards = tester.widgetList<ChoiceCard>(find.byType(ChoiceCard));
    expect(cards, hasLength(6));
    for (var i = 0; i < 6; i += 2) {
      expect(
        tester.getSize(find.byType(ChoiceCard).at(i)).height,
        tester.getSize(find.byType(ChoiceCard).at(i + 1)).height,
      );
    }
  });

  testWidgets('the old Home sections are gone', (tester) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    for (final gone in [
      'TODAY’S FOOD',
      'Foods for this phase',
      '0 to buy',
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
    testWidgets('free: Build a meal and Log diary are locked and go to the '
        'subscription page', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      await scrollTo(tester, card('Log diary'));
      expect(
        find.bySemanticsLabel(RegExp('^Build a meal, Premium, locked')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Log diary, coming soon')),
        findsOneWidget,
      );
      // Explore, Try and Shop are not locked.
      expect(find.bySemanticsLabel(RegExp('^Shop, Premium')), findsNothing);
      await tester.tap(card('Build a meal'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionPage), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Premium: Build a meal opens the builder, no lock', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHome(
        tester,
        more: [entitlementStateProvider.overrideWithValue(premium)],
      );
      await scrollTo(tester, card('Log diary'));
      expect(
        find.bySemanticsLabel(RegExp('Build a meal.*locked')),
        findsNothing,
      );
      await tester.tap(card('Build a meal'));
      await tester.pumpAndSettle();
      expect(find.byType(MealBuilderPage), findsOneWidget);
      expect(find.text('Choose a protein'), findsOneWidget);
      expect(find.text('Choose a base'), findsOneWidget);
      expect(find.text('Add 2–3 plants'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Log diary is Coming soon and does nothing, for every tier', (
      tester,
    ) async {
      for (final tier in [EntitlementState.free, premium]) {
        await pumpHome(
          tester,
          more: [entitlementStateProvider.overrideWithValue(tier)],
        );
        await scrollTo(tester, card('Log diary'));
        expect(find.text('Coming soon'), findsOneWidget);
        await tester.tap(card('Log diary'));
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(SubscriptionPage), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
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
      expect(find.text('Choose a protein'), findsNothing);
      expect(find.text('See Premium'), findsOneWidget);
    });
  });

  testWidgets('Explore foods, Explore recipes and Shop use the real tabs', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    await scrollTo(tester, card('Explore foods'));
    final filter = container.read(foodFilterProvider);
    final count = testCatalogue
        .foodsFor(Phase.follicular)
        .where(filter.allowsFood)
        .length;
    expect(find.text('$count foods for this phase'), findsOneWidget);
    await tester.tap(card('Explore foods'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodsPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await scrollTo(tester, card('Explore recipes'));
    await tester.tap(card('Explore recipes'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(find.text('29 follicular recipes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await scrollTo(tester, card('Shop'));
    await tester.tap(card('Shop'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopPage), findsOneWidget);
  });

  testWidgets('Try something new: Today’s food and two more, each with a '
      'recipe that uses it', (tester) async {
    final container = await pumpHome(tester);
    await scrollTo(tester, card('Try something new'));
    final pages = container.read(tryNewPagesProvider);
    await tester.tap(card('Try something new'));
    await tester.pumpAndSettle();
    final first = pages.first;
    expect(first, hasLength(3));
    expect(first.first.isTodaysFood, isTrue);
    for (final s in first) {
      expect(s.recipe.keyFoodIds, contains(s.food.id));
      expect(s.recipe.phase, Phase.follicular);
      expect(find.text(s.recipe.title), findsWidgets);
    }
    // The two extra foods are different foods, ideally different categories.
    expect(first.map((s) => s.food.id).toSet(), hasLength(3));
    expect(first[1].food.categoryId, isNot(first[2].food.categoryId));

    final firstTitles = [for (final s in first) s.recipe.title];
    await tester.tap(find.text('Show me more'));
    await tester.pumpAndSettle();
    final second = pages[1 % pages.length];
    expect(second.first.isTodaysFood, isTrue);
    expect([for (final s in second) s.recipe.title], isNot(firstTitles));
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
        expect(card('Try something new'), findsOneWidget);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}
