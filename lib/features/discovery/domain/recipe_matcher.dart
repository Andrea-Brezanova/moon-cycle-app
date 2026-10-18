import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';
import 'match_config.dart';

/// The foods a user chose for a meal: one protein, one base and 2–3 plants.
final class MealChoice {
  const MealChoice({
    required this.proteinId,
    required this.baseId,
    required this.plantIds,
  });

  final String proteinId;
  final String baseId;
  final List<String> plantIds;

  List<String> get ids => [proteinId, baseId, ...plantIds];

  /// A stable text form (`protein|base|plant,plant`), usable as a provider key.
  String get key => '$proteinId|$baseId|${plantIds.join(',')}';

  factory MealChoice.fromKey(String key) {
    final parts = key.split('|');
    return MealChoice(
      proteinId: parts[0],
      baseId: parts[1],
      plantIds: parts[2].isEmpty ? const [] : parts[2].split(','),
    );
  }

  @override
  bool operator ==(Object other) => other is MealChoice && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// How well a recipe covers a [MealChoice].
enum MatchLevel {
  /// Uses every selected food and nothing the user excludes.
  complete,

  /// Uses most of the selection (see [MatchConfig]); never presented as the
  /// requested meal.
  goodPartial,

  /// Not worth offering.
  insufficient,
}

final class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.level,
    required this.score,
    required this.coverage,
    required this.matchedIds,
    required this.missingIds,
    required this.extraFoodIds,
  });

  final Recipe recipe;
  final MatchLevel level;

  /// Orders results; higher is better.
  final double score;

  /// Weighted share of the selection the recipe uses, 0–1.
  final double coverage;
  final List<String> matchedIds;
  final List<String> missingIds;

  /// Catalogue foods in the recipe that the user did not choose.
  final List<String> extraFoodIds;
}

/// Finds and ranks recipes for a meal choice.
///
/// - Recipes the diet or avoidances exclude are never returned, at any level.
/// - *Complete* means every selected food id is in the recipe (as an
///   ingredient line or key food). Equivalent foods do not count (red lentils
///   are not green lentils); extra supporting ingredients are fine.
/// - *Good partial* is decided only by [MatchConfig].
final class RecipeMatcher {
  const RecipeMatcher(this.catalogue, {this.config = MatchConfig.defaults});

  final Catalogue catalogue;
  final MatchConfig config;

  List<RecipeMatch> match(
    MealChoice choice,
    FoodFilter filter, {
    Phase? viewingPhase,
    Iterable<Recipe>? recipes,
  }) {
    final matches = <RecipeMatch>[];
    for (final recipe in recipes ?? catalogue.recipes) {
      if (!filter.allowsRecipe(recipe, catalogue)) continue;
      final m = matchOne(recipe, choice, viewingPhase: viewingPhase);
      if (m.level != MatchLevel.insufficient) matches.add(m);
    }
    matches.sort(_byRank);
    return matches;
  }

  RecipeMatch matchOne(
    Recipe recipe,
    MealChoice choice, {
    Phase? viewingPhase,
  }) {
    final present = {
      for (final l in recipe.ingredients) ?l.foodId,
      ...recipe.keyFoodIds,
    };
    double weight(String id) => id == choice.proteinId
        ? config.proteinWeight
        : id == choice.baseId
        ? config.baseWeight
        : config.plantWeight;

    final matched = [
      for (final id in choice.ids)
        if (present.contains(id)) id,
    ];
    final missing = [
      for (final id in choice.ids)
        if (!present.contains(id)) id,
    ];
    final total = choice.ids.fold<double>(0, (s, id) => s + weight(id));
    final got = matched.fold<double>(0, (s, id) => s + weight(id));
    final coverage = total == 0 ? 0.0 : got / total;

    final extras = [
      for (final l in recipe.ingredients)
        if (l.foodId != null && !choice.ids.contains(l.foodId)) l.foodId!,
    ];

    final level = missing.isEmpty
        ? MatchLevel.complete
        : (coverage >= config.goodPartialMinCoverage &&
              matched.length >= config.partialMinMatched &&
              (!config.partialNeedsProteinOrBase ||
                  matched.contains(choice.proteinId) ||
                  matched.contains(choice.baseId)))
        ? MatchLevel.goodPartial
        : MatchLevel.insufficient;

    final complete =
        recipe.steps.length >= config.completeMinSteps &&
        recipe.ingredients.isNotEmpty;
    final score =
        coverage * 100 +
        (viewingPhase == recipe.phase ? config.phaseBonus : 0) +
        (complete ? config.qualityBonus : 0) -
        extras.length * config.extraFoodPenalty;

    return RecipeMatch(
      recipe: recipe,
      level: level,
      score: score,
      coverage: coverage,
      matchedIds: matched,
      missingIds: missing,
      extraFoodIds: extras,
    );
  }

  /// Complete before partial, then higher score, then recipe id (stable).
  static int _byRank(RecipeMatch a, RecipeMatch b) {
    final level = a.level.index - b.level.index;
    if (level != 0) return level;
    final score = b.score.compareTo(a.score);
    return score != 0 ? score : a.recipe.id.compareTo(b.recipe.id);
  }
}
