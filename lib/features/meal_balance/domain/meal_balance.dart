import '../../content/domain/food.dart';
import 'plate_group.dart';

/// How balanced a set of chosen foods is, as a share of a simple plate:
/// something from vegetables and fruit, a grain or starch, and a protein food
/// (meat, fish, egg, tofu, or beans and lentils). Pure and deterministic.
///
/// "Balanced" here is only this plate idea. It is not a calorie, nutrient or
/// health claim, and it never depends on the cycle.
final class MealBalance {
  const MealBalance._({
    required this.present,
    required this.missing,
    required this.score,
  });

  /// The three parts of a basic plate, in the order they are suggested.
  static const core = [
    PlateGroup.vegetableFruit,
    PlateGroup.grainStarch,
    PlateGroup.protein,
  ];

  /// Core parts the chosen foods already cover. Beans, lentils and peas
  /// cover the protein part (counted once, as protein).
  final Set<PlateGroup> present;

  /// Core parts still missing, in suggestion order.
  final List<PlateGroup> missing;

  /// 0 to 1: the share of the three core parts covered, plus a small variety
  /// credit for each additional distinct plant food, capped at 1.
  final double score;

  bool get isBalanced => missing.isEmpty;

  /// Evaluates [chosen]. Order does not matter; duplicates count once.
  static MealBalance evaluate(Iterable<Food> chosen) {
    final foods = {for (final f in chosen) f.id: f}.values;
    final groups = {for (final f in foods) plateGroupOf(f)};
    final covered = <PlateGroup>{
      if (groups.contains(PlateGroup.vegetableFruit)) PlateGroup.vegetableFruit,
      if (groups.contains(PlateGroup.grainStarch)) PlateGroup.grainStarch,
      if (groups.contains(PlateGroup.protein) ||
          groups.contains(PlateGroup.legume))
        PlateGroup.protein,
    };
    final missing = [
      for (final g in core)
        if (!covered.contains(g)) g,
    ];
    final plantFoods = foods
        .where((f) => plateGroupOf(f).countsTowardBalance)
        .length;
    final base = covered.length / core.length;
    final variety = covered.length == core.length
        ? 0.0
        : (plantFoods - covered.length).clamp(0, 2) * 0.05;
    return MealBalance._(
      present: covered,
      missing: missing,
      score: (base + variety).clamp(0.0, 1.0),
    );
  }
}
