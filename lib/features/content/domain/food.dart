import '../../../core/domain/phase.dart';

/// What a food is made from, for the diet filter.
enum AnimalSource { none, dairy, egg, seafood, meat, honey }

/// A food from the catalogue ("Lettuce (Bibb, Boston, romaine)").
final class Food {
  const Food({
    required this.id,
    required this.name,
    required this.aisleId,
    required this.categoryId,
    required this.animalSource,
    required this.allergenIds,
    this.mayContainAllergenIds = const {},
    this.synonyms = const [],
    this.cautions = const [],
    this.why = const {},
  });

  /// Permanent slug; user data (shopping items, avoidances) stores it.
  final String id;

  /// The name as exported, possibly with a parenthetical.
  final String name;

  final String aisleId;

  /// The food's own canonical category id (taxonomy `categories`), independent
  /// of whether any phase features it.
  final String categoryId;
  final AnimalSource animalSource;
  final Set<String> allergenIds;

  /// Allergens the food only *may* carry (check the label), e.g. oats and
  /// gluten, kimchi and fish. Not shown as a permanent allergen, but an
  /// avoided allergen still leaves the food out (conservative filtering).
  final Set<String> mayContainAllergenIds;

  /// Other names for typed shopping items and avoidances ("courgette").
  final List<String> synonyms;
  final List<String> cautions;

  /// The ingredient-sheet copy for each phase the food is recommended in.
  final Map<Phase, FoodWhy> why;

  /// The name without its parenthetical: "Lettuce".
  String get displayName {
    final i = name.indexOf(' (');
    return i < 0 ? name : name.substring(0, i);
  }

  /// The parenthetical, shown as a second line: "Bibb, Boston, romaine".
  String? get qualifier {
    final match = RegExp(r' \((.+)\)$').firstMatch(name);
    return match?.group(1);
  }

  @override
  String toString() => 'Food($id)';
}

/// Why a food suits a phase (ingredient sheet).
final class FoodWhy {
  const FoodWhy({required this.short, required this.detail});

  final String short;
  final String detail;
}
