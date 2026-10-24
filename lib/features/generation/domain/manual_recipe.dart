import '../../../core/domain/phase.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../content/domain/text_match.dart';

/// What the user typed into "Add a recipe".
final class ManualRecipeInput {
  const ManualRecipeInput({
    required this.title,
    required this.category,
    this.minutes,
    this.serves,
    this.notes = '',
    this.ingredientsText = '',
    this.stepsText = '',
  });

  final String title;
  final RecipeCategory category;
  final int? minutes;
  final int? serves;

  /// A line or two about the recipe (shown as its introduction).
  final String notes;

  /// One ingredient per line.
  final String ingredientsText;

  /// One step per line.
  final String stepsText;

  /// Why the recipe can't be saved yet, or null when it can.
  String? get problem {
    if (title.trim().isEmpty) return 'Give the recipe a name.';
    if (splitLines(ingredientsText).isEmpty && splitLines(stepsText).isEmpty) {
      return 'Add at least one ingredient or one step.';
    }
    return null;
  }
}

/// The non-empty lines of [text], trimmed, without a leading bullet or number
/// ("- 2 eggs", "1. Whisk", "• salt").
List<String> splitLines(String text) => [
  for (final raw in text.split(RegExp(r'\r?\n')))
    if (_clean(raw).isNotEmpty) _clean(raw),
];

String _clean(String line) =>
    line.trim().replaceFirst(RegExp(r'^([-*•–—]|\d{1,2}[.)])\s+'), '').trim();

/// The longest catalogue food named in [line] ("green lentils" over "lentil"),
/// or null when none is.
Food? matchFood(String line, Iterable<Food> foods) {
  Food? best;
  var bestLength = 0;
  for (final food in foods) {
    for (final name in [food.name, ...food.synonyms]) {
      if (name.length > bestLength && containsPhrase(line, name)) {
        best = food;
        bestLength = name.length;
      }
    }
  }
  return best;
}

/// The recipe for [input]: ingredient lines kept as written, matched to
/// catalogue foods where a name is recognised (so aisles and food preferences
/// can apply to those lines). Unmatched lines can't be checked. Time and
/// servings left empty are stored as 0 (and not shown); no phase claim is
/// made: [phase] only colours the card.
Recipe buildManualRecipe({
  required String id,
  required ManualRecipeInput input,
  required Phase phase,
  required Iterable<Food> foods,
}) {
  final lines = splitLines(input.ingredientsText);
  final matched = [for (final l in lines) matchFood(l, foods)];
  final keyIds = <String>[];
  for (final f in matched) {
    if (f != null && !keyIds.contains(f.id)) keyIds.add(f.id);
  }
  return Recipe(
    id: id,
    title: input.title.trim(),
    phase: phase,
    category: input.category,
    minutes: input.minutes ?? 0,
    serves: input.serves ?? 0,
    intro: input.notes.trim(),
    whyThisPhase: '',
    keyFoodIds: keyIds.take(3).toList(),
    ingredients: [
      for (final (i, l) in lines.indexed)
        RecipeIngredient(
          label: l,
          foodId: matched[i]?.id,
          aisleId: matched[i]?.aisleId ?? 'other',
        ),
    ],
    steps: splitLines(input.stepsText),
  );
}

/// The text to start the editor with, from a saved recipe.
ManualRecipeInput inputFromRecipe(Recipe r) => ManualRecipeInput(
  title: r.title,
  category: r.category,
  minutes: r.minutes == 0 ? null : r.minutes,
  serves: r.serves == 0 ? null : r.serves,
  notes: r.intro,
  ingredientsText: r.ingredients.map((i) => i.label).join('\n'),
  stepsText: r.steps.join('\n'),
);
