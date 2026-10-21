import '../../../core/domain/phase.dart';
import 'food.dart';
import 'phase_content.dart';
import 'recipe.dart';
import 'text_match.dart';

/// Everything the app knows about foods, phases and recipes. Read-only.
///
/// Only shippable foods are in it: foods with `shipReady: false` never reach
/// the app.
final class Catalogue {
  Catalogue({
    required this.categories,
    required this.aisles,
    required this.allergens,
    required this.sheetLabel,
    required this.phases,
    required this.foodsById,
    required this.recipes,
  });

  /// Food categories in the stored order.
  final List<FoodCategory> categories;

  /// In the Shop order.
  final List<Aisle> aisles;

  /// In the order of the allergen chips.
  final List<Allergen> allergens;

  /// "Recommended for your {phase} phase".
  final String sheetLabel;

  final Map<Phase, PhaseContent> phases;

  /// Shippable foods by id.
  final Map<String, Food> foodsById;

  /// Every recipe, in the stored order.
  final List<Recipe> recipes;

  Iterable<Food> get foods => foodsById.values;

  PhaseContent phase(Phase phase) => phases[phase]!;

  Food? food(String id) => foodsById[id];

  Recipe? recipe(String id) {
    for (final r in recipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  Aisle aisle(String id) => aisles.firstWhere((a) => a.id == id);

  /// The foods recommended for [phase], in the stored order.
  List<Food> foodsFor(Phase phase) => [
    for (final id in phases[phase]!.foodIds) foodsById[id]!,
  ];

  /// The category [foodId] is placed in for [phase] ("Meat").
  FoodCategory? categoryOf(String foodId, Phase phase) {
    for (final c in phases[phase]!.categories) {
      if (c.foodIds.contains(foodId)) return c.category;
    }
    return null;
  }

  /// The category [food] belongs to: its own canonical `category`, independent
  /// of the phase being viewed and of whether any phase features it.
  FoodCategory categoryFor(Food food) =>
      categories.firstWhere((c) => c.id == food.categoryId);

  /// The recipes of [phase], in the stored order (the first is featured).
  List<Recipe> recipesFor(Phase phase) => [
    for (final r in recipes)
      if (r.phase == phase) r,
  ];

  /// The catalogue food a typed name refers to, by name or synonym
  /// ("Courgette" → Zucchini). No plural guessing (plan §9.1).
  Food? foodNamed(String text) {
    final wanted = normaliseName(text);
    if (wanted.isEmpty) return null;
    for (final food in foodsById.values) {
      if (normaliseName(food.displayName) == wanted ||
          normaliseName(food.name) == wanted ||
          food.synonyms.any((s) => normaliseName(s) == wanted)) {
        return food;
      }
    }
    return null;
  }
}
