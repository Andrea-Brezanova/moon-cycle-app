import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/phase_content.dart';

/// For each food, how many of [phase]'s recipes use it as a key ingredient,
/// counting only recipes the user's preferences allow (what Recipes shows).
final recipeCountsProvider = Provider.family<Map<String, int>, Phase>((
  ref,
  phase,
) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final counts = <String, int>{};
  for (final recipe in catalogue.recipesFor(phase)) {
    if (!filter.allowsRecipe(recipe, catalogue)) continue;
    for (final id in recipe.keyFoodIds.toSet()) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
});

/// For each food, how many of all recipes use it as a key ingredient,
/// counting only recipes the user's preferences allow ("All foods").
final allRecipeCountsProvider = Provider<Map<String, int>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final counts = <String, int>{};
  for (final recipe in catalogue.recipes) {
    if (!filter.allowsRecipe(recipe, catalogue)) continue;
    for (final id in recipe.keyFoodIds.toSet()) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
});

/// The whole searchable catalogue grouped by each food's own category (stored
/// category order), foods A–Z within each, whether or not any phase features
/// it. Empty categories are left out; avoided foods are not removed here.
final allFoodsByCategoryProvider = Provider<List<(FoodCategory, List<Food>)>>((
  ref,
) {
  final catalogue = ref.watch(catalogueProvider);
  final byCategory = <String, List<Food>>{};
  for (final food in catalogue.foods) {
    byCategory.putIfAbsent(catalogue.categoryFor(food).id, () => []).add(food);
  }
  return [
    for (final category in catalogue.categories)
      if (byCategory[category.id] case final foods? when foods.isNotEmpty)
        (
          category,
          foods..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          ),
        ),
  ];
});

/// Suggestions for the "Protein ideas" and "Base ideas" in the meal-building
/// guide.
final class FoodIdeas {
  const FoodIdeas({required this.featured, required this.general});

  /// Featured in the viewed phase.
  final List<Food> featured;

  /// Not featured in the viewed phase, but still good to eat: used to keep a
  /// practical choice for every diet. Never presented as less appropriate.
  final List<Food> general;

  bool get isEmpty => featured.isEmpty && general.isEmpty;

  List<Food> get all => [...featured, ...general];
}

/// Kinds of protein source, so a short list can be balanced.
enum ProteinFamily { plant, egg, dairy, meat, seafood, nuts }

/// Foods in the protein categories that are not practical protein ideas
/// (fats, creams, low-protein milks, starchy nuts, processed meats, sugary
/// beans).
const _notFoodIdeas = {
  'butter',
  'cream-cheese',
  'sour-cream',
  'almond-milk',
  'oat-milk',
  'chestnut',
  'bacon',
  'ham',
  'baked-beans',
};

/// How familiar and practical a food is as a meal anchor, most common first.
/// Used only to rank suggestions; unlisted foods come after these. Plant
/// proteins follow the order a cook would reach for them.
const _commonProteins = [
  'eggs',
  'chicken',
  'tofu',
  'tempeh',
  'edamame',
  'green-lentil',
  'red-lentil',
  'chickpea',
  'black-turtle-bean',
  'kidney-bean',
  'seitan',
  'turkey',
  'beef',
  'salmon',
  'canned-tuna',
  'tuna',
  'shrimp',
  'cod',
  'canned-salmon',
  'greek-yogurt',
  'cottage-cheese',
  'plain-yogurt',
  'cheddar',
  'mozzarella',
  'feta',
  'kefir',
  'ricotta',
  'pinto-beans',
  'white-beans',
  'hummus',
  'black-eyed-pea',
  'split-pea',
  'lima-bean',
  'sardine',
  'trout',
  'haddock',
  'pork',
  'almond',
  'peanuts',
  'walnut',
  'cashew',
  'pumpkin-seeds',
  'sunflower-seeds',
  'chia-seeds',
  'flaxseeds',
  'nut-butter',
  'hemp-seeds',
  'pistachio',
];

/// Rich or festive meats that sit awkwardly with the lighter phases' meal
/// style; ranked down there when familiar alternatives exist.
const _heavyMeats = {'duck', 'lamb', 'pork', 'bacon', 'ham'};

/// Near-duplicates: when one is already suggested, skip the other.
const _twins = {'green-lentil': 'red-lentil', 'red-lentil': 'green-lentil'};

/// Ranks [food] for suggestions: lower is better.
int _proteinRank(Food food, Phase phase) {
  if (food.id == 'soy-milk') return 2000;
  var rank = _commonProteins.indexOf(food.id);
  if (rank < 0) rank = 1000;
  final light = phase == Phase.follicular || phase == Phase.ovulatory;
  if (light && _heavyMeats.contains(food.id)) rank += 500;
  return rank;
}

