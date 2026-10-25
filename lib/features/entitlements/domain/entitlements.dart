import '../../../core/domain/local_date.dart';

/// Subscription tiers, lowest first (plan §10).
enum Tier { free, plus, premium }

/// Everything that could ever be gated. Wrapping a feature in a gate from
/// the start means adding subscriptions later adds a source and a paywall,
/// without restructuring feature code.
enum Feature {
  /// Foods and Recipes for phases other than the current one.
  browseAllPhases,
  recipeDetail,
  shoppingList,
  reminders,

  /// Build a Meal: free for everyone, in every build.
  buildMeal,

  /// Log Diary and "Log meal": the basic diary is free.
  logDiary,
}

/// Which tier each feature needs. **Which features are Plus is a product
/// decision that hasn't been made** (plan §20, docs/open-questions.md), so
/// every feature is free for now: nothing can lock by accident when the
/// launch promo ends.
// TODO(open-question): set the Plus features before subscriptions launch.
const Map<Feature, Tier> defaultFeatureTiers = {
  Feature.browseAllPhases: Tier.free,
  Feature.recipeDetail: Tier.free,
  Feature.shoppingList: Tier.free,
  Feature.reminders: Tier.free,
  // Build a Meal is free for everyone (production builds included). The gate
  // stays in place so the tier can be changed here later without touching the
  // screens.
  Feature.buildMeal: Tier.free,
  // Basic diary (meals, symptoms, history, edit, delete) is free. Advanced
  // insights, if they come, would be a separate Premium feature.
  Feature.logDiary: Tier.free,
};

/// Where a tier comes from.
enum EntitlementOrigin {
  /// Everyone gets Plus until the launch-free end date.
  launchPromo,

  /// Added with accounts (v1.1): support grants, grandfathering.
  serverGrant,

  /// Added with subscriptions.
  purchase,

  /// Debug builds only: a developer previewing Premium. Never granted in
  /// profile or release builds.
  debugPreview,
}

/// One source's grant of a tier, valid until [endsOn] (inclusive). A null
/// [endsOn] never ends.
final class EntitlementGrant {
  const EntitlementGrant({
    required this.tier,
    required this.origin,
    this.endsOn,
  });

  final Tier tier;
  final EntitlementOrigin origin;
  final LocalDate? endsOn;

  bool isValidOn(LocalDate today) => endsOn == null || !today.isAfter(endsOn!);
}

/// The user's tier today, and the grant it came from.
final class EntitlementState {
  const EntitlementState({required this.tier, this.grant});

  static const free = EntitlementState(tier: Tier.free);

  final Tier tier;

  /// Null on the free tier.
  final EntitlementGrant? grant;
}

/// Combines grants by taking the highest tier that is still valid on
/// [today]. Ties go to the grant that lasts longest.
EntitlementState resolveEntitlement(
  List<EntitlementGrant> grants,
  LocalDate today,
) {
  EntitlementGrant? best;
  for (final g in grants.where((g) => g.isValidOn(today))) {
    if (best == null ||
        g.tier.index > best.tier.index ||
        (g.tier == best.tier && _lastsLonger(g, best))) {
      best = g;
    }
  }
  return best == null
      ? EntitlementState.free
      : EntitlementState(tier: best.tier, grant: best);
}

bool _lastsLonger(EntitlementGrant a, EntitlementGrant b) =>
    b.endsOn != null && (a.endsOn == null || a.endsOn!.isAfter(b.endsOn!));

/// The launch promo: Plus for everyone until one fixed date (spec §12).
/// A null [endsOn] means the date isn't set yet; the promo then has no end.
EntitlementGrant launchPromoGrant(LocalDate? endsOn) => EntitlementGrant(
  tier: Tier.plus,
  origin: EntitlementOrigin.launchPromo,
  endsOn: endsOn,
);

/// The only place the app asks "is this allowed?". The UI never compares
/// tier names.
final class FeatureGate {
  const FeatureGate(this.state, {this.tiers = defaultFeatureTiers});

  final EntitlementState state;
  final Map<Feature, Tier> tiers;

  bool canUse(Feature feature) =>
      state.tier.index >= (tiers[feature] ?? Tier.free).index;
}
