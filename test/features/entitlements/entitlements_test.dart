import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/entitlements/domain/entitlements.dart';

void main() {
  final today = LocalDate(2026, 10, 12);

  group('resolveEntitlement', () {
    test('no grants: free', () {
      expect(resolveEntitlement(const [], today).tier, Tier.free);
    });

    test('the launch promo gives Plus until its end date, inclusive', () {
      final promo = launchPromoGrant(today);
      expect(resolveEntitlement([promo], today).tier, Tier.plus);
      expect(resolveEntitlement([promo], today.addDays(1)).tier, Tier.free);
    });

    test('a promo without an end date never ends', () {
      final state = resolveEntitlement([launchPromoGrant(null)], today);
      expect(state.tier, Tier.plus);
      expect(state.grant?.origin, EntitlementOrigin.launchPromo);
    });

    test('the highest valid tier wins', () {
      final state = resolveEntitlement([
        launchPromoGrant(null),
        EntitlementGrant(
          tier: Tier.premium,
          origin: EntitlementOrigin.purchase,
          endsOn: today.addDays(30),
        ),
        EntitlementGrant(
          tier: Tier.premium,
          origin: EntitlementOrigin.serverGrant,
          endsOn: today.addDays(-1), // expired
        ),
      ], today);
      expect(state.tier, Tier.premium);
      expect(state.grant?.origin, EntitlementOrigin.purchase);
    });

    test('a tie goes to the grant that lasts longest', () {
      final state = resolveEntitlement([
        EntitlementGrant(
          tier: Tier.plus,
          origin: EntitlementOrigin.serverGrant,
          endsOn: today.addDays(10),
        ),
        launchPromoGrant(today.addDays(90)),
      ], today);
      expect(state.grant?.origin, EntitlementOrigin.launchPromo);
    });
  });

  group('FeatureGate', () {
    test('every feature is free in production, Build a Meal included', () {
      const gate = FeatureGate(EntitlementState.free);
      for (final f in Feature.values) {
        expect(gate.canUse(f), isTrue, reason: f.name);
      }
    });

    test('Plus (the launch promo’s tier) does not unlock Premium features', () {
      // The gate itself still works: a feature set to Premium stays locked.
      const tiers = {Feature.buildMeal: Tier.premium};
      const plus = FeatureGate(EntitlementState(tier: Tier.plus), tiers: tiers);
      expect(plus.canUse(Feature.buildMeal), isFalse);
      expect(plus.canUse(Feature.logDiary), isTrue); // the diary is free
      expect(plus.canUse(Feature.shoppingList), isTrue);
      const premium = FeatureGate(
        EntitlementState(tier: Tier.premium),
        tiers: tiers,
      );
      expect(premium.canUse(Feature.buildMeal), isTrue);
      expect(premium.canUse(Feature.logDiary), isTrue);
    });

    test('a Plus feature needs Plus or higher', () {
      const tiers = {Feature.recipeDetail: Tier.plus};
      expect(
        const FeatureGate(
          EntitlementState.free,
          tiers: tiers,
        ).canUse(Feature.recipeDetail),
        isFalse,
      );
      for (final tier in [Tier.plus, Tier.premium]) {
        expect(
          FeatureGate(
            EntitlementState(tier: tier),
            tiers: tiers,
          ).canUse(Feature.recipeDetail),
          isTrue,
        );
      }
    });

    test('during the launch promo every feature is open', () {
      final gate = FeatureGate(
        resolveEntitlement([launchPromoGrant(null)], today),
        tiers: {for (final f in Feature.values) f: Tier.plus},
      );
      expect(Feature.values.every(gate.canUse), isTrue);
    });
  });
}