/// The family of [food], or null when it is not a protein idea.
ProteinFamily? proteinFamilyOf(Food food) {
  if (_notFoodIdeas.contains(food.id)) return null;
  return switch (food.categoryId) {
    'protein' =>
      food.animalSource == AnimalSource.egg
          ? ProteinFamily.egg
          : food.animalSource == AnimalSource.meat
          ? ProteinFamily.meat
          : ProteinFamily.plant,
    'legumes' => ProteinFamily.plant,
    'seafood' => ProteinFamily.seafood,
    'dairy-alternatives' =>
      food.animalSource == AnimalSource.dairy
          ? ProteinFamily.dairy
          : food.id == 'soy-milk'
          ? ProteinFamily.plant
          : null,
    'nuts-seeds' => ProteinFamily.nuts,
    _ => null,
  };
}

/// Up to 8 protein ideas for [phase] that respect the user's diet and
/// avoidances. Phase-featured foods come first, then suitable general
/// catalogue foods. The set is balanced across families so one kind never
/// dominates just because a phase features many of it: at most 2 seafood and
/// 2 nuts/seeds, at least one practical plant protein, and an egg and a dairy
/// food where the diet allows. Soy milk ranks below meal-anchor proteins.
final proteinIdeasProvider = Provider.family<FoodIdeas, Phase>((ref, phase) {
  const limit = 8;
  const capByFamily = {
    ProteinFamily.plant: 5,
    ProteinFamily.egg: 1,
    ProteinFamily.dairy: 2,
    ProteinFamily.meat: 2,
    ProteinFamily.seafood: 2,
    ProteinFamily.nuts: 2,
  };
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final featuredIds = catalogue.phase(phase).foodIds.toSet();

  // Eligible foods per family: best first (featured, then common and
  // practical, then catalogue order; soy milk last).
  final byFamily = {for (final fam in ProteinFamily.values) fam: <Food>[]};
  for (final food in catalogue.foods) {
    final fam = proteinFamilyOf(food);
    if (fam == null || !filter.allowsFood(food)) continue;
    byFamily[fam]!.add(food);
  }
  for (final entry in byFamily.entries) {
    final foods = entry.value;
    final order = {for (final (i, f) in foods.indexed) f.id: i};
    foods.sort((a, b) {
      final fa = featuredIds.contains(a.id) ? 0 : 1;
      final fb = featuredIds.contains(b.id) ? 0 : 1;
      if (fa != fb) return fa - fb;
      final r = _proteinRank(a, phase) - _proteinRank(b, phase);
      if (r != 0) return r;
      return order[a.id]! - order[b.id]!;
    });
  }

  final picked = <Food>[];
  final counts = {for (final fam in ProteinFamily.values) fam: 0};
  bool isFeatured(Food f) => featuredIds.contains(f.id);

  // Takes the best not-yet-picked food of [fam] passing [test].
  bool take(ProteinFamily fam, bool Function(Food) test) {
    if (picked.length >= limit || counts[fam]! >= capByFamily[fam]!) {
      return false;
    }
    for (final f in byFamily[fam]!) {
      if (picked.contains(f) || !test(f)) continue;
      // One of each near-duplicate (green and red lentils) is enough.
      final twin = _twins[f.id];
      if (twin != null && picked.any((p) => p.id == twin)) continue;
      // Soy milk only when no meal-anchor plant protein is left to show.
      if (f.id == 'soy-milk' &&
          byFamily[fam]!.any(
            (o) => o.id != 'soy-milk' && !picked.contains(o),
          )) {
        continue;
      }
      picked.add(f);
      counts[fam] = counts[fam]! + 1;
      return true;
    }
    return false;
  }

  // 1. One practical plant protein, an egg and a dairy food, and one meat or
  //    seafood, where compatible; featured foods first.
  for (final fam in [
    ProteinFamily.plant,
    ProteinFamily.egg,
    ProteinFamily.dairy,
    ProteinFamily.meat,
    ProteinFamily.seafood,
  ]) {
    take(fam, isFeatured) || take(fam, (_) => true);
  }
  // 2. Featured foods round-robin across families, then general ones, never
  //    past a family's cap. Nuts and seeds come last as supporting protein.
  const roundRobin = [
    ProteinFamily.plant,
    ProteinFamily.dairy,
    ProteinFamily.meat,
    ProteinFamily.seafood,
    ProteinFamily.egg,
    ProteinFamily.nuts,
  ];
  for (final test in <bool Function(Food)>[isFeatured, (_) => true]) {
    var progressed = true;
    while (picked.length < limit && progressed) {
      progressed = false;
      for (final fam in roundRobin) {
        if (take(fam, test)) progressed = true;
      }
    }
  }

  return FoodIdeas(
    featured: [
      for (final f in picked)
        if (isFeatured(f)) f,
    ],
    general: [
      for (final f in picked)
        if (!isFeatured(f)) f,
    ],
  );
});

