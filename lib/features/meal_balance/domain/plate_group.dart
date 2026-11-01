import '../../content/domain/food.dart';

/// The part of a plate a food mainly fills, after the general "plate" guidance
/// used by USDA MyPlate and the Harvard Healthy Eating Plate: vegetables and
/// fruit, whole grains and other starches, protein foods, and smaller amounts
/// of dairy or fortified alternatives and of healthy fats.
///
/// This is a culinary grouping for suggesting balanced combinations. It says
/// nothing about any phase of the cycle.
enum PlateGroup {
  vegetableFruit('Vegetables and fruit'),
  grainStarch('Grains and starches'),
  protein('Protein foods'),
  legume('Beans, lentils and peas'),
  dairyAlternative('Dairy and alternatives'),
  nutSeed('Nuts and seeds'),
  fermented('Fermented foods'),
  seasoning('Herbs and seasoning'),
  other('Other');

  const PlateGroup(this.label);
  final String label;

  /// Groups that count toward a balanced plate. Seasoning, fermented sides and
  /// "other" never make a meal balanced on their own.
  bool get countsTowardBalance => switch (this) {
    vegetableFruit || grainStarch || protein || legume => true,
    dairyAlternative || nutSeed => true,
    fermented || seasoning || other => false,
  };
}

/// Herbs season a meal; they are not a plate group of their own
/// (the same ids the Build a Meal picker leaves out).
const _herbIds = {'parsley', 'mint', 'peppermint', 'basil', 'cilantro', 'dill'};

/// Vegetable and fruit entries that are prepared products, not a plant.
const _preparedIds = {'tomato-paste', 'salsa', 'guacamole'};

/// The plate group of [food], from its own catalogue category (never from a
/// phase it is featured in).
PlateGroup plateGroupOf(Food food) {
  if (_herbIds.contains(food.id)) return PlateGroup.seasoning;
  if (_preparedIds.contains(food.id)) return PlateGroup.other;
  return switch (food.categoryId) {
    'vegetables' || 'fruit' => PlateGroup.vegetableFruit,
    'grains' => PlateGroup.grainStarch,
    'legumes' => PlateGroup.legume,
    'protein' || 'seafood' => PlateGroup.protein,
    'dairy-alternatives' => PlateGroup.dairyAlternative,
    'nuts-seeds' => PlateGroup.nutSeed,
    'fermented' => PlateGroup.fermented,
    _ => PlateGroup.other,
  };
}
