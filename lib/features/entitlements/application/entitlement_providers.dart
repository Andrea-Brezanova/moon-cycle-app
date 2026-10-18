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
/// In profile and release builds this is false, so nothing below can grant
/// anything.
final debugPreviewAllowedProvider = Provider<bool>((ref) => kDebugMode);

/// Whether a development run starts with every feature unlocked. `main()`
/// sets it to true for a **debug build of the dev flavour** and nowhere else;
/// the default is false (tests, and anything that does not set it). There is no
/// build define or runtime setting that can turn it on, and
/// [debugPreviewAllowedProvider] keeps it inert outside debug builds anyway.
final debugUnlockAtStartProvider = Provider<bool>((ref) => false);

/// Whether a run opens with every feature unlocked: a **debug build of the dev
/// flavour** only. Profile and release builds, and the prod flavour, are never
/// unlocked, whatever else is configured.
bool developmentUnlockEnabled({
  required bool isDebugBuild,
  required bool isDevFlavour,
}) => isDebugBuild && isDevFlavour;

/// The developer's switch: all features unlocked for testing, on top of the
/// real entitlements (Settings › debug links). Starts as
/// [debugUnlockAtStartProvider]; switching it off shows the production
/// restrictions. Never saved.
final debugPremiumPreviewProvider = NotifierProvider<DebugPremiumPreview, bool>(
  DebugPremiumPreview.new,
);

class DebugPremiumPreview extends Notifier<bool> {
  @override
  bool build() => ref.read(debugUnlockAtStartProvider);

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
