import '../../content/domain/catalogue.dart';
import '../../content/domain/recipe.dart';
import '../../content/domain/text_match.dart';

/// The key of a catalogue food.
String foodKey(String foodId) => 'food:$foodId';

/// What a typed item is: a catalogue food when its name or a synonym matches
/// ("Courgette" → Zucchini), otherwise free text in the Other aisle. No
/// plural guessing (plan §9.1).
final class TypedItem {
  const TypedItem({
    required this.key,
    this.foodId,
    required this.name,
    required this.aisleId,
  });

  final String key;
  final String? foodId;
  final String name;
  final String aisleId;
}

/// The aisle for things that aren't in the catalogue.
const otherAisle = 'other';

/// Resolves typed text; null for blank text.
TypedItem? resolveTyped(String text, Catalogue catalogue) {
  final normalised = normaliseName(text);
  if (normalised.isEmpty) return null;
  final food = catalogue.foodNamed(text);
  if (food != null) {
    return TypedItem(
      key: foodKey(food.id),
      foodId: food.id,
      name: food.displayName,
      aisleId: food.aisleId,
    );
  }
  final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  return TypedItem(
    key: 'text:$normalised',
    name: '${trimmed[0].toUpperCase()}${trimmed.substring(1)}',
    aisleId: otherAisle,
  );
}

/// The key a recipe line goes on the list under: its food's, or the typed
/// key of its label ("Olive oil" → `text:olive oil`).
String lineKey(RecipeIngredient line, Catalogue catalogue) =>
    line.foodId != null
    ? foodKey(line.foodId!)
    : resolveTyped(line.label, catalogue)!.key;
