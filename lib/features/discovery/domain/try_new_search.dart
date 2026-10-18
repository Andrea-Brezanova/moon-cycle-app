import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';

/// Existing recipes that use **all** of [foodIds] (as ingredient lines or key
/// foods), allowed by the user's diet and avoidances. Recipes of [phase] come
/// first; ties keep the library order, so the result is stable.
///
/// Used by Try Something New: three foods, and recipes that include every one.
List<Recipe> recipesUsingAll(
  Catalogue catalogue,
  FoodFilter filter,
  List<String> foodIds, {
  Phase? phase,
  int limit = 3,
}) {
  final found = [
    for (final r in catalogue.recipes)
      if (filter.allowsRecipe(r, catalogue) && _usesAll(r, foodIds)) r,
  ];
  if (phase != null) {
    found.sort((a, b) {
      final pa = a.phase == phase ? 0 : 1;
      final pb = b.phase == phase ? 0 : 1;
      return pa - pb; // stable sort keeps library order within each group
    });
  }
  return found.take(limit).toList();
}

bool _usesAll(Recipe r, List<String> foodIds) {
  final present = {for (final l in r.ingredients) ?l.foodId, ...r.keyFoodIds};
  return foodIds.every(present.contains);
}
