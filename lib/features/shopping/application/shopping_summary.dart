import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shopping_repository.dart';
import '../domain/shopping_item.dart';

/// The shopping list as it is stored, oldest first.
final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchItems(),
);

/// What Home and Foods show about the shopping list.
final class ShoppingSummary {
  const ShoppingSummary({
    required this.toBuy,
    required this.done,
    required this.fromRecipes,
    required this.onListFoodIds,
    this.onListKeys = const {},
  });

  static const empty = ShoppingSummary(
    toBuy: 0,
    done: 0,
    fromRecipes: 0,
    onListFoodIds: {},
  );

  final int toBuy;
  final int done;

  /// To-buy items with at least one recipe source.
  final int fromRecipes;

  /// Catalogue foods in To buy (the "on your list" marks and chips).
  final Set<String> onListFoodIds;

  /// Keys of the To-buy items, for things that aren't catalogue foods
  /// (a recipe's olive oil).
  final Set<String> onListKeys;
}

final shoppingSummaryProvider = Provider<ShoppingSummary>((ref) {
  final items = ref.watch(shoppingItemsProvider).value;
  if (items == null) return ShoppingSummary.empty;
  final toBuy = [
    for (final i in items)
      if (!i.done) i,
  ];
  return ShoppingSummary(
    toBuy: toBuy.length,
    done: items.length - toBuy.length,
    fromRecipes: toBuy.where((i) => i.hasRecipeSource).length,
    onListFoodIds: {
      for (final i in toBuy)
        if (i.foodId != null) i.foodId!,
    },
    onListKeys: {for (final i in toBuy) i.key},
  );
});
