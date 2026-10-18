import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';
import 'generated_recipe.dart';
import 'generation_request.dart';

/// Why a generated recipe was refused.
enum IssueCode {
  schema,
  length,
  range,
  unknownFood,
  unit,
  amount,
  pantryLine,
  missingSelection,
  extraAnimalProduct,
  dietOrAllergen,
  bannedClaim,
  foodSafety,
  duplicateIngredient,
}

final class ValidationIssue {
  const ValidationIssue(this.code, this.message);

  final IssueCode code;

  /// For logs and for the repair prompt. Never shown to users verbatim.
  final String message;

  @override
  String toString() => '${code.name}: $message';
}

final class ValidationReport {
  const ValidationReport(this.issues);

  final List<ValidationIssue> issues;

  bool get isValid => issues.isEmpty;

  @override
  String toString() => issues.isEmpty ? 'valid' : issues.join('; ');
}

/// Deterministic checks every generated recipe must pass before it reaches the
/// user. The checks are code, not a second model: allergens and diet are
/// derived from the linked foods with the app's own [FoodFilter], never from
/// what the generator claims.
///
/// The same rules are implemented in the backend (`supabase/functions/_shared`)
/// and both are run against the shared fixtures in `test/fixtures/generation`.
final class RecipeValidator {
  const RecipeValidator(this.catalogue);

  final Catalogue catalogue;

  static const minSteps = 3;
  static const maxSteps = 5;
  static const minIngredients = 4;
  static const maxIngredients = 16;

  /// Claims the app does not make (hormones, treatment, symptoms, "boosting").
  /// The union of the two lists the content tests use, plus a few more that
  /// generated text could reach for.
  static final bannedClaims = RegExp(
    r'hormon|estrogen|oestrogen|progesterone|fertil|detox|regulat|prevent|'
    r'\btreat|\bcure|\bfix\b|deficien|\bpms\b|cramp|symptom|scientific|'
    r'proven|science|clinical|boost|\bheal(s|ing)?\b|inflammat|immun|'
    r'superfood|weight loss|lose weight|anti-?oxidant|cleanse|balance your',
    caseSensitive: false,
  );

  /// Pantry lines that need no catalogue food: oils, seasoning, spices, stock.
  static final pantryLine = RegExp(
    r'\b(salt|pepper|cumin|paprika|cinnamon|chil+i|curry|thyme|oregano|'
    r'turmeric|coriander|cardamom|nutmeg|ginger powder|garlic powder|'
    r'onion powder|vanilla|stock|bouillon|baking powder|oil|vinegar|water|'
    r'mustard|soy sauce|tamari|spice|spices|seasoning)\b',
    caseSensitive: false,
  );

  // Foods that must be cooked, and how the recipe must say so.
  static const _poultryPork = {
    'chicken', 'turkey', 'duck', 'pork', 'bacon', //
  };
  static const _otherMeat = {'beef', 'lamb'};
  static const _shellfish = {
    'shrimp', 'clam', 'crab', 'lobster', 'mussel', 'oyster', 'scallop', //
    'squid', 'octopus',
  };
  static final _cookVerb = RegExp(
    r'\b(cook|bake|roast|simmer|boil|fry|sear|grill|poach|steam|saut[eé]|'
    r'stir-fry|braise|heat|scramble)',
    caseSensitive: false,
  );
  static final _cookedThrough = RegExp(
    r'cooked through|no longer pink|until (it|they) (is|are) (cooked|done)|'
    r'\b(165|74|71|160)\s?(°|degrees|f\b|c\b)|juices run clear|piping hot|'
    r'steaming hot|until (cooked|done|golden)',
    caseSensitive: false,
  );
  static final _rawOnly = RegExp(
    r'\bserve (it |them )?raw\b|\buncooked (chicken|turkey|duck|pork|egg)|'
    r'\bundercooked\b|\braw (chicken|turkey|duck|pork|egg)s?\b|\brunny\b',
    caseSensitive: false,
  );

