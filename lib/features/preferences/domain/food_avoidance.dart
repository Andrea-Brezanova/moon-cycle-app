/// Something the user wants left out of foods and recipes.
sealed class FoodAvoidance {
  const FoodAvoidance({required this.id});

  final String id;
}

/// A common allergen, e.g. `peanut` (ids from the content catalogue).
final class AllergenAvoidance extends FoodAvoidance {
  const AllergenAvoidance({required super.id, required this.allergenId});

  final String allergenId;

  @override
  bool operator ==(Object other) =>
      other is AllergenAvoidance &&
      other.id == id &&
      other.allergenId == allergenId;

  @override
  int get hashCode => Object.hash(id, allergenId);
}

/// One catalogue food, e.g. `cilantro`.
final class FoodItemAvoidance extends FoodAvoidance {
  const FoodItemAvoidance({required super.id, required this.foodId});

  final String foodId;

  @override
  bool operator ==(Object other) =>
      other is FoodItemAvoidance && other.id == id && other.foodId == foodId;

  @override
  int get hashCode => Object.hash(id, foodId);
}

/// Something typed with "+ Add another" that isn't in the catalogue. It is
/// matched against food names and synonyms when filtering.
final class CustomAvoidance extends FoodAvoidance {
  const CustomAvoidance({required super.id, required this.label});

  final String label;

  @override
  bool operator ==(Object other) =>
      other is CustomAvoidance && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}
