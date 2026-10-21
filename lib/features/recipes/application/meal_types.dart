import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/recipe.dart';

/// The meal types that have at least one recipe in the current scope (one
/// phase, or every phase for "All recipes"), in their fixed order. A tab for
/// a meal type with no recipes is never shown.
List<MealType> availableMealTypes(
  Catalogue catalogue, {
  required Phase phase,
  required bool all,
}) {
  final recipes = all ? catalogue.recipes : catalogue.recipesFor(phase);
  final present = {for (final r in recipes) r.mealType};
  return [
    for (final type in MealType.values)
      if (present.contains(type)) type,
  ];
}
