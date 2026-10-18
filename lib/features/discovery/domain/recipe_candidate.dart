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
  });

  final Recipe recipe;
  final RecipeSource source;
  final RecipeRights rights;
  final RecipeMatch match;

  bool get isComplete => match.level == MatchLevel.complete;
}
