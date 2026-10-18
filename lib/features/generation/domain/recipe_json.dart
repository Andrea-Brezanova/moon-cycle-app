import '../../../core/domain/phase.dart';
import '../../content/domain/recipe.dart';

/// A [Recipe] as plain JSON, for storing personal recipes on the phone.
Map<String, Object?> recipeToJson(Recipe r) => {
  'id': r.id,
  'title': r.title,
  'phase': r.phase.name,
  'category': r.category.name,
  'minutes': r.minutes,
  'serves': r.serves,
  'intro': r.intro,
  'why_this_phase': r.whyThisPhase,
  'key_food_ids': r.keyFoodIds,
  'ingredients': [
    for (final l in r.ingredients)
      {
        'label': l.label,
        'food_id': l.foodId,
        'amount': l.amount,
        'unit': l.unit,
        'qty_text': l.qtyText,
        'metric': l.metric,
        'aisle_id': l.aisleId,
        'extra_allergen_ids': l.extraAllergenIds.toList()..sort(),
      },
  ],
  'steps': r.steps,
};

Recipe recipeFromJson(Map<String, Object?> j) => Recipe(
  id: j['id']! as String,
  title: j['title']! as String,
  phase: Phase.values.byName(j['phase']! as String),
  category: RecipeCategory.values.byName(j['category']! as String),
  minutes: j['minutes']! as int,
  serves: j['serves']! as int,
  intro: j['intro']! as String,
  whyThisPhase: j['why_this_phase']! as String,
  keyFoodIds: (j['key_food_ids']! as List<Object?>).cast<String>(),
  ingredients: [
    for (final line in (j['ingredients']! as List<Object?>))
      _line(line! as Map<String, Object?>),
  ],
  steps: (j['steps']! as List<Object?>).cast<String>(),
);

RecipeIngredient _line(Map<String, Object?> l) => RecipeIngredient(
  label: l['label']! as String,
  foodId: l['food_id'] as String?,
  amount: (l['amount'] as num?)?.toDouble(),
  unit: l['unit'] as String?,
  qtyText: l['qty_text'] as String?,
  metric: l['metric'] as String?,
  aisleId: l['aisle_id']! as String,
  extraAllergenIds: ((l['extra_allergen_ids'] as List<Object?>?) ?? const [])
      .cast<String>()
      .toSet(),
);