/// Base foods that make a satisfying meal base, by familiarity: whole grains
/// and rice, potatoes, bread and pasta, then substantial legumes. Foods not
/// listed (sweetened cereals, snacks, refined flour) are never suggested.
const _baseFamilies = <String, List<String>>{
  'grain': [
    'brown-rice',
    'quinoa',
    'oat',
    'farro',
    'barley',
    'bulgur',
    'buckwheat',
    'millet',
    'wild-rice',
    'white-rice',
    'polenta',
    'couscous',
  ],
  'potato': ['sweet-potato', 'white-potato'],
  'bread': [
    'whole-grain-bread',
    'sourdough-bread',
    'whole-wheat-pasta',
    'tortillas',
    'pita-bread',
    'pasta',
    'soba-noodles',
    'rye-bread',
  ],
  'legume': ['green-lentil', 'chickpea', 'black-turtle-bean', 'kidney-bean'],
};

/// 4–6 "Base ideas" for [phase], respecting diet and avoidances. A phase with
/// no featured grain still gets practical base choices: featured foods come
/// first, then familiar general ones, spread across grains, potatoes, bread or
/// pasta and legumes.
final baseIdeasProvider = Provider.family<FoodIdeas, Phase>((ref, phase) {
  const limit = 6;
  const perFamily = 2;
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  final featuredIds = catalogue.phase(phase).foodIds.toSet();
  bool isFeatured(Food f) => featuredIds.contains(f.id);

  final lanes = <List<Food>>[];
  for (final ids in _baseFamilies.values) {
    final foods = [
      for (final id in ids)
        if (catalogue.food(id) case final f? when filter.allowsFood(f)) f,
    ];
    // Featured first, keeping the familiarity order within each group.
    lanes.add([
      ...foods.where(isFeatured),
      ...foods.where((f) => !isFeatured(f)),
    ]);
  }

  final picked = <Food>[];
  final counts = List.filled(lanes.length, 0);
  bool take(int lane, bool Function(Food) test) {
    if (picked.length >= limit || counts[lane] >= perFamily) return false;
    for (final f in lanes[lane]) {
      if (picked.contains(f) || !test(f)) continue;
      picked.add(f);
      counts[lane]++;
      return true;
    }
    return false;
  }

  // One of each family, featured first; then top up, featured then general.
  for (var i = 0; i < lanes.length; i++) {
    take(i, isFeatured) || take(i, (_) => true);
  }
  for (final test in <bool Function(Food)>[isFeatured, (_) => true]) {
    var progressed = true;
    while (picked.length < limit && progressed) {
      progressed = false;
      for (var i = 0; i < lanes.length; i++) {
        if (take(i, test)) progressed = true;
      }
    }
  }
  return FoodIdeas(
    featured: [
      for (final f in picked)
        if (isFeatured(f)) f,
    ],
    general: [
      for (final f in picked)
        if (!isFeatured(f)) f,
    ],
  );
});

/// Where a food goes in a meal: the protein, the base, or one of the plants.
enum MealSlot {
  protein('Protein'),
  base('Base'),
  plant('Plant');

  const MealSlot(this.label);

  final String label;
}

/// The meal slot [food] belongs in. A protein source (including legumes and
/// nuts, as supporting protein) is a protein; the familiar starches are a
/// base; everything else (vegetables, fruit, herbs) is a plant.
MealSlot mealSlotFor(Food food) {
  if (proteinFamilyOf(food) != null) return MealSlot.protein;
  return isBaseFood(food) ? MealSlot.base : MealSlot.plant;
}

/// Whether [food] is one of the familiar meal bases (whole grains and rice,
/// potatoes, bread and pasta, substantial legumes).
bool isBaseFood(Food food) =>
    _baseFamilies.values.any((ids) => ids.contains(food.id));

/// Herbs are seasoning, not one of the plants of a meal: they never count
/// toward the 2–3 plants (and aren't offered as a plant).
const _herbIds = {'parsley', 'mint', 'peppermint', 'basil', 'cilantro', 'dill'};

bool isHerb(Food food) => _herbIds.contains(food.id);

/// Vegetable and fruit entries that are prepared products rather than a
/// plant to put on the plate (pastes, dips, salsa).
const _preparedIds = {'tomato-paste', 'salsa', 'guacamole'};

/// Whether [food] can be one of a meal's 2–3 plants: a vegetable or fruit
/// (including culinary vegetables sold as pantry foods, such as olives,
/// canned tomatoes and sea vegetables), but not a herb, a base or a prepared
/// product.
bool isMealPlant(Food food) =>
    (food.categoryId == 'vegetables' || food.categoryId == 'fruit') &&
    !isHerb(food) &&
    !_preparedIds.contains(food.id) &&
    mealSlotFor(food) == MealSlot.plant;
