import '../../../core/domain/phase.dart';

/// Why something is on the list.
enum SourceType {
  /// Added from Foods or a Home chip (a phase's recommended food).
  phaseFood,

  /// Added with a recipe's ingredients.
  recipe,

  /// Typed into the add field.
  manual,
}

/// One reason an item is on the list, with the quantity it asked for.
/// An item's quantity is derived from its sources (plan §8.3), so merging
/// only ever adds a source.
final class ShoppingSource {
  const ShoppingSource({
    required this.id,
    required this.type,
    this.phase,
    this.recipeId,
    this.amount,
    this.unit,
    this.qtyText,
  });

  final String id;
  final SourceType type;
  final Phase? phase;
  final String? recipeId;
  final double? amount;
  final String? unit;
  final String? qtyText;

  /// Two sources with the same identity are the same reason: adding the same
  /// recipe twice never doubles its quantities (plan §9.2).
  bool sameIdentityAs(ShoppingSource other) =>
      type == other.type &&
      switch (type) {
        SourceType.recipe => recipeId == other.recipeId,
        SourceType.phaseFood => phase == other.phase,
        SourceType.manual => true,
      };
}

/// An item on the shopping list.
final class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.key,
    this.foodId,
    required this.name,
    required this.aisleId,
    this.done = false,
    this.doneAt,
    required this.sources,
    required this.createdAt,
  });

  final String id;

  /// `food:<id>` or `text:<normalised name>`: the same key is the same item.
  final String key;
  final String? foodId;
  final String name;
  final String aisleId;
  final bool done;
  final DateTime? doneAt;
  final List<ShoppingSource> sources;
  final DateTime createdAt;

  /// Shows the "Merged" tag: combined from more than one source.
  bool get isMerged => sources.length > 1;

  bool get hasRecipeSource => sources.any((s) => s.type == SourceType.recipe);

  ShoppingItem copyWith({
    bool? done,
    DateTime? doneAt,
    bool clearDoneAt = false,
    List<ShoppingSource>? sources,
  }) => ShoppingItem(
    id: id,
    key: key,
    foodId: foodId,
    name: name,
    aisleId: aisleId,
    done: done ?? this.done,
    doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
    sources: sources ?? this.sources,
    createdAt: createdAt,
  );

  @override
  String toString() => 'ShoppingItem($key${done ? ', done' : ''})';
}
