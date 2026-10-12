import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../data/shopping_repository.dart';
import '../domain/item_key.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_merger.dart';

/// The Undo offer after "Clear all".
final class ClearUndo {
  const ClearUndo(this.cleared);

  final ClearedItems cleared;

  /// "3 done items cleared".
  String get message {
    final n = cleared.itemIds.length;
    return '$n done ${n == 1 ? 'item' : 'items'} cleared';
  }
}

/// What adding a recipe did, for the recipe screen's feedback.
final class RecipeAdded {
  const RecipeAdded({required this.outcomes, required this.skipped});

  final List<AddOutcome> outcomes;

  /// Lines left out because the user avoids them (PRD §9).
  final List<RecipeIngredient> skipped;

  int get added => outcomes.whereType<ItemCreated>().length;
  int get merged => outcomes.whereType<ItemMerged>().length;
}

/// How long "Clear all" can be undone (spec §7.5).
final undoWindowProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 8),
);

/// Every change to the shopping list goes through here. Its state is the
/// Undo offer after "Clear all", which lasts [undoWindowProvider].
class ShoppingController extends Notifier<ClearUndo?> {
  Timer? _undoTimer;

  ShoppingRepository get _repo => ref.read(shoppingRepositoryProvider);

  @override
  ClearUndo? build() {
    ref.onDispose(() => _undoTimer?.cancel());
    return null;
  }

  /// "Add to shopping list" on the ingredient sheet.
  Future<AddOutcome> addFood(Food food, Phase phase) => _repo.add(
    AddRequest(
      key: foodKey(food.id),
      foodId: food.id,
      name: food.displayName,
      aisleId: food.aisleId,
      source: ShoppingSource(id: '', type: SourceType.phaseFood, phase: phase),
    ),
  );

  /// The add field. Null for blank text.
  Future<AddOutcome?> addTyped(String text) async {
    final typed = resolveTyped(text, ref.read(catalogueProvider));
    if (typed == null) return null;
    return _repo.add(
      AddRequest(
        key: typed.key,
        foodId: typed.foodId,
        name: typed.name,
        aisleId: typed.aisleId,
        source: const ShoppingSource(id: '', type: SourceType.manual),
      ),
    );
  }

  /// "Add ingredients to shopping list": every line the user doesn't avoid,
  /// merged with what's already there, in one transaction.
  Future<RecipeAdded> addRecipe(Recipe recipe) async {
    final catalogue = ref.read(catalogueProvider);
    final filter = ref.read(foodFilterProvider);
    final skipped = filter.avoidedLines(recipe, catalogue);
    final requests = <AddRequest>[];
    for (final line in recipe.ingredients) {
      if (skipped.contains(line)) continue;
      final food = line.foodId == null ? null : catalogue.food(line.foodId!);
      final typed = food == null ? resolveTyped(line.label, catalogue) : null;
      requests.add(
        AddRequest(
          key: lineKey(line, catalogue),
          foodId: food?.id ?? typed?.foodId,
          name: food?.displayName ?? typed!.name,
          aisleId: line.aisleId,
          source: ShoppingSource(
            id: '',
            type: SourceType.recipe,
            recipeId: recipe.id,
            amount: line.amount,
            unit: line.unit,
            qtyText: line.qtyText,
          ),
        ),
      );
    }
    return RecipeAdded(
      outcomes: await _repo.addAll(requests),
      skipped: skipped,
    );
  }

  Future<void> toggle(ShoppingItem item) =>
      _repo.setDone(item.id, done: !item.done);

  Future<void> remove(ShoppingItem item) => _repo.remove(item.id);

  /// "Clear all": removes the Done items and offers Undo for 8 seconds.
  Future<void> clearDone() async {
    final cleared = await _repo.clearDone();
    if (cleared.isEmpty) return;
    _undoTimer?.cancel();
    _undoTimer = Timer(ref.read(undoWindowProvider), () => state = null);
    state = ClearUndo(cleared);
  }

  /// Brings the cleared items back, while the offer lasts.
  Future<void> undoClear() async {
    final offer = state;
    if (offer == null) return;
    _undoTimer?.cancel();
    state = null;
    await _repo.restore(offer.cleared);
  }

  void dismissUndo() {
    _undoTimer?.cancel();
    state = null;
  }
}

final shoppingControllerProvider =
    NotifierProvider<ShoppingController, ClearUndo?>(ShoppingController.new);
