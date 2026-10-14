import '../../../core/domain/phase.dart';

/// The stored recipe categories. Lunch and dinner are shown as "Meals".
enum RecipeCategory {
  breakfast(MealType.breakfast),
  lunch(MealType.meals),
  dinner(MealType.meals),
  snack(MealType.snacks);

  const RecipeCategory(this.mealType);

  final MealType mealType;
}

/// The meal tabs on Recipes.
enum MealType {
  breakfast('Breakfast'),
  meals('Meals'),
  snacks('Snacks');

  const MealType(this.label);

  final String label;
}

final class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.phase,
    required this.category,
    required this.minutes,
    required this.serves,
    required this.intro,
    required this.whyThisPhase,
    this.imageUrl,
    required this.keyFoodIds,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;
  final Phase phase;
  final RecipeCategory category;
  final int minutes;
  final int serves;
  final String intro;

  /// One conservative sentence on why the recipe suits its phase's meal
  /// style ("Why this recipe?" on the detail screen).
  final String whyThisPhase;
  final String? imageUrl;

  /// The key ingredients: they drive "Cook with…" and the recipe counts.
  final List<String> keyFoodIds;

  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  MealType get mealType => category.mealType;

  @override
  String toString() => 'Recipe($id)';
}

/// One line of a recipe's ingredient list ("150 g green lentils").
final class RecipeIngredient {
  const RecipeIngredient({
    required this.label,
    this.foodId,
    this.amount,
    this.unit,
    this.qtyText,
    this.metric,
    required this.aisleId,
    this.extraAllergenIds = const {},
  });

  final String label;

  /// The catalogue food, or null for a line like "Olive oil".
  final String? foodId;

  final double? amount;

  /// "g", "tbsp", "piece", "handful"…; null when there's no amount.
  final String? unit;

  /// A quantity in words ("to serve").
  final String? qtyText;

  /// Display-only metric companion to the US [amount]/[unit] ("170 g",
  /// "14 oz / 400 g"). Never used for shopping-list totals.
  final String? metric;

  /// Its food's aisle, or the line's own for non-catalogue lines.
  final String aisleId;

  /// Allergens of this line beyond its food's (e.g. buckwheat noodles may
  /// contain gluten although buckwheat doesn't).
  final Set<String> extraAllergenIds;

  /// "150 g", "2", "1 tbsp", "2 cups (480 ml)", "1 can (14 oz / 400 g)",
  /// "to serve" (a unit of "piece" shows the number alone; spec §9). Plural
  /// grammar is display-only: the stored unit is never changed.
  String get quantityLabel {
    if (amount == null) return qtyText ?? '';
    final number = formatAmount(amount!);
    final base = unit == null || unit == 'piece'
        ? number
        : '$number ${_displayUnit(unit!, amount!)}';
    return metric == null ? base : '$base ($metric)';
  }
}

const _plurals = {
  'cup': 'cups',
  'can': 'cans',
  'jar': 'jars',
  'fillet': 'fillets',
  'clove': 'cloves',
  'bunch': 'bunches',
  'head': 'heads',
  'handful': 'handfuls',
};

String _displayUnit(String unit, double amount) =>
    amount > 1 ? (_plurals[unit] ?? unit) : unit;

/// 2.0 → "2", 0.5 → "½", 1.5 → "1½", 0.25 → "¼", 1.2 → "1.2".
String formatAmount(double amount) {
  final whole = amount.truncate();
  final fraction = amount - whole;
  const fractions = [(0.25, '¼'), (0.5, '½'), (0.75, '¾')];
  for (final (value, glyph) in fractions) {
    if ((fraction - value).abs() < 0.001) {
      return whole == 0 ? glyph : '$whole$glyph';
    }
  }
  if (fraction.abs() < 0.001) return '$whole';
  return amount.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
