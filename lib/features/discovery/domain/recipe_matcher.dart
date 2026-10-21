import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';
import 'match_config.dart';

/// The foods the user chose to cook with: any foods, in any categories.
final class MealChoice {
  MealChoice(List<String> ids) : ids = List.unmodifiable(ids);

  final List<String> ids;

  /// A stable text form (`a,b,c`), usable as a provider key.
  String get key => ids.join(',');

  factory MealChoice.fromKey(String key) => MealChoice([
    for (final id in key.split(','))
      if (id.isNotEmpty) id,
  ]);

  @override
  bool operator ==(Object other) => other is MealChoice && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// How well a recipe covers a [MealChoice]. A recipe that uses none of the
/// chosen foods is not a match at all and is never returned.
enum MatchLevel {
  /// Uses every chosen food (it may use others too).
  complete,

  /// Uses most of them (see [MatchConfig.goodMinCoverage]), not all.
  good,

  /// Uses at least one, but fewer than that.
  partial,
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

  /// Share of the chosen foods the recipe uses, 0–1.
  final double coverage;

  /// The chosen foods that are in the recipe, in the order chosen.
  final List<String> matchedIds;

  /// The chosen foods that are not.
  final List<String> missingIds;

  /// Catalogue foods in the recipe that the user did not choose.
  final List<String> extraFoodIds;
}

/// Finds and ranks recipes for a meal choice.
///
/// - A recipe qualifies if it uses **at least one** chosen food (as an
///   ingredient line or key food, by stable food id); other ingredients are
///   fine.
/// - Recipes the diet or avoidances exclude are never returned, at any level.
/// - The more chosen foods a recipe uses, the higher it ranks. Only a recipe
///   using all of them is *complete*.
final class RecipeMatcher {
  const RecipeMatcher(this.catalogue, {this.config = MatchConfig.defaults});

  final Catalogue catalogue;
  final MatchConfig config;

  List<RecipeMatch> match(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
    Iterable<Recipe>? recipes,
  }) {
    final matches = <RecipeMatch>[];
    for (final recipe in recipes ?? catalogue.recipes) {
      if (!filter.allowsRecipe(recipe, catalogue)) continue;
      final m = matchOne(recipe, choice, currentPhase: currentPhase);
      if (m != null) matches.add(m);
    }
    matches.sort(compareMatches);
    return matches;
  }

  /// The match of [recipe], or null if it uses none of the chosen foods.
  RecipeMatch? matchOne(
    Recipe recipe,
    MealChoice choice, {
    Phase? currentPhase,
  }) {
    if (choice.ids.isEmpty) return null;
    final present = {
      for (final l in recipe.ingredients) ?l.foodId,
      ...recipe.keyFoodIds,
    };
    final matched = [
      for (final id in choice.ids)
        if (present.contains(id)) id,
    ];
    if (matched.isEmpty) return null;
    final missing = [
      for (final id in choice.ids)
        if (!present.contains(id)) id,
    ];
    final coverage = matched.length / choice.ids.length;
    final extras = [
      for (final l in recipe.ingredients)
        if (l.foodId != null && !choice.ids.contains(l.foodId)) l.foodId!,
    ];
    final level = missing.isEmpty
        ? MatchLevel.complete
        : coverage >= config.goodMinCoverage
        ? MatchLevel.good
        : MatchLevel.partial;
    final wellWritten =
        recipe.steps.length >= config.completeMinSteps &&
        recipe.ingredients.isNotEmpty;
    final score =
        matched.length * 100.0 +
        (currentPhase == recipe.phase ? config.phaseBonus : 0) +
        (wellWritten ? config.qualityBonus : 0) -
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

  /// More chosen foods first, then higher score, then recipe id (stable).
  static int compareMatches(RecipeMatch a, RecipeMatch b) {
    final byCount = b.matchedIds.length.compareTo(a.matchedIds.length);
    if (byCount != 0) return byCount;
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.recipe.id.compareTo(b.recipe.id);
  }
}
