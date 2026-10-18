import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import 'food_providers.dart';

/// Limits of the meal builder, in one place.
abstract final class MealBuilderConfig {
  /// The most foods one search can use. Raise it here if testing shows people
  /// want more.
  static const maxIngredients = 8;

  /// A search needs at least one food. No category is required.
  static const minIngredients = 1;
}

/// The foods the user has chosen to cook with: any number from one to
/// [MealBuilderConfig.maxIngredients], from any category, each at most once.
final class MealSelection {
  const MealSelection([this.ids = const []]);

  /// Food ids in the order they were chosen.
  final List<String> ids;

  bool get isEmpty => ids.isEmpty;

  /// A search can start.
  bool get canCreate => ids.length >= MealBuilderConfig.minIngredients;

  bool get isFull => ids.length >= MealBuilderConfig.maxIngredients;

  bool contains(String id) => ids.contains(id);
}

final mealSelectionProvider =
    NotifierProvider.autoDispose<MealSelectionController, MealSelection>(
      MealSelectionController.new,
    );

class MealSelectionController extends Notifier<MealSelection> {
  @override
  MealSelection build() => const MealSelection();

  /// Chooses [food], or un-chooses it if already chosen. Returns false when
  /// the limit is reached and nothing was added.
  bool toggle(Food food) {
    final s = state;
    if (s.contains(food.id)) {
      state = MealSelection([...s.ids]..remove(food.id));
      return true;
    }
    if (s.isFull) return false;
    state = MealSelection([...s.ids, food.id]);
    return true;
  }

  /// Starts the meal with [food] (from its page). Does nothing if it is already
  /// chosen. Herbs season a meal and are not offered as ingredients here.
  void seed(Food food) {
    if (state.contains(food.id) || isHerb(food)) return;
    toggle(food);
  }

  void remove(String id) => state = MealSelection([...state.ids]..remove(id));

  void clear() => state = const MealSelection();
}

/// The foods one section offers.
final class MealOptions {
  const MealOptions({required this.phaseFoods, required this.otherFoods});

  /// Eligible foods featured in the user's current phase: what a section shows
  /// first, and on its own until "Show all foods" is pressed.
  final List<Food> phaseFoods;

  /// The other eligible foods, from other phases or from none, A–Z.
  final List<Food> otherFoods;

  List<Food> get all => [...phaseFoods, ...otherFoods];
}

/// What each section offers. "Current phase" is the phase calculated from the
/// user's cycle, not one they are browsing, and the diet and avoidances apply.
final mealOptionsProvider = Provider.family<MealOptions, MealSlot>((ref, slot) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final featured = catalogue
      .phase(ref.watch(actualPhaseProvider))
      .foodIds
      .toSet();

  bool eligible(Food f) => switch (slot) {
    MealSlot.protein => proteinFamilyOf(f) != null,
    MealSlot.base => isBaseFood(f),
    MealSlot.plant => isMealPlant(f),
  };
  int az(Food a, Food b) =>
      a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());

  final allowed = [
    for (final f in catalogue.foods)
      if (eligible(f) && filter.allowsFood(f)) f,
  ];
  return MealOptions(
    phaseFoods: [
      for (final f in allowed)
        if (featured.contains(f.id)) f,
    ]..sort(az),
    otherFoods: [
      for (final f in allowed)
        if (!featured.contains(f.id)) f,
    ]..sort(az),
  );
});
