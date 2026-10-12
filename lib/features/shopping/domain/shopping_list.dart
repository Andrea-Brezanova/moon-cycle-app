import 'shopping_item.dart';

/// To buy, grouped by aisle in the fixed order; empty aisles are left out
/// (plan §9.2). Items keep the order they were added in.
List<(String aisleId, List<ShoppingItem> items)> toBuyByAisle(
  List<ShoppingItem> items,
  List<String> aisleOrder,
) => [
  for (final aisle in aisleOrder)
    if (items.where((i) => !i.done && i.aisleId == aisle).toList()
        case final inAisle when inAisle.isNotEmpty)
      (aisle, inAisle),
];

/// Done, most recently checked first.
List<ShoppingItem> doneItems(List<ShoppingItem> items) =>
    items.where((i) => i.done).toList()..sort(
      (a, b) => (b.doneAt ?? b.createdAt).compareTo(a.doneAt ?? a.createdAt),
    );