  ValidationReport validate(
    GeneratedRecipe recipe,
    GenerationRequest request,
    FoodFilter filter,
  ) {
    final issues = <ValidationIssue>[];
    void add(IssueCode code, String message) =>
        issues.add(ValidationIssue(code, message));

    // Lengths and ranges.
    void length(String what, String text, int min, int max) {
      final n = text.trim().length;
      if (n < min || n > max) {
        add(IssueCode.length, '$what is $n characters (allowed $min–$max)');
      }
    }

    length('title', recipe.title, 3, 80);
    length('intro', recipe.intro, 10, 400);
    if (recipe.minutes < 5 || recipe.minutes > 180) {
      add(IssueCode.range, 'minutes ${recipe.minutes} (allowed 5–180)');
    }
    if (recipe.serves < 1 || recipe.serves > 8) {
      add(IssueCode.range, 'serves ${recipe.serves} (allowed 1–8)');
    }
    if (recipe.steps.length < minSteps || recipe.steps.length > maxSteps) {
      add(
        IssueCode.range,
        '${recipe.steps.length} steps (allowed $minSteps–$maxSteps)',
      );
    }
    for (final (i, step) in recipe.steps.indexed) {
      length('step ${i + 1}', step, 10, 400);
    }
    if (recipe.ingredients.length < minIngredients ||
        recipe.ingredients.length > maxIngredients) {
      add(
        IssueCode.range,
        '${recipe.ingredients.length} ingredients '
        '(allowed $minIngredients–$maxIngredients)',
      );
    }

    // Ingredient lines.
    final foods = <Food>[];
    final seen = <String>{};
    for (final line in recipe.ingredients) {
      length('ingredient label', line.label, 2, 80);
      final id = line.foodId;
      if (id == null) {
        if (!pantryLine.hasMatch(line.label)) {
          add(
            IssueCode.pantryLine,
            '"${line.label}" is neither a catalogue food nor a pantry line',
          );
        }
      } else {
        final food = catalogue.food(id);
        if (food == null) {
          add(IssueCode.unknownFood, 'unknown food "$id"');
        } else {
          foods.add(food);
          if (!seen.add(id)) {
            add(IssueCode.duplicateIngredient, '"$id" appears twice');
          }
        }
      }
      final unit = line.unit;
      if (unit != null && !allowedUnits.contains(unit)) {
        add(IssueCode.unit, 'unit "$unit" is not allowed');
      }
      final amount = line.amount;
      if (amount != null) {
        if (!amount.isFinite || amount <= 0 || amount > _maxAmount(unit)) {
          add(IssueCode.amount, '"${line.label}": $amount ${unit ?? ''}');
        }
        if (unit == null) {
          add(IssueCode.unit, '"${line.label}" has an amount but no unit');
        }
      } else if (line.qtyText == null || line.qtyText!.trim().isEmpty) {
        add(IssueCode.amount, '"${line.label}" has no quantity');
      }
    }

    // The chosen foods all appear, as catalogue lines.
    final used = {for (final f in foods) f.id};
    for (final id in request.foodIds) {
      if (!used.contains(id)) {
        add(IssueCode.missingSelection, 'the chosen food "$id" is missing');
      }
    }

    // No animal product the user did not choose.
    final chosen = request.foodIds.toSet();
    for (final f in foods) {
      if (chosen.contains(f.id)) continue;
      if (f.animalSource != AnimalSource.none &&
          f.animalSource != AnimalSource.honey) {
        add(
          IssueCode.extraAnimalProduct,
          '"${f.id}" (${f.animalSource.name}) was not chosen',
        );
      }
    }

    // Diet and allergens, from the linked foods and the app's own filter.
    final asRecipe = Recipe(
      id: 'check',
      title: recipe.title,
      phase: request.phase,
      category: recipe.category,
      minutes: recipe.minutes,
      serves: recipe.serves,
      intro: recipe.intro,
      whyThisPhase: '',
      keyFoodIds: request.foodIds,
      ingredients: [
        for (final l in recipe.ingredients)
          RecipeIngredient(
            label: l.label,
            foodId: l.foodId != null && catalogue.food(l.foodId!) != null
                ? l.foodId
                : null,
            aisleId: 'pantry',
          ),
      ],
      steps: recipe.steps,
    );
    if (!filter.allowsRecipe(asRecipe, catalogue)) {
      final avoided = [
        for (final l in filter.avoidedLines(asRecipe, catalogue)) l.label,
      ];
      add(
        IssueCode.dietOrAllergen,
        'conflicts with the user\'s diet or avoidances'
        '${avoided.isEmpty ? '' : ': ${avoided.join(', ')}'}',
      );
    }

    // Claims.
    final text = [
      recipe.title,
      recipe.intro,
      ...recipe.steps,
      for (final l in recipe.ingredients) l.label,
    ].join('\n');
    final claim = bannedClaims.firstMatch(text);
    if (claim != null) {
      add(IssueCode.bannedClaim, 'contains "${claim.group(0)}"');
    }

    // Food safety.
    final steps = recipe.steps.join('\n');
    final ids = used;
    final needsCooking = ids.any(
      (id) =>
          _poultryPork.contains(id) ||
          _otherMeat.contains(id) ||
          _shellfish.contains(id) ||
          id == 'eggs',
    );
    if (needsCooking && !_cookVerb.hasMatch(steps)) {
      add(IssueCode.foodSafety, 'meat, eggs or shellfish with no cooking step');
    }
    if (ids.any(_poultryPork.contains) && !_cookedThrough.hasMatch(steps)) {
      add(
        IssueCode.foodSafety,
        'poultry or pork without "cooked through" wording',
      );
    }
    if (ids.contains('kidney-bean')) {
      final line = recipe.ingredients
          .where((l) => l.foodId == 'kidney-bean')
          .map((l) => l.label)
          .join(' ');
      final canned = RegExp(
        r'canned|tinned|cooked',
        caseSensitive: false,
      ).hasMatch(line);
      if (!canned && !RegExp(r'\bboil', caseSensitive: false).hasMatch(steps)) {
        add(IssueCode.foodSafety, 'kidney beans must be canned or boiled');
      }
    }
    if (_rawOnly.hasMatch(steps)) {
      add(IssueCode.foodSafety, 'raw or undercooked instruction');
    }

    return ValidationReport(issues);
  }

  /// Largest sensible amount of one line, by unit.
  static double _maxAmount(String? unit) => switch (unit) {
    'g' => 1500,
    'kg' => 3,
    'ml' => 1500,
    'l' => 3,
    'tsp' => 12,
    'tbsp' => 12,
    'cup' => 8,
    'oz' => 48,
    'lb' => 4,
    'pinch' => 4,
    'can' || 'jar' => 4,
    'clove' || 'fillet' || 'thumb' || 'head' || 'bunch' => 10,
    'handful' => 6,
    _ => 20,
  };
}
