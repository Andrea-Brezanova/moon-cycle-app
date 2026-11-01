import '../../content/domain/food.dart';
import 'plate_group.dart';

/// Why a suggested food goes with the foods already chosen, in words a person
/// can read, with where the idea comes from.
final class Reason {
  const Reason({required this.code, required this.text, required this.source});

  /// Stable id, for tests and analytics-free logging.
  final String code;

  /// Plain-language explanation. Never mentions a phase, hormones or a
  /// health outcome.
  final String text;

  /// Where the idea comes from (a public guideline or fact sheet).
  final String source;
}

/// Plant foods that are a useful source of iron: beans, lentils and peas
/// (the legume group), plus these.
const plantIronFoodIds = {
  'spinach',
  'kale',
  'chard',
  'collard',
  'tofu',
  'tempeh',
  'quinoa',
  'pumpkin-seeds',
  'cashew',
};

/// Foods rich in vitamin C that are easy to add to a plate: citrus, berries,
/// peppers and brassicas. The same pairing the app's menstrual-phase copy
/// already gives (NIH ODS), generalised to every day.
const vitaminCFoodIds = {
  'orange',
  'grapefruit',
  'mandarin',
  'kiwi',
  'strawberry',
  'papaya',
  'red-bell-pepper',
  'green-bell-pepper',
  'yellow-bell-pepper',
  'broccoli',
  'brussels-sprouts',
};

bool isPlantIronFood(Food f) =>
    plateGroupOf(f) == PlateGroup.legume || plantIronFoodIds.contains(f.id);

bool isVitaminCFood(Food f) => vitaminCFoodIds.contains(f.id);

/// The documented reasons [candidate] suits [chosen]. Empty when there is no
/// established reason beyond plate completeness (which the ranker adds).
List<Reason> pairingReasonsFor(Food candidate, Iterable<Food> chosen) {
  final out = <Reason>[];
  final list = chosen.toList();
  if (isVitaminCFood(candidate) && list.any(isPlantIronFood)) {
    out.add(
      const Reason(
        code: 'plant-iron-vitamin-c',
        text:
            'Vitamin C helps your body absorb iron from plant foods, so it '
            'goes well with the beans, lentils or greens you chose.',
        source: 'NIH Office of Dietary Supplements, Iron fact sheet',
      ),
    );
  }
  if (isPlantIronFood(candidate) && list.any(isVitaminCFood)) {
    out.add(
      const Reason(
        code: 'plant-iron-vitamin-c',
        text:
            'Plant iron is absorbed better with vitamin C, which the food '
            'you chose provides.',
        source: 'NIH Office of Dietary Supplements, Iron fact sheet',
      ),
    );
  }
  return out;
}
