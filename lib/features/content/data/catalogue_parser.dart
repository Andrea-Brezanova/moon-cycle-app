import '../../../core/domain/phase.dart';
import '../domain/catalogue.dart';
import '../domain/food.dart';
import '../domain/phase_content.dart';
import '../domain/recipe.dart';

/// Builds the [Catalogue] from the decoded `assets/content/*.json` files.
///
/// Strict: an unknown id or a missing field throws a [FormatException], so a
/// content mistake fails the validation test instead of reaching a user.
/// Foods with `shipReady: false` are left out entirely.
Catalogue parseCatalogue({
  required Map<String, Object?> taxonomy,
  required Map<String, Object?> phases,
  required Map<String, Object?> foods,
  required Map<String, Object?> recipes,
}) {
  final categories = [
    for (final c in _list(taxonomy, 'categories'))
      FoodCategory(id: _str(c, 'id'), name: _str(c, 'name')),
  ];
  final aisles = [
    for (final a in _list(taxonomy, 'aisles'))
      Aisle(id: _str(a, 'id'), name: _str(a, 'name')),
  ];
  final allergens = [
    for (final a in _list(taxonomy, 'allergens'))
      Allergen(id: _str(a, 'id'), label: _str(a, 'label')),
  ];
  final aisleIds = {for (final a in aisles) a.id};
  final categoryIds = {for (final c in categories) c.id};
  final allergenIds = {for (final a in allergens) a.id};

  final foodsById = <String, Food>{};
  for (final f in _list(foods, 'foods')) {
    if (f['shipReady'] != true) continue;
    final id = _str(f, 'id');
    final why = _map(f, 'why');
    final food = Food(
      id: id,
      name: _str(f, 'name'),
      aisleId: _known(_str(f, 'aisle'), aisleIds, 'aisle', id),
      categoryId: _known(_str(f, 'category'), categoryIds, 'category', id),
      animalSource: AnimalSource.values.byName(_str(f, 'animalSource')),
      allergenIds: {
        for (final a in _strings(f, 'allergens'))
          _known(a, allergenIds, 'allergen', id),
      },
      mayContainAllergenIds: {
        for (final a in _strings(f, 'mayContainAllergens'))
          _known(a, allergenIds, 'allergen', id),
      },
      synonyms: _strings(f, 'synonyms'),
      cautions: _strings(f, 'cautions'),
      why: {
        for (final MapEntry(:key, :value) in why.entries)
          Phase.values.byName(key): FoodWhy(
            short: _str(value! as Map<String, Object?>, 'short'),
            detail: _str(value as Map<String, Object?>, 'detail'),
          ),
      },
    );
    if (foodsById.containsKey(id)) throw FormatException('Duplicate food $id');
    foodsById[id] = food;
  }

  final categoriesById = {for (final c in categories) c.id: c};
  final phaseContents = <Phase, PhaseContent>{};
  for (final p in _list(phases, 'phases')) {
    final phase = Phase.values.byName(_str(p, 'id'));
    phaseContents[phase] = PhaseContent(
      phase: phase,
      name: _str(p, 'name'),
      season: _str(p, 'season'),
      tagline: _str(p, 'tagline'),
      summary: _str(p, 'summary'),
      focusBody: _str(p, 'focusBody'),
      cooking: _str(p, 'cooking'),
      note: _str(p, 'note'),
      categories: [
        for (final c in _list(p, 'categories'))
          PhaseCategory(
            category:
                categoriesById[_str(c, 'category')] ??
                (throw FormatException('Unknown category in ${phase.name}')),
            // Not-ship-ready foods stay in the file but never in the app.
            foodIds: [
              for (final id in _strings(c, 'foods'))
                if (foodsById.containsKey(id)) id,
            ],
          ),
      ],
    );
  }
  if (phaseContents.length != Phase.values.length) {
    throw const FormatException('Every phase needs its content');
  }

  final recipeList = <Recipe>[];
  for (final r in _list(recipes, 'recipes')) {
    final id = _str(r, 'id');
    String food(String foodId) => foodsById.containsKey(foodId)
        ? foodId
        : throw FormatException('Recipe $id uses unknown food $foodId');
    recipeList.add(
      Recipe(
        id: id,
        title: _str(r, 'title'),
        phase: Phase.values.byName(_str(r, 'phase')),
        category: RecipeCategory.values.byName(_str(r, 'category')),
        minutes: _int(r, 'minutes'),
        serves: _int(r, 'serves'),
        intro: _str(r, 'intro'),
        whyThisPhase: _str(r, 'whyThisPhase'),
        imageUrl: (r['image'] as Map<String, Object?>?)?['url'] as String?,
        keyFoodIds: [for (final f in _strings(r, 'keyFoods')) food(f)],
        ingredients: [
          for (final l in _list(r, 'ingredients'))
            RecipeIngredient(
              label: _str(l, 'label'),
              foodId: l['food'] == null ? null : food(l['food']! as String),
              amount: (l['amount'] as num?)?.toDouble(),
              unit: l['unit'] as String?,
              qtyText: l['qtyText'] as String?,
              metric: l['metric'] as String?,
              aisleId: l['food'] != null
                  ? foodsById[l['food']]!.aisleId
                  : _known(_str(l, 'aisle'), aisleIds, 'aisle', id),
              extraAllergenIds: {
                for (final a in _strings(l, 'allergens'))
                  _known(a, allergenIds, 'allergen', id),
              },
            ),
        ],
        steps: _strings(r, 'steps'),
      ),
    );
  }

  return Catalogue(
    categories: categories,
    aisles: aisles,
    allergens: allergens,
    sheetLabel: _str(taxonomy, 'sheetLabel'),
    phases: phaseContents,
    foodsById: foodsById,
    recipes: recipeList,
  );
}

String _str(Map<String, Object?> json, String key) => switch (json[key]) {
  final String s => s,
  _ => throw FormatException('Missing text "$key"', json.toString()),
};

int _int(Map<String, Object?> json, String key) => switch (json[key]) {
  final int i => i,
  _ => throw FormatException('Missing number "$key"', json.toString()),
};

Map<String, Object?> _map(Map<String, Object?> json, String key) =>
    (json[key] as Map<String, Object?>?) ?? const {};

List<Map<String, Object?>> _list(Map<String, Object?> json, String key) => [
  for (final item in (json[key] as List<Object?>?) ?? const [])
    item! as Map<String, Object?>,
];

List<String> _strings(Map<String, Object?> json, String key) => [
  for (final item in (json[key] as List<Object?>?) ?? const []) item! as String,
];

String _known(String value, Set<String> known, String what, String owner) =>
    known.contains(value)
    ? value
    : throw FormatException('$owner: unknown $what "$value"');
