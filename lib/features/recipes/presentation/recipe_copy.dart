import '../../../core/design/widgets/moon_icon.dart';
import '../../content/domain/recipe.dart';
import '../application/recipe_list.dart';

/// "recipe", "breakfasts", "snack"…
String mealNoun(MealType? type, {required bool plural}) => switch (type) {
  null => plural ? 'recipes' : 'recipe',
  MealType.breakfast => plural ? 'breakfasts' : 'breakfast',
  MealType.meals => plural ? 'meals' : 'meal',
  MealType.snacks => plural ? 'snacks' : 'snack',
};

/// "3 follicular recipes", "1 follicular recipe with chicken",
/// "0 follicular breakfasts with chicken".
String recipeCountLine(RecipeList list, {String? foodName}) {
  final n = list.recipes.length;
  final noun = mealNoun(list.filter.mealType, plural: n != 1);
  final food = foodName == null ? '' : ' with $foodName';
  return '$n ${_phaseWord(list)}$noun$food';
}

/// "follicular " for This phase; nothing for All recipes.
String _phaseWord(RecipeList list) => list.all ? '' : '${list.phase.name} ';

/// The way out of an empty list.
enum EmptyAction { showAllMealTypes, clearIngredient, reviewPreferences }

final class RecipesEmptyCopy {
  const RecipesEmptyCopy({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  final MoonIconName icon;

  /// With one `*italic*` word.
  final String title;
  final String body;
  final List<EmptyAction> actions;
}

/// The empty state for [list], or null when it has recipes (spec §7.4:
/// `16-recipes-empty-meal-type`, `17-recipes-empty-ingredient`,
/// `18-recipes-empty-preferences`).
RecipesEmptyCopy? recipesEmptyCopy(RecipeList list, {String? foodName}) {
  if (list.recipes.isNotEmpty) return null;
  final phaseSp = _phaseWord(list);
  final scopeText = list.all ? 'the' : 'this phase’s';
  final meal = list.filter.mealType;
  if (list.fitPreferences == 0) {
    return RecipesEmptyCopy(
      icon: MoonIconName.avoid,
      title: 'Nothing fits your *preferences*',
      body:
          'Your food preferences and foods to avoid leave out every '
          '${phaseSp}recipe.',
      actions: const [EmptyAction.reviewPreferences],
    );
  }
  if (foodName != null) {
    final elsewhere = meal != null && list.withFoodAnyMeal > 0;
    return RecipesEmptyCopy(
      icon: MoonIconName.recipes,
      title: meal == null
          ? 'No ${phaseSp}recipes with *$foodName*'
          : 'No ${mealNoun(meal, plural: true)} with *$foodName*',
      body: !elsewhere
          ? 'None of $scopeText recipes uses $foodName yet.'
          : list.withFoodAnyMeal == 1
          ? 'There’s a ${phaseSp}recipe with $foodName in another meal type.'
          : 'There are ${list.withFoodAnyMeal} ${phaseSp}recipes with $foodName '
                'in other meal types.',
      actions: [
        if (elsewhere) EmptyAction.showAllMealTypes,
        EmptyAction.clearIngredient,
      ],
    );
  }
  return RecipesEmptyCopy(
    icon: MoonIconName.recipes,
    title: 'No $phaseSp${mealNoun(meal, plural: true)} *yet*',
    body:
        'None of $scopeText recipes is a ${mealNoun(meal, plural: false)}. '
        'Try another meal type.',
    actions: const [EmptyAction.showAllMealTypes],
  );
}
