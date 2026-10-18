import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';
import '../domain/match_config.dart';
import '../domain/recipe_candidate.dart';
import '../domain/recipe_discovery.dart';
import '../domain/recipe_matcher.dart';
import '../domain/recipe_source.dart';

/// Moon Cycle's own library (priority 1).
class InternalRecipeSource implements RecipeSourceProvider {
  InternalRecipeSource(
    this.catalogue, {
    MatchConfig config = MatchConfig.defaults,
  }) : _matcher = RecipeMatcher(catalogue, config: config);

  final Catalogue catalogue;
  final RecipeMatcher _matcher;

  @override
  RecipeSource get source => RecipeSource.internal;

  @override
  Future<List<RecipeCandidate>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? viewingPhase,
  }) async => [
    for (final m in _matcher.match(choice, filter, viewingPhase: viewingPhase))
      RecipeCandidate(
        recipe: m.recipe,
        source: RecipeSource.internal,
        rights: RecipeRights.moonCycle,
        match: m,
      ),
  ];
}

/// A recipe from an external provider, already normalised into the app's
/// [Recipe] (ingredients linked to catalogue food ids by the adapter) with the
/// terms it came with.
final class ExternalRecipe {
  const ExternalRecipe({required this.recipe, required this.rights});

  /// Its id is namespaced by the adapter (`x-<provider>-<id>`).
  final Recipe recipe;
  final RecipeRights rights;
}

/// The one thing a provider adapter implements. Nothing else in the app knows
/// which provider is behind it.
abstract interface class ExternalRecipeClient {
  Future<List<ExternalRecipe>> search(MealChoice choice, FoodFilter filter);
}

/// No external provider is approved or configured: production today.
class NoExternalRecipeClient implements ExternalRecipeClient {
  const NoExternalRecipeClient();

  @override
  Future<List<ExternalRecipe>> search(
    MealChoice choice,
    FoodFilter filter,
  ) async => const [];
}

/// An approved external provider (priority 2). Applies the same matcher and the
/// same diet and avoidance filter as the internal library, and drops anything
/// whose terms do not allow showing it in full.
class ExternalRecipeSource implements RecipeSourceProvider {
  ExternalRecipeSource(
    this.client,
    this.catalogue, {
    MatchConfig config = MatchConfig.defaults,
  }) : _matcher = RecipeMatcher(catalogue, config: config);

  final ExternalRecipeClient client;
  final Catalogue catalogue;
  final RecipeMatcher _matcher;

  @override
  RecipeSource get source => RecipeSource.externalApi;

  @override
  Future<List<RecipeCandidate>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? viewingPhase,
  }) async {
    final found = [
      for (final e in await client.search(choice, filter))
        if (e.rights.mayDisplayFull) e,
    ];
    final rights = {for (final e in found) e.recipe.id: e.rights};
    final matches = _matcher.match(
      choice,
      filter,
      viewingPhase: viewingPhase,
      recipes: [for (final e in found) e.recipe],
    );
    return [
      for (final m in matches)
        RecipeCandidate(
          recipe: m.recipe,
          source: RecipeSource.externalApi,
          rights: rights[m.recipe.id]!,
          match: m,
        ),
    ];
  }
}
