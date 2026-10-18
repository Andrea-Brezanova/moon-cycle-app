import 'dart:async';

import '../../../core/domain/phase.dart';
import '../../content/domain/food_filter.dart';
import 'provider_policy.dart';
import 'recipe_candidate.dart';
import 'recipe_deduper.dart';
import 'recipe_matcher.dart';
import 'recipe_source.dart';

/// A place recipes can be found: the internal library, or one external
/// provider. Adding or removing a provider is adding or removing a source here;
/// Build a meal and Recipe detail never change.
abstract interface class RecipeSourceProvider {
  RecipeSource get source;

  /// `moon-cycle` or the provider's short id.
  String get providerId;

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
  const DiscoveryResult({
    required this.results,
    this.failedSources = const {},
    this.countsByProvider = const {},
  });

  /// Every matching recipe from every source, best first: the most chosen
  /// foods first, complete matches before good before partial.
  final List<RecipeCandidate> results;

  /// Providers that could not answer, and why. The search still carried on.
  final Map<String, ProviderProblem> failedSources;

  /// Recipes each provider contributed before duplicates were removed.
  final Map<String, int> countsByProvider;

  bool get isEmpty => results.isEmpty;

  /// Recipes that use every chosen food.
  List<RecipeCandidate> get complete => [
    for (final c in results)
      if (c.isComplete) c,
  ];
}

/// Asks every source at the same time, each with its own failure handling, then
/// combines, ranks and de-duplicates what they return. Nothing is generated:
/// an empty result is reported as empty.
final class RecipeDiscovery {
  const RecipeDiscovery(this.sources, {this.deduper = const RecipeDeduper()});

  /// The library first: when two sources have the same recipe, the better
  /// ranked copy is kept, and on a tie the earlier source wins.
  final List<RecipeSourceProvider> sources;
  final RecipeDeduper deduper;

  Future<DiscoveryResult> discover(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
  }) async {
    final failed = <String, ProviderProblem>{};
    final counts = <String, int>{};
    final lists = await Future.wait([
      for (final source in sources)
        () async {
          try {
            final found = await source.find(
              choice,
              filter,
              currentPhase: currentPhase,
            );
            counts[source.providerId] = found.length;
            return found;
          } on ProviderUnavailable catch (e) {
            failed[source.providerId] = e.problem;
          } on Object {
            failed[source.providerId] = ProviderProblem.badResponse;
          }
          return const <RecipeCandidate>[];
        }(),
    ]);
    final all = [for (final l in lists) ...l];
    // More chosen foods first; at the same count the Moon Cycle library comes
    // before any external provider (it is reviewed, and costs nothing); then
    // score, then source order.
    int rank(RecipeCandidate c) => c.source == RecipeSource.internal ? 0 : 1;
    final indexed = [for (final (i, c) in all.indexed) (i, c)]
      ..sort((a, b) {
        final n = b.$2.match.matchedIds.length.compareTo(
          a.$2.match.matchedIds.length,
        );
        if (n != 0) return n;
        final r = rank(a.$2).compareTo(rank(b.$2));
        if (r != 0) return r;
        final byScore = RecipeMatcher.compareMatches(a.$2.match, b.$2.match);
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
    return DiscoveryResult(
      results: deduper.dedupe([for (final e in indexed) e.$2]),
      failedSources: failed,
      countsByProvider: counts,
    );
  }
}
