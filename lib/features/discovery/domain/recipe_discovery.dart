import '../../../core/domain/phase.dart';
import '../../content/domain/food_filter.dart';
import 'recipe_candidate.dart';
import 'recipe_matcher.dart';
import 'recipe_source.dart';

/// A place recipes can be found: the internal library, and an approved external
/// provider when one is configured.
abstract interface class RecipeSourceProvider {
  RecipeSource get source;

  /// Every recipe that uses at least one chosen food, already filtered by the
  /// user's diet and avoidances. May throw; the caller carries on with the
  /// other sources.
  Future<List<RecipeCandidate>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
  });
}

/// What discovery found for a meal.
final class DiscoveryResult {
  const DiscoveryResult({required this.results, this.failedSources = const []});

  /// Every matching recipe from every source, best first: the most chosen
  /// foods first, complete matches before good before partial.
  final List<RecipeCandidate> results;

  /// Sources that errored (the search still carried on).
  final List<RecipeSource> failedSources;

  bool get isEmpty => results.isEmpty;

  /// Recipes that use every chosen food.
  List<RecipeCandidate> get complete => [
    for (final c in results)
      if (c.isComplete) c,
  ];
}

/// Asks every source, then combines and ranks what they return, so the best
/// real recipes come first whichever source they are from. Nothing is
/// generated: an empty result is reported as empty.
final class RecipeDiscovery {
  const RecipeDiscovery(this.sources);

  /// Every source is asked; the order only decides which duplicate is kept.
  final List<RecipeSourceProvider> sources;

  Future<DiscoveryResult> discover(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
  }) async {
    final all = <RecipeCandidate>[];
    final failed = <RecipeSource>[];
    for (final source in sources) {
      try {
        all.addAll(
          await source.find(choice, filter, currentPhase: currentPhase),
        );
      } on Object {
        failed.add(source.source);
      }
    }
    // Duplicates by id are dropped (the first source's copy is kept).
    final seen = <String>{};
    final ranked = <RecipeCandidate>[
      for (final c in all)
        if (seen.add(c.recipe.id)) c,
    ]..sort((a, b) => RecipeMatcher.compareMatches(a.match, b.match));
    return DiscoveryResult(results: ranked, failedSources: failed);
  }
}
