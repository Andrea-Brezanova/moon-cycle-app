import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/viewing_phase.dart';
import 'food_providers.dart';

/// What the user has chosen for a meal: one protein, one base and two or three
/// plants, by food id.
final class MealSelection {
  const MealSelection({this.proteinId, this.baseId, this.plantIds = const []});

  static const maxPlants = 3;
  static const minPlants = 2;

  final String? proteinId;
  final String? baseId;
  final List<String> plantIds;

  bool get isEmpty => proteinId == null && baseId == null && plantIds.isEmpty;

  /// A protein, a base and 2–3 plants.
  bool get isComplete =>
      proteinId != null &&
      baseId != null &&
      plantIds.length >= minPlants &&
      plantIds.length <= maxPlants;

  /// Every chosen food id, in meal order.
  List<String> get ids => [?proteinId, ?baseId, ...plantIds];

  bool contains(String id) => ids.contains(id);
}

final mealSelectionProvider =
    NotifierProvider.autoDispose<MealSelectionController, MealSelection>(
      MealSelectionController.new,
    );

class MealSelectionController extends Notifier<MealSelection> {
  @override
  MealSelection build() => const MealSelection();

  /// Chooses (or, if already chosen, un-chooses) [food] in its [slot].
  /// Returns false when a plant can't be added because three are chosen.
  /// A food is never in the meal twice.
  bool toggle(MealSlot slot, Food food) {
    final s = state;
    switch (slot) {
      case MealSlot.protein:
        state = MealSelection(
          proteinId: s.proteinId == food.id ? null : food.id,
          baseId: s.baseId == food.id ? null : s.baseId,
          plantIds: [...s.plantIds]..remove(food.id),
        );
      case MealSlot.base:
        state = MealSelection(
          proteinId: s.proteinId == food.id ? null : s.proteinId,
          baseId: s.baseId == food.id ? null : food.id,
          plantIds: [...s.plantIds]..remove(food.id),
        );
      case MealSlot.plant:
        if (s.plantIds.contains(food.id)) {
          state = MealSelection(
            proteinId: s.proteinId,
            baseId: s.baseId,
            plantIds: [...s.plantIds]..remove(food.id),
          );
        } else if (s.plantIds.length >= MealSelection.maxPlants) {
          return false;
        } else {
          state = MealSelection(
            proteinId: s.proteinId == food.id ? null : s.proteinId,
            baseId: s.baseId == food.id ? null : s.baseId,
            plantIds: [...s.plantIds, food.id],
          );
        }
    }
    return true;
  }

  /// Starts the meal with [food] in the slot it belongs in (from a food's
  /// page). Does nothing if it is already chosen.
  void seed(Food food) {
    if (state.contains(food.id)) return;
    // Herbs season a meal; they are not one of its plants.
    if (isHerb(food)) return;
    final slot = mealSlotFor(food);
    // Don't let a seed push out a plant: three are the most.
    toggle(slot, food);
  }

  /// Removes [id] wherever it is.
  void remove(String id) {
    final s = state;
    state = MealSelection(
      proteinId: s.proteinId == id ? null : s.proteinId,
      baseId: s.baseId == id ? null : s.baseId,
      plantIds: [...s.plantIds]..remove(id),
    );
  }

  void clear() => state = const MealSelection();
}

/// The foods a step offers.
final class MealOptions {
  const MealOptions({required this.suggested, required this.all});

  /// A short, balanced starting list (featured foods of the phase first).
  final List<Food> suggested;

  /// Everything the user can pick for the step, featured foods first, then
  /// A–Z. Nothing is hidden because of the phase.
  final List<Food> all;
}

final mealOptionsProvider = Provider.family<MealOptions, MealSlot>((ref, slot) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final phase = ref.watch(viewingPhaseProvider);
  final featured = catalogue.phase(phase).foodIds.toSet();

  bool eligible(Food f) => switch (slot) {
    MealSlot.protein => proteinFamilyOf(f) != null,
    MealSlot.base => isBaseFood(f),
    MealSlot.plant => isMealPlant(f),
  };

  final all =
      [
        for (final f in catalogue.foods)
          if (eligible(f) && filter.allowsFood(f)) f,
      ]..sort((a, b) {
        final fa = featured.contains(a.id) ? 0 : 1;
        final fb = featured.contains(b.id) ? 0 : 1;
        if (fa != fb) return fa - fb;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

  final suggested = switch (slot) {
    MealSlot.protein => ref.watch(proteinIdeasProvider(phase)).all,
    MealSlot.base => ref.watch(baseIdeasProvider(phase)).all,
    MealSlot.plant => all.take(12).toList(),
  };
  return MealOptions(suggested: suggested, all: all);
});
