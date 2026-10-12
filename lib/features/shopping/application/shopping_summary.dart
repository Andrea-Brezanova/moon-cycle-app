import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What Home and Foods show about the shopping list.
final class ShoppingSummary {
  const ShoppingSummary({
    required this.toBuy,
    required this.done,
    required this.fromRecipes,
    required this.onListFoodIds,
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

  /// Catalogue foods that are in To buy (the "on your list" marks).
  final Set<String> onListFoodIds;
}

/// Filled from the shopping list in Milestone 9.
final shoppingSummaryProvider = Provider<ShoppingSummary>(
  (ref) => ShoppingSummary.empty,
);
