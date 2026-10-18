import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_links.dart';
import '../../../core/time/today.dart';
import '../domain/entitlements.dart';

/// Every source of entitlements. v1 has only the launch promo; server
/// grants (v1.1) and purchases are added here later.
final entitlementGrantsProvider = Provider<List<EntitlementGrant>>(
  (ref) => [
    launchPromoGrant(ref.watch(appLinksProvider).launchFreeEndDate),
    // Development only: previewing Premium. Both switches must be on, and the
    // first is false in profile and release builds, so this can never grant
    // anything in a shipped app.
    if (ref.watch(debugPreviewAllowedProvider) &&
        ref.watch(debugPremiumPreviewProvider))
      const EntitlementGrant(
        tier: Tier.premium,
        origin: EntitlementOrigin.debugPreview,
      ),
  ],
);

/// Whether the debug Premium preview may exist at all: debug builds only.
final debugPreviewAllowedProvider = Provider<bool>((ref) => kDebugMode);

/// The developer's switch (Settings › debug links). Off by default and never
/// saved, so a restart is always back to the real entitlements.
final debugPremiumPreviewProvider = NotifierProvider<DebugPremiumPreview, bool>(
  DebugPremiumPreview.new,
);

class DebugPremiumPreview extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final entitlementStateProvider = Provider<EntitlementState>(
  (ref) => resolveEntitlement(
    ref.watch(entitlementGrantsProvider),
    ref.watch(todayProvider),
  ),
);

final featureGateProvider = Provider<FeatureGate>(
  (ref) => FeatureGate(ref.watch(entitlementStateProvider)),
);
