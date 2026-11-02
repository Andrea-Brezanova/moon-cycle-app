import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../domain/complement_ranker.dart';

/// Build a Meal 2.0, application layer (docs/build-a-meal-2.md). NOT shown in
/// the app: nothing in the UI reads these providers yet, and the existing
/// Build a Meal flow is unchanged.

/// The most foods a 2.0 meal holds (same limit as the current builder).
const mealDraftMaxFoods = 8;

/// Foods the user dislikes. A dislike only keeps a food out of *suggestions*;
/// it never blocks choosing that food on purpose, and it is not a safety
/// filter (allergies and diet are, through [foodFilterProvider]).
///
/// Empty until the dislikes preference exists (a separate, schema-approved
/// change; see docs/build-a-meal-2-data-model.md).
final dislikedFoodIdsProvider = Provider<Set<String>>((ref) => const {});

enum AddResult { added, alreadyChosen, full, notAllowed, unknownFood }

/// The foods chosen so far, in the order chosen. Any food can start a meal and
/// no category is required. Kept alive for the whole session so leaving the
/// screen and coming back keeps the selection (unlike an auto-disposed
/// provider).
final mealDraftProvider = NotifierProvider<MealDraftController, List<String>>(
  MealDraftController.new,
);

class MealDraftController extends Notifier<List<String>> {
  @override
  List<String> build() {
    // If the user later adds an allergy or changes diet, a chosen food that is
    // no longer allowed is dropped rather than left in the meal.
    ref.listen(foodFilterProvider, (_, filter) {
      final catalogue = ref.read(catalogueProvider);
      state = [
        for (final id in state)
          if (catalogue.food(id) case final food? when filter.allowsFood(food))
            id,
      ];
    });
    return const [];
  }

  /// Adds [foodId] unless it is unknown, not allowed for this user (diet,
  /// allergies, avoidances), already chosen, or the meal is full.
  AddResult add(String foodId) {
    final food = ref.read(catalogueProvider).food(foodId);
    if (food == null) return AddResult.unknownFood;
    if (!ref.read(foodFilterProvider).allowsFood(food)) {
      return AddResult.notAllowed;
    }
    if (state.contains(foodId)) return AddResult.alreadyChosen;
    if (state.length >= mealDraftMaxFoods) return AddResult.full;
    state = [...state, foodId];
    return AddResult.added;
  }

  void remove(String foodId) => state = [...state]..remove(foodId);

  void clear() => state = const [];
}

/// Foods that go with the draft, with reasons: strictly within the user's diet
/// and allergies, never a disliked or already chosen food, no phase input.
final mealSuggestionsProvider = Provider<List<Suggestion>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final chosen = <Food>[
    for (final id in ref.watch(mealDraftProvider)) ?catalogue.food(id),
  ];
  return suggestComplements(
    chosen: chosen,
    candidates: catalogue.foods,
    allows: filter.allowsFood,
    dislikedIds: ref.watch(dislikedFoodIdsProvider),
  );
});
