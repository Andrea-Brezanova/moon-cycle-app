import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../entitlements/application/entitlement_providers.dart';
import '../data/providers/provider_http.dart';
import '../data/providers/themealdb_client.dart';
import '../data/recipe_sources.dart';
import '../data/usage_ledger.dart';
import '../domain/match_config.dart';
import '../domain/provider_policy.dart';
import '../domain/recipe_discovery.dart';
import '../domain/recipe_matcher.dart';

/// The matching thresholds. One place to change them (and to override in
/// tests).
final matchConfigProvider = Provider<MatchConfig>(
  (ref) => MatchConfig.defaults,
);

/// Whether development-only providers (free test keys) may be used: a debug
/// build of the dev flavour, the same gate as the other development tools.
/// False in release and profile builds and in the prod flavour.
final devExternalAllowedProvider = Provider<bool>(
  (ref) =>
      ref.watch(debugPreviewAllowedProvider) &&
      ref.watch(debugUnlockAtStartProvider),
);

/// Each external provider's policy: enabled or not, quota, budget, timeouts.
/// Turn a provider on or off here (or override in tests); nothing else changes.
///
/// - TheMealDB: on only where [devExternalAllowedProvider] is true.
/// - Provider B (not chosen yet): not listed, so it cannot be called.
final providerPoliciesProvider = Provider<Map<String, ProviderPolicy>>((ref) {
  final dev = ref.watch(devExternalAllowedProvider);
  return {
    TheMealDbClient.id: TheMealDbClient.policyDefaults.copyWith(enabled: dev),
  };
});

/// The HTTP transport adapters use (replaced by fakes in tests).
final providerHttpGetProvider = Provider<HttpGet>((ref) => ioHttpGet);

/// The adapters of every provider that is configured **and** enabled.
final externalClientsProvider = Provider<List<ExternalRecipeClient>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final policies = ref.watch(providerPoliciesProvider);
  final ledger = ref.watch(usageLedgerProvider);
  final get = ref.watch(providerHttpGetProvider);
  final clients = <ExternalRecipeClient>[];
  final mealDb = policies[TheMealDbClient.id];
  if (mealDb != null && mealDb.enabled) {
    clients.add(
      TheMealDbClient(
        http: ProviderHttp(policy: mealDb, ledger: ledger, get: get),
        catalogue: catalogue,
        policy: mealDb,
      ),
    );
  }
  return clients;
});

/// External recipes found in this session, by id, so opening one needs no
/// second request. Memory only: nothing is stored.
final externalRecipeCacheProvider = Provider<Map<String, ExternalRecipe>>(
  (ref) => {},
);

/// Internal library first, then every enabled external provider (asked at the
/// same time; one failing never stops the rest).
final recipeDiscoveryProvider = Provider<RecipeDiscovery>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final config = ref.watch(matchConfigProvider);
  final policies = ref.watch(providerPoliciesProvider);
  final cache = ref.watch(externalRecipeCacheProvider);
  return RecipeDiscovery([
    InternalRecipeSource(catalogue, config: config),
    for (final client in ref.watch(externalClientsProvider))
      ExternalRecipeSource(
        client,
        catalogue,
        config: config,
        policy: policies[client.providerId]!,
        onFound: (e) => cache[e.recipe.id] = e,
      ),
  ]);
});

/// What discovery finds for a meal (keyed by [MealChoice.key]), for the user's
/// diet and avoidances and the user's current phase.
final mealDiscoveryProvider = FutureProvider.autoDispose
    .family<DiscoveryResult, String>(
      (ref, key) => ref
          .watch(recipeDiscoveryProvider)
          .discover(
            MealChoice.fromKey(key),
            ref.watch(foodFilterProvider),
            currentPhase: ref.watch(actualPhaseProvider),
          ),
    );

/// One external recipe by its app id (`x-themealdb-52772`): from this
/// session's results, or asked of its provider again (for a saved reference).
/// Null when the provider is off or no longer has it.
final externalRecipeProvider = FutureProvider.autoDispose
    .family<ExternalRecipe?, String>((ref, id) async {
      final cached = ref.read(externalRecipeCacheProvider)[id];
      if (cached != null) return cached;
      final match = RegExp(r'^x-([a-z0-9]+)-(.+)$').firstMatch(id);
      if (match == null) return null;
      for (final client in ref.read(externalClientsProvider)) {
        if (client.providerId != match.group(1)) continue;
        try {
          final found = await client.byId(match.group(2)!);
          if (found != null) {
            ref.read(externalRecipeCacheProvider)[id] = found;
          }
          return found;
        } on ProviderUnavailable {
          return null;
        }
      }
      return null;
    });
