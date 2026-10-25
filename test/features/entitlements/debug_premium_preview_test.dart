import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';

ProviderContainer make({bool allowed = true, bool unlockAtStart = false}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 1, 5)),
      debugPreviewAllowedProvider.overrideWithValue(allowed),
      debugUnlockAtStartProvider.overrideWithValue(unlockAtStart),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Production has no Premium-only feature (Build a Meal is free), so these tests
/// gate Build a Meal as if it were Premium to exercise the preview machinery.
const _gated = {Feature.buildMeal: Tier.premium};

FeatureGate gateOf(ProviderContainer c) =>
    FeatureGate(c.read(entitlementStateProvider), tiers: _gated);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a release build, free user: Build a Meal is allowed with no Premium '
      'switch, no debug preview and no unlock', () {
    final c = make(allowed: false); // what kDebugMode is in a shipped app
    expect(c.read(devPremiumSwitchAllowedProvider), isFalse);
    expect(c.read(debugPremiumPreviewProvider), isFalse);
    expect(c.read(featureGateProvider).canUse(Feature.buildMeal), isTrue);
    // And with no entitlement at all (promo over, no account).
    expect(
      const FeatureGate(EntitlementState.free).canUse(Feature.buildMeal),
      isTrue,
    );
  });

  test('real entitlements: the launch promo only, never Premium', () {
    final c = make();
    final state = c.read(entitlementStateProvider);
    expect(state.tier, Tier.plus);
    expect(state.grant?.origin, EntitlementOrigin.launchPromo);
    final gate = gateOf(c);
    expect(gate.canUse(Feature.buildMeal), isFalse);
    expect(gate.canUse(Feature.shoppingList), isTrue);
  });

  test('the preview is off by default', () {
    expect(make().read(debugPremiumPreviewProvider), isFalse);
  });

  test('in a debug build the switch previews Premium, then restores', () {
    final c = make();
    c.read(debugPremiumPreviewProvider.notifier).toggle();
    expect(c.read(entitlementStateProvider).tier, Tier.premium);
    expect(
      c.read(entitlementStateProvider).grant?.origin,
      EntitlementOrigin.debugPreview,
    );
    expect(gateOf(c).canUse(Feature.buildMeal), isTrue);
    // The launch promo is untouched underneath.
    expect(
      c.read(entitlementGrantsProvider).first.origin,
      EntitlementOrigin.launchPromo,
    );
    c.read(debugPremiumPreviewProvider.notifier).toggle();
    expect(c.read(entitlementStateProvider).tier, Tier.plus);
  });

  test('profile and release builds ignore the switch: no bypass', () {
    final c = make(allowed: false); // what kDebugMode is in a shipped app
    c.read(debugPremiumPreviewProvider.notifier).toggle();
    expect(c.read(debugPremiumPreviewProvider), isTrue);
    expect(c.read(entitlementStateProvider).tier, Tier.plus);
    expect(gateOf(c).canUse(Feature.buildMeal), isFalse);
    expect(c.read(entitlementGrantsProvider).map((g) => g.origin), [
      EntitlementOrigin.launchPromo,
    ]);
  });

  test('production: no feature is Premium-only; Build a Meal is free', () {
    for (final f in Feature.values) {
      expect(defaultFeatureTiers[f] ?? Tier.free, Tier.free, reason: f.name);
    }
    expect(defaultFeatureTiers[Feature.buildMeal], Tier.free);
  });

  group('development: every feature unlocked from the start', () {
    test('a dev run (UNLOCK_ALL_FEATURES) starts fully unlocked', () {
      final c = make(unlockAtStart: true);
      final gate = gateOf(c);
      for (final f in Feature.values) {
        expect(gate.canUse(f), isTrue, reason: f.name);
      }
      // The real entitlements are still the Plus launch promo underneath.
      expect(
        c.read(entitlementGrantsProvider).first.origin,
        EntitlementOrigin.launchPromo,
      );
    });

    test('the switch restores the production restrictions, no rebuild', () {
      final c = make(unlockAtStart: true);
      c.read(debugPremiumPreviewProvider.notifier).toggle(); // off
      final gate = gateOf(c);
      expect(gate.canUse(Feature.buildMeal), isFalse);
      expect(gate.canUse(Feature.logDiary), isTrue); // free in production
      expect(gate.canUse(Feature.shoppingList), isTrue);
    });

    test('a profile or release build never unlocks, whatever is set', () {
      final c = make(allowed: false, unlockAtStart: true);
      expect(gateOf(c).canUse(Feature.buildMeal), isFalse);
      expect(c.read(entitlementGrantsProvider).map((g) => g.origin), [
        EntitlementOrigin.launchPromo,
      ]);
    });

    test('the production tier settings: everything free', () {
      expect(defaultFeatureTiers[Feature.buildMeal], Tier.free);
      expect(defaultFeatureTiers[Feature.logDiary], Tier.free);
      expect(defaultFeatureTiers[Feature.shoppingList], Tier.free);
    });

    test('a run unlocks only in a debug build of the dev flavour', () {
      bool enabled(bool debug, bool dev) =>
          developmentUnlockEnabled(isDebugBuild: debug, isDevFlavour: dev);
      expect(enabled(true, true), isTrue);
      expect(enabled(true, false), isFalse); // debug build, prod flavour
      expect(enabled(false, true), isFalse); // release/profile, dev flavour
      expect(enabled(false, false), isFalse);
    });

    test('the owner’s test-phone build: dev flavour with the define only', () {
      bool allowed(Flavor f, bool define) =>
          devPremiumBuildAllowed(flavor: f, define: define);
      expect(allowed(Flavor.dev, true), isTrue);
      expect(allowed(Flavor.dev, false), isFalse); // every normal build
      expect(allowed(Flavor.prod, true), isFalse); // never production
      expect(allowed(Flavor.prod, false), isFalse);
    });

    test('without the define a release build cannot grant Premium', () {
      // The define is absent in tests, as in every normal build.
      final c = ProviderContainer(
        overrides: [
          debugPreviewAllowedProvider.overrideWithValue(false),
          debugUnlockAtStartProvider.overrideWithValue(true),
          clockProvider.overrideWithValue(() => DateTime(2026, 1, 5)),
          appConfigProvider.overrideWithValue(
            const AppConfig(flavor: Flavor.dev),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(devPremiumSwitchAllowedProvider), isFalse);
      expect(c.read(entitlementStateProvider).tier, isNot(Tier.premium));
    });

    test('nothing in configuration can turn it on', () {
      // The start value is false unless main() sets it, and no env file or
      // build define is read for it.
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(debugUnlockAtStartProvider), isFalse);
      for (final file in Directory('env').listSync().whereType<File>()) {
        expect(
          file.readAsStringSync(),
          isNot(contains('UNLOCK')),
          reason: file.path,
        );
      }
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, isNot(contains('fromEnvironment')));
    });
  });
}
