import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';
import '../domain/ingredient_mapper.dart';
import '../domain/match_config.dart';
import '../domain/provider_policy.dart';
import '../domain/recipe_candidate.dart';
import '../domain/recipe_discovery.dart';
import '../domain/recipe_matcher.dart';
import '../domain/recipe_source.dart';
import 'providers/ingredient_lines.dart';

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
  String get providerId => 'moon-cycle';

  @override
  Future<List<RecipeCandidate>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
  }) async => [
    for (final m in _matcher.match(choice, filter, currentPhase: currentPhase))
      RecipeCandidate(
        recipe: m.recipe,
        source: RecipeSource.internal,
        providerId: providerId,
        rights: RecipeRights.moonCycle,
        match: m,
      ),
  ];
}

/// A recipe from an external provider, already normalised into the app's
/// [Recipe] (ingredients linked to catalogue food ids by the adapter where the
/// mapping is reliable) with the terms it came with.
final class ExternalRecipe {
  const ExternalRecipe({
    required this.recipe,
    required this.rights,
    required this.providerId,
    required this.externalId,
  });

  /// Its id is namespaced by the adapter (`x-<provider>-<id>`).
  final Recipe recipe;
  final RecipeRights rights;

  /// The provider's short id (`themealdb`).
  final String providerId;

  /// The provider's own id for the recipe.
  final String externalId;
}

/// The one thing a provider adapter implements. Nothing else in the app knows
/// which provider is behind it. Provider-specific parsing, ingredient names and
/// endpoints stay inside the adapter.
abstract interface class ExternalRecipeClient {
  String get providerId;

  /// Recipes that may use any of the chosen foods. May throw
  /// [ProviderUnavailable]; the search carries on with the other sources.
  Future<List<ExternalRecipe>> search(MealChoice choice, FoodFilter filter);

  /// One recipe by its provider id (to reopen a saved reference), or null.
  Future<ExternalRecipe?> byId(String externalId);
}

/// No external provider is approved or configured.
class NoExternalRecipeClient implements ExternalRecipeClient {
  const NoExternalRecipeClient();

  @override
  String get providerId => 'none';

  @override
  Future<List<ExternalRecipe>> search(
    MealChoice choice,
    FoodFilter filter,
  ) async => const [];

  @override
  Future<ExternalRecipe?> byId(String externalId) async => null;
}

/// An external provider as a recipe source. Whatever the adapter returns, this
/// applies the same rules as for the library:
///
/// - recipes whose terms forbid full display are dropped;
/// - **a recipe with an ingredient we cannot identify is dropped whenever the
///   user has a diet or an avoidance**, because it cannot be shown to be safe
///   (only Moon Cycle foods, plain pantry items and ingredients with reviewed
///   allergen data in the ingredient vocabulary count as identified);
/// - the user's diet and avoidances are applied with the same filter;
/// - the same matcher ranks them.
class ExternalRecipeSource implements RecipeSourceProvider {
  ExternalRecipeSource(
    this.client,
    this.catalogue, {
    required this.policy,
    MatchConfig config = MatchConfig.defaults,
    this.onFound,
  }) : _matcher = RecipeMatcher(catalogue, config: config),
       _mapper = IngredientMapper(catalogue);

  final IngredientMapper _mapper;
  final ExternalRecipeClient client;
  final Catalogue catalogue;
  final ProviderPolicy policy;
  final RecipeMatcher _matcher;

  /// Told about every recipe that will be shown, so a detail page can open it
  /// without asking the provider again.
  final void Function(ExternalRecipe recipe)? onFound;

  @override
  RecipeSource get source => RecipeSource.externalApi;

  @override
  String get providerId => client.providerId;

  /// Whatever the adapter did, lines with no food id are understood again here,
  /// so known allergens and animal sources are always attached and checked.
  ExternalRecipe _withKnownData(ExternalRecipe e) {
    final r = e.recipe;
    final lines = [
      for (final l in r.ingredients)
        l.foodId == null &&
                l.extraAllergenIds.isEmpty &&
                l.extraAnimalSource == null
            ? ingredientLine(_mapper, l.label, quantity: l.qtyText)
            : l,
    ];
    return ExternalRecipe(
      recipe: Recipe(
        id: r.id,
        title: r.title,
        phase: r.phase,
        category: r.category,
        minutes: r.minutes,
        serves: r.serves,
        intro: r.intro,
        whyThisPhase: r.whyThisPhase,
        imageUrl: r.imageUrl,
        keyFoodIds: r.keyFoodIds,
        ingredients: lines,
        steps: r.steps,
      ),
      rights: e.rights,
      providerId: e.providerId,
      externalId: e.externalId,
    );
  }

  /// Whether [recipe] can be shown to a user with [filter].
  bool safeFor(Recipe recipe, FoodFilter filter) {
    if (filter.isEmpty) return true;
    for (final line in recipe.ingredients) {
      if (line.foodId == null && !_mapper.classify(line.label).isIdentified) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<List<RecipeCandidate>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
  }) async {
    if (!policy.enabled) return const [];
    final raw = await client
        .search(choice, filter)
        .timeout(
          policy.timeout,
          onTimeout: () =>
              throw const ProviderUnavailable(ProviderProblem.timeout),
        );
    final found = <ExternalRecipe>[];
    for (final e0 in raw) {
      final e = _withKnownData(e0);
      if (!e.rights.mayDisplayFull || !safeFor(e.recipe, filter)) continue;
      found.add(
        ExternalRecipe(
          recipe: currentPhase == null
              ? e.recipe
              : e.recipe.copyWith(phase: currentPhase),
          rights: e.rights,
          providerId: e.providerId,
          externalId: e.externalId,
        ),
      );
    }
    final byId = {for (final e in found) e.recipe.id: e};
    final matches = _matcher.match(
      choice,
      filter,
      currentPhase: currentPhase,
      recipes: [for (final e in found) e.recipe],
    );
    final out = <RecipeCandidate>[];
    for (final m in matches) {
      final e = byId[m.recipe.id]!;
      onFound?.call(e);
      out.add(
        RecipeCandidate(
          recipe: m.recipe,
          source: RecipeSource.externalApi,
          providerId: e.providerId,
          rights: e.rights,
          match: m,
        ),
      );
    }
    return out;
  }
}
