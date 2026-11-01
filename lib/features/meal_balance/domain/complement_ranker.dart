import '../../content/domain/food.dart';
import 'meal_balance.dart';
import 'pairing_rules.dart';
import 'plate_group.dart';

/// A food suggested to go with the foods already chosen.
final class Suggestion {
  const Suggestion({
    required this.food,
    required this.score,
    required this.reasons,
  });

  final Food food;

  /// Higher is better; only meaningful for ordering one list.
  final double score;

  /// Why it was suggested. Never empty.
  final List<Reason> reasons;
}

/// Every number the ranker uses, in one place so it can be read, tested and
/// changed on purpose (like `MatchConfig` for recipes).
final class RankerConfig {
  const RankerConfig({
    this.fillsMissingGroup = 3.0,
    this.nextMissingFalloff = 0.5,
    this.pairingBonus = 2.0,
    this.newCategoryBonus = 0.5,
    this.coveredGroupPenalty = 1.0,
    this.limit = 6,
  });

  /// A food that covers a core plate part the meal still lacks. The first
  /// missing part (vegetables and fruit, then grains, then protein) is worth
  /// the full amount; each later one this much less, so the order is stable.
  final double fillsMissingGroup;
  final double nextMissingFalloff;

  /// A documented pairing (for example vitamin C with plant iron).
  final double pairingBonus;

  /// A food from a category not yet in the meal: variety.
  final double newCategoryBonus;

  /// Subtracted for a food whose plate part is already covered while another
  /// part is still missing, so the next suggestion completes the plate first.
  final double coveredGroupPenalty;

  final int limit;

  static const defaults = RankerConfig();
}

/// Suggests foods that go with [chosen]: pure, deterministic and free of
/// network, clock or randomness.
///
/// Rules, in order of authority:
/// 1. **Safety is not scored.** A food the caller does not [allows] (diet,
///    allergens, avoidances) is never returned, whatever its score.
/// 2. Foods the user dislikes or already chose are never returned.
/// 3. Herbs, fermented sides and "other" foods are not suggested as a part of
///    the plate (they can still be chosen by the user).
/// 4. Score = fills a missing plate part + a documented pairing + variety −
///    repeating a covered part. Ties break on [featuredIds] (optional, and
///    only ever a tie-break, never a reason shown), then name, then id.
///
/// The cycle is not an input to the score. [featuredIds] exists so a caller
/// that already features foods for the phase can order otherwise identical
/// suggestions the same way; it never adds a reason or a claim.
List<Suggestion> suggestComplements({
  required Iterable<Food> chosen,
  required Iterable<Food> candidates,
  bool Function(Food food)? allows,
  Set<String> dislikedIds = const {},
  Set<String> featuredIds = const {},
  RankerConfig config = RankerConfig.defaults,
}) {
  final chosenList = [...chosen];
  final chosenIds = {for (final f in chosenList) f.id};
  final balance = MealBalance.evaluate(chosenList);
  final chosenCategories = {for (final f in chosenList) f.categoryId};

  final scored = <Suggestion>[];
  for (final food in candidates) {
    if (chosenIds.contains(food.id) || dislikedIds.contains(food.id)) continue;
    if (allows != null && !allows(food)) continue;
    final group = plateGroupOf(food);
    if (!group.countsTowardBalance) continue;

    final reasons = <Reason>[];
    var score = 0.0;
    final coreGroup = group == PlateGroup.legume ? PlateGroup.protein : group;
    final missingIndex = balance.missing.indexOf(coreGroup);
    if (missingIndex >= 0) {
      score +=
          config.fillsMissingGroup - missingIndex * config.nextMissingFalloff;
      reasons.add(
        Reason(
          code: 'completes-plate',
          text: switch (coreGroup) {
            PlateGroup.vegetableFruit =>
              'Adds vegetables or fruit, which fill half of a balanced plate.',
            PlateGroup.grainStarch =>
              'Adds a grain or starch, the base that rounds the meal out.',
            _ => 'Adds a protein food to complete the meal.',
          },
          source: 'USDA MyPlate; Harvard Healthy Eating Plate',
        ),
      );
    } else if (balance.missing.isNotEmpty &&
        MealBalance.core.contains(coreGroup)) {
      score -= config.coveredGroupPenalty;
    }

    final pairings = pairingReasonsFor(food, chosenList);
    if (pairings.isNotEmpty) {
      score += config.pairingBonus;
      reasons.addAll(pairings);
    }
    if (!chosenCategories.contains(food.categoryId)) {
      score += config.newCategoryBonus;
      if (reasons.isEmpty) {
        reasons.add(
          const Reason(
            code: 'adds-variety',
            text: 'Adds variety: a different kind of food from the ones you chose.',
            source: 'General dietary guidance on variety',
          ),
        );
      }
    }
    if (reasons.isEmpty) {
      reasons.add(
        const Reason(
          code: 'goes-with',
          text: 'A common addition to the foods you chose.',
          source: 'Culinary convention',
        ),
      );
    }
    scored.add(Suggestion(food: food, score: score, reasons: reasons));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final fa = featuredIds.contains(a.food.id) ? 0 : 1;
    final fb = featuredIds.contains(b.food.id) ? 0 : 1;
    if (fa != fb) return fa - fb;
    final byName = a.food.displayName.toLowerCase().compareTo(
      b.food.displayName.toLowerCase(),
    );
    return byName != 0 ? byName : a.food.id.compareTo(b.food.id);
  });
  return scored.take(config.limit).toList();
}
