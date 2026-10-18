import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../data/recipe_sources.dart';
import '../domain/match_config.dart';
import '../domain/recipe_discovery.dart';
import '../domain/recipe_matcher.dart';

/// The matching thresholds. One place to change them (and to override in
/// tests).
final matchConfigProvider = Provider<MatchConfig>(
  (ref) => MatchConfig.defaults,
);

/// The approved external recipe provider. None is approved yet, so this is the
/// empty client; an adapter replaces it here once one is chosen and its terms
/// are checked.
final externalRecipeClientProvider = Provider<ExternalRecipeClient>(
  (ref) => const NoExternalRecipeClient(),
);

/// Internal library first, then the external provider.
final recipeDiscoveryProvider = Provider<RecipeDiscovery>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final config = ref.watch(matchConfigProvider);
  return RecipeDiscovery([
    InternalRecipeSource(catalogue, config: config),
    ExternalRecipeSource(
      ref.watch(externalRecipeClientProvider),
      catalogue,
      config: config,
    ),
  ], maxSuggestions: config.maxSuggestions);
});

/// What discovery finds for a meal (keyed by [MealChoice.key]), for the user's
/// diet and avoidances and the phase being viewed.
final mealDiscoveryProvider = FutureProvider.autoDispose
    .family<DiscoveryResult, String>(
      (ref, key) => ref
          .watch(recipeDiscoveryProvider)
          .discover(
            MealChoice.fromKey(key),
            ref.watch(foodFilterProvider),
            viewingPhase: ref.watch(viewingPhaseProvider),
          ),
    );
