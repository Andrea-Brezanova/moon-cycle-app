import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_links.dart';
import '../../../core/time/today.dart';
import '../domain/entitlements.dart';

/// Every source of entitlements. v1 has only the launch promo; server
/// grants (v1.1) and purchases are added here later.
final entitlementGrantsProvider = Provider<List<EntitlementGrant>>(
  (ref) => [launchPromoGrant(ref.watch(appLinksProvider).launchFreeEndDate)],
);

final entitlementStateProvider = Provider<EntitlementState>(
  (ref) => resolveEntitlement(
    ref.watch(entitlementGrantsProvider),
    ref.watch(todayProvider),
  ),
);

final featureGateProvider = Provider<FeatureGate>(
  (ref) => FeatureGate(ref.watch(entitlementStateProvider)),
);
