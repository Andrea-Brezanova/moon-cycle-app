import '../../content/domain/text_match.dart';
import 'recipe_candidate.dart';

/// Removes the same recipe shown twice, without merging recipes that merely
/// sound alike.
///
/// Two candidates are the same recipe when either
/// - they have the same provider and the same id; or
/// - their normalised titles are equal **and** their identified ingredients
///   overlap by at least [minIngredientOverlap]; or
/// - their titles share at least [minTitleOverlap] of their words **and** their
///   identified ingredients overlap by at least [strongIngredientOverlap].
///
/// Similar titles alone are never enough ("Chicken Curry" in two kitchens), and
/// neither are similar ingredients alone. Each side needs at least
/// [minIngredients] identified ingredients to be compared. The better-ranked
/// copy is kept (the list is already ranked) and records which providers also
/// had it, so provenance and each provider's rights stay with the copy shown.
class RecipeDeduper {
  const RecipeDeduper({
    this.minIngredientOverlap = 0.5,
    this.minTitleOverlap = 0.7,
    this.strongIngredientOverlap = 0.7,
    this.minIngredients = 3,
  });

  final double minIngredientOverlap;
  final double minTitleOverlap;
  final double strongIngredientOverlap;
  final int minIngredients;

  List<RecipeCandidate> dedupe(List<RecipeCandidate> ranked) {
    final kept = <RecipeCandidate>[];
    final also = <int, List<String>>{};
    for (final c in ranked) {
      var merged = false;
      for (var i = 0; i < kept.length; i++) {
        if (isSame(kept[i], c)) {
          final list = also.putIfAbsent(i, () => [...kept[i].alsoFrom]);
          if (c.providerId != kept[i].providerId &&
              !list.contains(c.providerId)) {
            list.add(c.providerId);
          }
          merged = true;
          break;
        }
      }
      if (!merged) kept.add(c);
    }
    return [
      for (final (i, c) in kept.indexed)
        also.containsKey(i) ? c.withAlsoFrom(also[i]!) : c,
    ];
  }

  bool isSame(RecipeCandidate a, RecipeCandidate b) {
    if (a.providerId == b.providerId && a.recipe.id == b.recipe.id) return true;
    final foodsA = _foods(a);
    final foodsB = _foods(b);
    if (foodsA.length < minIngredients || foodsB.length < minIngredients) {
      return false;
    }
    final overlap = _jaccard(foodsA, foodsB);
    final titleA = normaliseName(a.recipe.title);
    final titleB = normaliseName(b.recipe.title);
    if (titleA == titleB) return overlap >= minIngredientOverlap;
    return _jaccard(titleA.split(' ').toSet(), titleB.split(' ').toSet()) >=
            minTitleOverlap &&
        overlap >= strongIngredientOverlap;
  }

  static Set<String> _foods(RecipeCandidate c) => {
    for (final l in c.recipe.ingredients) ?l.foodId,
  };

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0;
    final inter = a.intersection(b).length;
    return inter / (a.length + b.length - inter);
  }
}
