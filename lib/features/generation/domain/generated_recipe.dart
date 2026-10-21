import '../../content/domain/catalogue.dart';
import '../../content/domain/recipe.dart';
import 'generation_request.dart';

/// Version of the structured recipe schema; the backend returns the same one.
const generatedRecipeSchemaVersion = 1;

/// Units a generated ingredient line may use (the app's shopping list totals
/// these; see `displayQuantity`).
const allowedUnits = {
  'g',
  'kg',
  'ml',
  'l',
  'tsp',
  'tbsp',
  'cup',
  'oz',
  'lb',
  'piece',
  'pinch',
  'can',
  'jar',
  'handful',
  'clove',
  'fillet',
  'thumb',
  'head',
  'bunch',
};

/// One ingredient line as returned by a generator. A line is either a
/// catalogue food ([foodId]) or a plain pantry line (salt, a spice, stock) with
/// no [foodId] and the `pantry` aisle.
final class GeneratedIngredient {
  const GeneratedIngredient({
    required this.label,
    this.foodId,
    this.amount,
    this.unit,
    this.qtyText,
  });

  final String label;
  final String? foodId;
  final double? amount;
  final String? unit;
  final String? qtyText;

  factory GeneratedIngredient.fromJson(Map<String, Object?> json) =>
      GeneratedIngredient(
        label: _string(json, 'label'),
        foodId: _optString(json, 'food_id'),
        amount: _optNum(json, 'amount')?.toDouble(),
        unit: _optString(json, 'unit'),
        qtyText: _optString(json, 'qty_text'),
      );

  Map<String, Object?> toJson() => {
    'label': label,
    'food_id': foodId,
    'amount': amount,
    'unit': unit,
    'qty_text': qtyText,
  };
}

/// A recipe as a generator returns it: untrusted until validated.
///
/// Diet and allergens are deliberately **not** part of it: they are derived
/// from the linked foods, never taken from the generator's claims.
final class GeneratedRecipe {
  const GeneratedRecipe({
    required this.title,
    required this.intro,
    required this.category,
    required this.minutes,
    required this.serves,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final String intro;
  final RecipeCategory category;
  final int minutes;
  final int serves;
  final List<GeneratedIngredient> ingredients;
  final List<String> steps;

  /// Parses the structured output. Throws [FormatException] on any shape
  /// problem (the validator reports it as a `schema` issue).
  factory GeneratedRecipe.fromJson(Map<String, Object?> json) {
    final version = json['schema_version'];
    if (version != generatedRecipeSchemaVersion) {
      throw FormatException('Unsupported schema_version: $version');
    }
    final categoryName = _string(json, 'category');
    final category = RecipeCategory.values
        .where((c) => c.name == categoryName)
        .firstOrNull;
    if (category == null) {
      throw FormatException('Unknown category "$categoryName"');
    }
    final ingredients = json['ingredients'];
    final steps = json['steps'];
    if (ingredients is! List<Object?> || steps is! List<Object?>) {
      throw const FormatException('ingredients and steps must be lists');
    }
    return GeneratedRecipe(
      title: _string(json, 'title'),
      intro: _string(json, 'intro'),
      category: category,
      minutes: _int(json, 'minutes'),
      serves: _int(json, 'serves'),
      ingredients: [
        for (final i in ingredients)
          if (i is Map<String, Object?>)
            GeneratedIngredient.fromJson(i)
          else
            throw const FormatException('An ingredient must be an object'),
      ],
      steps: [
        for (final s in steps)
          if (s is String)
            s
          else
            throw const FormatException('A step must be text'),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'schema_version': generatedRecipeSchemaVersion,
    'title': title,
    'intro': intro,
    'category': category.name,
    'minutes': minutes,
    'serves': serves,
    'ingredients': [for (final i in ingredients) i.toJson()],
    'steps': steps,
  };

  /// The app's own [Recipe], so every existing screen (detail, shopping,
  /// "Cook with…") works unchanged. Call only after validation.
  ///
  /// The "why" line is built from the user's choices, not from the generator.
  Recipe toRecipe({
    required String id,
    required GenerationRequest request,
    required Catalogue catalogue,
  }) {
    String name(String foodId) =>
        catalogue.food(foodId)?.displayName.toLowerCase() ?? foodId;
    final chosen = [for (final f in request.foodIds) name(f)];
    return Recipe(
      id: id,
      title: title,
      phase: request.phase,
      category: category,
      minutes: minutes,
      serves: serves,
      intro: intro,
      whyThisPhase: 'Made from the foods you chose: ${_join(chosen)}.',
      keyFoodIds: request.foodIds,
      ingredients: [
        for (final line in ingredients)
          RecipeIngredient(
            label: line.label,
            foodId: line.foodId,
            amount: line.amount,
            unit: line.unit,
            qtyText: line.qtyText,
            aisleId: line.foodId == null
                ? 'pantry'
                : catalogue.food(line.foodId!)!.aisleId,
          ),
      ],
      steps: steps,
    );
  }
}

String _join(List<String> items) => items.length < 2
    ? items.join()
    : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';

String _string(Map<String, Object?> json, String key) => switch (json[key]) {
  final String s => s,
  _ => throw FormatException('"$key" must be text'),
};

String? _optString(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      null => null,
      final String s => s,
      _ => throw FormatException('"$key" must be text or null'),
    };

num? _optNum(Map<String, Object?> json, String key) => switch (json[key]) {
  null => null,
  final num n => n,
  _ => throw FormatException('"$key" must be a number or null'),
};

int _int(Map<String, Object?> json, String key) => switch (json[key]) {
  final int i => i,
  _ => throw FormatException('"$key" must be a whole number'),
};
