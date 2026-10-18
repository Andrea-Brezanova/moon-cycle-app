import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real entitlements: the launch promo only, never Premium', () {
    final c = make();
    final state = c.read(entitlementStateProvider);
    expect(state.tier, Tier.plus);
    expect(state.grant?.origin, EntitlementOrigin.launchPromo);
    final gate = c.read(featureGateProvider);
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
    expect(c.read(featureGateProvider).canUse(Feature.buildMeal), isTrue);
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
    expect(c.read(featureGateProvider).canUse(Feature.buildMeal), isFalse);
    expect(c.read(entitlementGrantsProvider).map((g) => g.origin), [
      EntitlementOrigin.launchPromo,
    ]);
  });

  test('the Premium designation of the unbuilt features is preserved', () {
    expect(defaultFeatureTiers[Feature.buildMeal], Tier.premium);
    expect(defaultFeatureTiers[Feature.logDiary], Tier.premium);
  });

  group('development: every feature unlocked from the start', () {
    test('a dev run (UNLOCK_ALL_FEATURES) starts fully unlocked', () {
      final c = make(unlockAtStart: true);
      final gate = c.read(featureGateProvider);
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
      final gate = c.read(featureGateProvider);
      expect(gate.canUse(Feature.buildMeal), isFalse);
      expect(gate.canUse(Feature.logDiary), isFalse);
      expect(gate.canUse(Feature.shoppingList), isTrue);
    });

    test('a profile or release build never unlocks, whatever is set', () {
      final c = make(allowed: false, unlockAtStart: true);
      expect(c.read(featureGateProvider).canUse(Feature.buildMeal), isFalse);
      expect(c.read(entitlementGrantsProvider).map((g) => g.origin), [
        EntitlementOrigin.launchPromo,
      ]);
    });

    test('the production tier settings are untouched', () {
      expect(defaultFeatureTiers[Feature.buildMeal], Tier.premium);
      expect(defaultFeatureTiers[Feature.logDiary], Tier.premium);
      expect(defaultFeatureTiers[Feature.shoppingList], Tier.free);
    });

    test('only dev env files turn it on; the prod files never do', () {
      bool unlocks(String file) {
        final json = jsonDecode(
          File('env/$file').readAsStringSync(),
        ) as Map<String, Object?>;
        return json['UNLOCK_ALL_FEATURES'] == true;
      }

      expect(unlocks('dev.example.json'), isTrue);
      expect(unlocks('prod.example.json'), isFalse);
      if (File('env/prod.json').existsSync()) {
        expect(unlocks('prod.json'), isFalse);
      }
    });
  });
}
