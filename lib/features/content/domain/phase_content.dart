import '../../../core/domain/phase.dart';

/// A food category ("Nuts & seeds"), in the stored order.
final class FoodCategory {
  const FoodCategory({required this.id, required this.name});

  final String id;
  final String name;
}

/// A shopping aisle ("Produce"), in the Shop order.
final class Aisle {
  const Aisle({required this.id, required this.name});

  final String id;
  final String name;
}

/// A common allergen, as offered in onboarding and Allergies ("Tree nuts").
final class Allergen {
  const Allergen({required this.id, required this.label});

  final String id;
  final String label;
}

/// The copy and foods for one phase, exactly as exported.
final class PhaseContent {
  const PhaseContent({
    required this.phase,
    required this.name,
    required this.season,
    required this.tagline,
    required this.summary,
    required this.focusBody,
    required this.homeFocus,
    required this.learnMore,
    required this.cooking,
    required this.note,
    required this.categories,
  });

  final Phase phase;

  /// "Follicular".
  final String name;

  /// "Inner spring".
  final String season;

  /// "Fresh, light and energising"; the last word is set in italic.
  final String tagline;

  /// The first sentence of the focus copy (Home hero, reveal).
  final String summary;

  /// The rest of the focus copy (Home "Your focus").
  final String focusBody;

  /// The approved short Today's focus description on Home, the same all phase
  /// long.
  final String homeFocus;

  /// The longer approved explanation shown on Learn more: paragraphs separated
  /// by a blank line.
  final String learnMore;

  /// "Light steaming, quick sautés and fresh salads."
  final String cooking;

  /// "These are suggestions, not rules. We feature different foods across your
  /// cycle to encourage variety — you can enjoy any food at any time." Shown directly below the phase intro on Foods.
  final String note;

  /// Foods per category, in the stored order. Only shippable foods.
  final List<PhaseCategory> categories;

  Iterable<String> get foodIds => categories.expand((c) => c.foodIds);
}

final class PhaseCategory {
  const PhaseCategory({required this.category, required this.foodIds});

  final FoodCategory category;
  final List<String> foodIds;
}
