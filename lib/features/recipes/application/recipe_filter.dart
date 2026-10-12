import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/domain/recipe.dart';
import '../../cycle/application/viewing_phase.dart';

/// The Recipes filters besides the phase: a meal type and one ingredient
/// (PRD §9). Session state, not saved.
final class RecipeFilter {
  const RecipeFilter({this.mealType, this.foodId});

  /// Null is "All".
  final MealType? mealType;

  /// "Cook with…": a catalogue food, or null.
  final String? foodId;

  RecipeFilter copyWith({
    MealType? mealType,
    bool clearMealType = false,
    String? foodId,
    bool clearFood = false,
  }) => RecipeFilter(
    mealType: clearMealType ? null : (mealType ?? this.mealType),
    foodId: clearFood ? null : (foodId ?? this.foodId),
  );
}

final recipeFilterProvider =
    NotifierProvider<RecipeFilterController, RecipeFilter>(
      RecipeFilterController.new,
    );

class RecipeFilterController extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() {
    // An ingredient belongs to a phase: a new phase clears it (plan §13).
    ref.listen(viewingPhaseProvider, (_, _) {
      if (state.foodId != null) state = state.copyWith(clearFood: true);
    });
    return const RecipeFilter();
  }

  void setMealType(MealType? type) => state = type == null
      ? state.copyWith(clearMealType: true)
      : state.copyWith(mealType: type);

  void cookWith(String foodId) => state = state.copyWith(foodId: foodId);

  void clearIngredient() => state = state.copyWith(clearFood: true);

  /// "See N recipes with X" from a sheet: that ingredient, every meal type.
  void showRecipesWith(String foodId) => state = RecipeFilter(foodId: foodId);

  /// "All recipes" from Home.
  void reset() => state = const RecipeFilter();
}
