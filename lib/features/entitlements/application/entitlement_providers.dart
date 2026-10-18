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

/// Whether a development run starts with every feature unlocked. Set with
/// `--dart-define=UNLOCK_ALL_FEATURES=true` (it is in `env/dev.json`, and
/// must never be in `env/prod.json`); false when not set, so tests and
/// production builds start with the real restrictions.
final debugUnlockAtStartProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('UNLOCK_ALL_FEATURES'),
);

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
