import '../../preferences/domain/diet.dart';
import '../../preferences/domain/food_avoidance.dart';
import 'catalogue.dart';
import 'food.dart';
import 'recipe.dart';
import 'text_match.dart';

/// Leaves out what the user doesn't eat (plan §8.4).
///
/// - Diet: vegan excludes every animal source; vegetarian excludes meat and
///   seafood; pescatarian excludes meat.
/// - Avoidances: an avoided allergen excludes every food and recipe line that
///   carries it *or may carry it* (check-label foods such as oats and gluten);
///   an avoided food excludes that food; a typed avoidance excludes foods and
///   recipe lines whose name contains it.
/// - A recipe is excluded if any of its lines is.
///
/// Matching is conservative: when in doubt, leave it out.
final class FoodFilter {
  const FoodFilter({this.diet = Diet.omnivore, this.avoidances = const []});

  static const none = FoodFilter();

  final Diet diet;
  final List<FoodAvoidance> avoidances;

  bool get isEmpty => diet == Diet.omnivore && avoidances.isEmpty;

  /// The allergen ids the user avoids.
  Set<String> get allergenIds => _allergens;

  Set<String> get _allergens => {
    for (final a in avoidances)
      if (a is AllergenAvoidance) a.allergenId,
  };

  Set<String> get _foods => {
    for (final a in avoidances)
      if (a is FoodItemAvoidance) a.foodId,
  };

  List<String> get _phrases => [
    for (final a in avoidances)
      if (a is CustomAvoidance) a.label,
  ];

  bool allowsFood(Food food) =>
      _dietAllows(food.animalSource) &&
      !_foods.contains(food.id) &&
      food.allergenIds.intersection(_allergens).isEmpty &&
      food.mayContainAllergenIds.intersection(_allergens).isEmpty &&
      !_phrases.any(
        (p) =>
            containsPhrase(food.name, p) ||
            food.synonyms.any((s) => containsPhrase(s, p)),
      );

  bool allowsLine(RecipeIngredient line, Catalogue catalogue) {
    if (line.extraAllergenIds.intersection(_allergens).isNotEmpty) {
      return false;
    }
    if (_phrases.any((p) => containsPhrase(line.label, p))) return false;
    final food = line.foodId == null ? null : catalogue.food(line.foodId!);
    return food == null || allowsFood(food);
  }

  /// Vegetarian and vegan users also lose recipes with a food that only *may*
  /// contain fish or shellfish (kimchi): the recipe cannot be called
  /// meat-free with confidence. Foods themselves are unchanged.
  bool _conditionallyAnimal(Recipe recipe, Catalogue catalogue) {
    if (diet != Diet.vegetarian && diet != Diet.vegan) return false;
    return recipe.ingredients.any((line) {
      final food = line.foodId == null ? null : catalogue.food(line.foodId!);
      return food != null &&
          food.mayContainAllergenIds.any(
            (a) => a == 'fish' || a == 'shellfish',
          );
    });
  }

  bool allowsRecipe(Recipe recipe, Catalogue catalogue) =>
      !_conditionallyAnimal(recipe, catalogue) &&
      recipe.ingredients.every((line) => allowsLine(line, catalogue));

  /// The lines of [recipe] the user avoids; adding the recipe to Shop skips
  /// them.
  List<RecipeIngredient> avoidedLines(Recipe recipe, Catalogue catalogue) => [
    for (final line in recipe.ingredients)
      if (!allowsLine(line, catalogue)) line,
  ];

  bool _dietAllows(AnimalSource source) => switch (diet) {
    Diet.omnivore => true,
    Diet.pescatarian => source != AnimalSource.meat,
    Diet.vegetarian =>
      source != AnimalSource.meat && source != AnimalSource.seafood,
    Diet.vegan => source == AnimalSource.none,
  };
}
