import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';

ProviderContainer make({bool allowed = true}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 1, 5)),
      debugPreviewAllowedProvider.overrideWithValue(allowed),
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
}
