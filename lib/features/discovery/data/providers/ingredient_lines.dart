import '../../../content/domain/recipe.dart';
import '../../domain/ingredient_mapper.dart';
import '../../domain/ingredient_vocabulary.dart';

/// One external ingredient line as the app's [RecipeIngredient], using what the
/// mapper reliably knows: a Moon Cycle food id, or known allergens and animal
/// source, or nothing (which later makes a recipe unsafe for restricted users).
RecipeIngredient ingredientLine(
  IngredientMapper mapper,
  String name, {
  String? quantity,
}) {
  final label = '${name[0].toUpperCase()}${name.substring(1)}';
  final c = mapper.classify(name);
  return switch (c.kind) {
    IngredientKind.food => RecipeIngredient(
      label: label,
      foodId: c.food!.id,
      qtyText: quantity,
      aisleId: c.food!.aisleId,
      extraAllergenIds:
          IngredientVocabulary.allergenOverrides[c.food!.id] ?? const {},
    ),
    IngredientKind.derived => RecipeIngredient(
      label: label,
      qtyText: quantity,
      aisleId: c.derived!.aisle,
      extraAllergenIds: c.derived!.allergens,
      extraAnimalSource: c.derived!.animal,
    ),
    IngredientKind.pantrySafe => RecipeIngredient(
      label: label,
      qtyText: quantity,
      aisleId: 'pantry',
    ),
    _ => RecipeIngredient(label: label, qtyText: quantity, aisleId: 'other'),
  };
}
