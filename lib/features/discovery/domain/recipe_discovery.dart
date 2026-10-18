import '../../../core/domain/phase.dart';
import '../../content/domain/food_filter.dart';
import 'recipe_candidate.dart';
import 'recipe_matcher.dart';
import 'recipe_source.dart';

/// A place recipes can be found. Implementations: the internal library, and an
/// approved external provider when one is configured.
abstract interface class RecipeSourceProvider {
  RecipeSource get source;

  /// Every recipe at least a good partial match, already filtered by the
  /// user's diet and avoidances and ranked. May throw; the caller carries on
  /// with the next source.
  Future<List<RecipeCandidate>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? viewingPhase,
  });
}

/// What discovery found for a meal.
final class DiscoveryResult {
  const DiscoveryResult({
    required this.complete,
    required this.partial,
    this.completeSource,
    this.failedSources = const [],
  });

  /// Recipes that use every selected food, from the first source that has any.
  final List<RecipeCandidate> complete;

  /// Close matches, offered separately. Never presented as the requested meal.
  final List<RecipeCandidate> partial;

  /// The source [complete] came from; null when nothing complete was found.
  final RecipeSource? completeSource;

  /// Sources that errored (the search still carried on).
  final List<RecipeSource> failedSources;

  /// No existing recipe uses every selected food: only then may the generation
  /// fallback be offered.
  bool get needsGeneration => complete.isEmpty;
}

/// Tries the sources in priority order and stops at the first with a complete
/// match, so a generated recipe is only ever a fallback.
final class RecipeDiscovery {
  const RecipeDiscovery(this.sources, {this.maxSuggestions = 5});

  /// In priority order: internal library, then external.
  final List<RecipeSourceProvider> sources;
  final int maxSuggestions;

  Future<DiscoveryResult> discover(
    MealChoice choice,
    FoodFilter filter, {
    Phase? viewingPhase,
  }) async {
    final partial = <RecipeCandidate>[];
    final failed = <RecipeSource>[];
    for (final source in sources) {
      final List<RecipeCandidate> found;
      try {
        found = await source.find(choice, filter, viewingPhase: viewingPhase);
      } on Object {
        failed.add(source.source);
        continue;
      }
      final complete = [
        for (final c in found)
          if (c.isComplete) c,
      ];
      partial.addAll([
        for (final c in found)
          if (!c.isComplete) c,
      ]);
      if (complete.isNotEmpty) {
        return DiscoveryResult(
          complete: complete,
          partial: partial.take(maxSuggestions).toList(),
          completeSource: source.source,
          failedSources: failed,
        );
      }
    }
    return DiscoveryResult(
      complete: const [],
      partial: partial.take(maxSuggestions).toList(),
      failedSources: failed,
    );
  }
}
