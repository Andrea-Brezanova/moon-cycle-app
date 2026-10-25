import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/diary/presentation/diary_hub_page.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';
import 'package:moon_cycle/features/foods/presentation/learn_more_page.dart';
import 'package:moon_cycle/features/foods/presentation/meal_builder_page.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/plants/presentation/three_plants_page.dart';
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

  testWidgets('hierarchy: hero, focus, 3 a day, quick access', (tester) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    final order = [
      find.text('Follicular'),
      find.text('TODAY’S FOCUS'),
      find.text('TODAY’S PICKS'),
      find.text('3 plants'),
      find.text('3 ways to move'),
      find.text('3 minutes of calm'),
      find.text('QUICK ACCESS'),
    ];
    for (var i = 0; i < order.length - 1; i++) {
      expect(top(tester, order[i]), lessThan(top(tester, order[i + 1])));
    }
    expect(find.text('Learn more about your phase\u00A0→'), findsOneWidget);
    expect(find.text('My Diary'), findsOneWidget);
    expect(find.text('Shopping List'), findsOneWidget);
  });

  testWidgets('the 3 a day cards carry the agreed copy, nothing to complete', (
    tester,
  ) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(390, 2600) * 3;
    await tester.pumpAndSettle();
    for (final t in [
      'Three plants chosen for your phase today.',
      'Three movement ideas. Pick what feels right.',
      'A short breathing or mindfulness pause.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    for (final gone in ['Learn more about your cycle', 'Streak']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });

  testWidgets('Today’s focus shows the short approved description in full, the '
      'same every day of the phase', (tester) async {
    final c = await pumpHome(tester);
    final focus = testCatalogue.phase(Phase.follicular).homeFocus;
    final paragraphs = focus.split('\n\n');
    expect(paragraphs, hasLength(1));
    expect(c.read(viewingPhaseProvider), Phase.follicular);
    // The headline stays; only the body changed.
    expect(find.text('Fresh, curious & energising'), findsOneWidget);
    for (final p in paragraphs) {
      await scrollTo(tester, find.text(p));
      expect(find.text(p), findsOneWidget);
    }
    expect(find.text('Learn more about your phase\u00A0→'), findsOneWidget);
  });

  testWidgets('Learn more keeps its sections and adds the longer approved '
      'explanation once', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Learn more about your phase\u00A0→'));
    await tester.tap(find.text('Learn more about your phase\u00A0→'));
    await tester.pumpAndSettle();
    expect(find.byType(LearnMorePage), findsOneWidget);
    expect(find.text('ABOUT THIS PHASE'), findsOneWidget);
    final longer = testCatalogue.phase(Phase.follicular).learnMore;
    for (final p in longer.split('\n\n')) {
      await scrollTo(tester, find.text(p));
      expect(find.text(p), findsOneWidget);
    }
    // The existing content is still there.
    for (final t in ['WHAT YOUR BODY MAY NEED', 'WHY THESE FOODS']) {
      await scrollTo(tester, find.text(t));
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  for (final (width, scale) in [(320.0, 1.0), (320.0, 2.0), (390.0, 1.5)]) {
    for (final phase in Phase.values) {
      testWidgets('Today’s focus, ${phase.name}: the whole description fits '
          'at ${width}pt, $scale× text', (tester) async {
        tester.view.physicalSize = Size(width, 900) * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = testDatabase();
        await seedCycle(tester, db, start: sampleStart);
        final c = await pumpApp(
          tester,
          database: db,
          overrides: [clockProvider.overrideWithValue(designNow)],
        );
        c.read(viewingPhaseProvider.notifier).choose(phase);
        await tester.pumpAndSettle();
        for (final p in testCatalogue.phase(phase).homeFocus.split('\n\n')) {
          await scrollTo(tester, find.text(p));
          expect(find.text(p), findsOneWidget, reason: '${phase.name}: $p');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the EAT card opens the 3 Plants a Day page', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('3 plants'));
    await tester.tap(find.text('3 plants'));
    await tester.pumpAndSettle();
    expect(find.byType(ThreePlantsPage), findsOneWidget);
  });

  testWidgets('MOVE and RELAX open their tabs', (tester) async {
    await pumpHome(tester);
    for (final title in ['3 ways to move', '3 minutes of calm']) {
      await scrollTo(tester, find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsNothing, reason: title);
      await tester.tap(find.byKey(const ValueKey('tab-home')));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    }
  });

  testWidgets('Learn more opens the phase page and follows the viewed phase', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    container.read(viewingPhaseProvider.notifier).choose(Phase.luteal);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Learn more about your phase\u00A0→'));
    await tester.tap(find.text('Learn more about your phase\u00A0→'));
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

  group('quick access', () {
    testWidgets('My Diary and Shopping List open, with no Plus lock', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      await scrollTo(tester, find.text('My Diary'));
      expect(find.textContaining('Plus'), findsNothing);
      await tester.tap(find.text('My Diary'));
      await tester.pumpAndSettle();
      // Home opens the My Diary hub; the entries are one card further in.
      expect(find.byType(DiaryHubPage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab-home')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Shopping List'));
      await tester.tap(find.text('Shopping List'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopPage), findsOneWidget);
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

  group('large text and small phones', () {
    for (final (width, scale) in [
      (390.0, 1.5),
      (390.0, 2.0),
      (390.0, 3.0),
      (320.0, 1.5),
    ]) {
      testWidgets(
        '${width}pt at $scale×: no overflow, targets are big enough',
        (tester) async {
          final handle = tester.ensureSemantics();
          await pumpScreen(
            tester,
            const HomePage(),
            dark: false,
            width: width,
            textScale: scale,
            height: 12000,
            overrides: [cycleStateProvider.overrideWithValue(stateOnDay(21))],
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('QUICK ACCESS'), findsOneWidget);
          if (scale == 1.5) {
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
  });
}
