/// One nutrient line in a profile: the amount per serving and, when it has one,
/// what share of a daily reference intake that is (for each adult age group).
final class ProfileNutrient {
  const ProfileNutrient({
    required this.name,
    required this.amount,
    required this.unit,
    this.references = const [],
  });

  factory ProfileNutrient.fromJson(Map<String, Object?> json) =>
      ProfileNutrient(
        name: json['name']! as String,
        amount: (json['amount']! as num).toDouble(),
        unit: json['unit']! as String,
        references: [
          for (final r in (json['reference'] as List<Object?>? ?? const []))
            ProfileReference.fromJson(r! as Map<String, Object?>),
        ],
      );

  final String name;
  final double amount;
  final String unit;

  /// Empty for a nutrient shown as an amount only (vitamin K).
  final List<ProfileReference> references;
}

/// "48% of 310 mg (19–30 y, RDA)".
final class ProfileReference {
  const ProfileReference({
    required this.group,
    required this.kind,
    required this.value,
    required this.unit,
    required this.percent,
  });

  factory ProfileReference.fromJson(Map<String, Object?> json) =>
      ProfileReference(
        group: json['group']! as String,
        kind: json['kind']! as String,
        value: (json['value']! as num).toDouble(),
        unit: json['unit']! as String,
        percent: (json['percent']! as num).toInt(),
      );

  final String group;
  final String kind;
  final double value;
  final String unit;
  final int percent;
}

/// The standard five-section Food Detail content for one food, with its
/// review status. Only a profile with [publishable] true is ever shown in the
/// app.
final class FoodProfile {
  const FoodProfile({
    required this.foodId,
    required this.whatItOffers,
    required this.practicalServing,
    required this.howToEatIt,
    required this.cycleRelevance,
    required this.energyKcal,
    required this.nutrients,
    required this.cautions,
    required this.reviewLabel,
    required this.publishable,
  });

  /// Reads one entry of `reference-profiles.json`.
  factory FoodProfile.fromJson(
    Map<String, Object?> json, {
    required String reviewLabel,
    bool? publishable,
  }) {
    final sections = json['sections']! as Map<String, Object?>;
    final serving = json['perServing']! as Map<String, Object?>;
    final review = json['review']! as Map<String, Object?>;
    return FoodProfile(
      foodId: json['catalogueId']! as String,
      whatItOffers: sections['whatItOffers']! as String,
      practicalServing: sections['practicalServing']! as String,
      howToEatIt: sections['howToEatIt']! as String,
      cycleRelevance: sections['cycleRelevance']! as String,
      energyKcal: (serving['energyKcal']! as num).toInt(),
      nutrients: [
        for (final n in serving['keyNutrients']! as List<Object?>)
          ProfileNutrient.fromJson(n! as Map<String, Object?>),
      ],
      cautions: [
        for (final c in json['cautions']! as List<Object?>)
          (c! as Map<String, Object?>)['text']! as String,
      ],
      reviewLabel: reviewLabel,
      publishable: publishable ?? review['publishable'] == true,
    );
  }

  final String foodId;
  final String whatItOffers;

  /// The household portion the nutrient amounts are for.
  final String practicalServing;
  final String howToEatIt;
  final String cycleRelevance;
  final int energyKcal;
  final List<ProfileNutrient> nutrients;

  /// Sourced cautions, shown in the page's existing "Good to know" note.
  final List<String> cautions;

  /// "Nutrition data verified against USDA and NIH sources; editorial review
  /// pending; not clinically reviewed."
  final String reviewLabel;
  final bool publishable;
}

/// Reads the bundled `food_profiles.json`: the reviewed profiles by food id.
/// A profile not marked publishable is left out, so nothing unreviewed can
/// reach the app.
Map<String, FoodProfile> parseFoodProfiles(Map<String, Object?> json) {
  final label = json['reviewLabel']! as String;
  final profiles = json['profiles']! as Map<String, Object?>;
  return {
    for (final e in profiles.entries)
      if (FoodProfile.fromJson(
        e.value! as Map<String, Object?>,
        reviewLabel: label,
      ).publishable)
        e.key: FoodProfile.fromJson(
          e.value! as Map<String, Object?>,
          reviewLabel: label,
        ),
  };
}
