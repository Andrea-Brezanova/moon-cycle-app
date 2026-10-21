import '../../content/domain/recipe.dart';
import 'recipe_matcher.dart';
import 'recipe_source.dart';

/// One recipe offered for a meal: the app's own [Recipe] (so every existing
/// screen works unchanged) plus where it came from and what may be done with
/// it. Screens depend on this, never on a provider.
final class RecipeCandidate {
  const RecipeCandidate({
    required this.recipe,
    required this.source,
    required this.rights,
    required this.match,
    this.providerId = 'moon-cycle',
    this.alsoFrom = const [],
  });

  final Recipe recipe;
  final RecipeSource source;

  /// `moon-cycle`, or the external provider's short id (`themealdb`).
  final String providerId;
  final RecipeRights rights;
  final RecipeMatch match;

  /// Other providers that had the same recipe (it is shown once).
  final List<String> alsoFrom;

  bool get isComplete => match.level == MatchLevel.complete;

  /// "2 of 3": how many of the chosen foods this recipe uses.
  String matchCount(int chosen) => '${match.matchedIds.length} of $chosen';

  RecipeCandidate withAlsoFrom(List<String> providers) => RecipeCandidate(
    recipe: recipe,
    source: source,
    rights: rights,
    match: match,
    providerId: providerId,
    alsoFrom: providers,
  );
}
