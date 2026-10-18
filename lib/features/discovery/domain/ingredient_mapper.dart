import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import 'ingredient_vocabulary.dart';

/// What an external ingredient line is understood to be.
final class IngredientClass {
  const IngredientClass(this.kind, {this.food, this.derived});

  final IngredientKind kind;

  /// For [IngredientKind.food].
  final Food? food;

  /// For [IngredientKind.derived].
  final Derived? derived;

  /// Whether a user with a diet or an allergy can be told this line is
  /// compatible: it is identified, or it is known to be neutral.
  bool get isIdentified =>
      kind == IngredientKind.food ||
      kind == IngredientKind.pantrySafe ||
      kind == IngredientKind.derived;
}

/// Understands an external provider's ingredient text, conservatively.
///
/// In order: a Moon Cycle food by name or synonym (after removing preparation
/// words and one plural), a reviewed alias ([IngredientVocabulary.aliases]), a
/// plain pantry item, an ingredient with known allergens and animal source, a
/// named ambiguous item, or unknown. It never guesses from a shared word:
/// "peanut butter" is not butter, "chicken stock" is not chicken.
class IngredientMapper {
  IngredientMapper(this.catalogue);

  final Catalogue catalogue;

  static const _harmless = {
    'fresh',
    'chopped',
    'minced',
    'diced',
    'sliced',
    'grated',
    'crushed',
    'large',
    'small',
    'medium',
    'ripe',
    'raw',
    'whole',
    'peeled',
    'finely',
    'roughly',
    'cooked',
    'frozen',
    'organic',
    'baby',
    'extra',
    'free',
    'range',
    'beaten',
    'unsalted',
    'salted',
    'dried',
    'sprigs',
    'sprig',
  };

  final _cache = <String, IngredientClass>{};

  /// The Moon Cycle food this line is, or null.
  Food? map(String raw) => classify(raw).food;

  IngredientClass classify(String raw) =>
      _cache.putIfAbsent(raw, () => _classify(raw));

  IngredientClass _classify(String raw) {
    final name = normaliseName(_clean(raw));
    if (name.isEmpty) return const IngredientClass(IngredientKind.unknown);
    final kept = [
      for (final w in name.split(' '))
        if (!_harmless.contains(w)) w,
    ].join(' ');
    final candidates = <String>{name, kept, _singular(name), _singular(kept)}
      ..removeWhere((c) => c.isEmpty);

    for (final c in candidates) {
      final food = catalogue.foodNamed(c);
      if (food != null) return IngredientClass(IngredientKind.food, food: food);
    }
    for (final c in candidates) {
      final id = IngredientVocabulary.aliases[c];
      final food = id == null ? null : catalogue.food(id);
      if (food != null) return IngredientClass(IngredientKind.food, food: food);
    }
    for (final c in candidates) {
      if (IngredientVocabulary.pantrySafe.contains(c)) {
        return const IngredientClass(IngredientKind.pantrySafe);
      }
    }
    for (final c in candidates) {
      final d = IngredientVocabulary.derived[c];
      if (d != null) {
        return IngredientClass(IngredientKind.derived, derived: d);
      }
    }
    for (final c in candidates) {
      if (IngredientVocabulary.ambiguous.contains(c)) {
        return const IngredientClass(IngredientKind.ambiguous);
      }
    }
    return const IngredientClass(IngredientKind.unknown);
  }

  /// Drops anything after a comma and any bracketed note: "egg, beaten" → "egg".
  static String _clean(String raw) =>
      raw.split(',').first.replaceAll(RegExp(r'\(.*?\)'), ' ');

  static String _singular(String text) {
    if (text.endsWith('ies') && text.length > 4) {
      return '${text.substring(0, text.length - 3)}y';
    }
    if (text.endsWith('oes') && text.length > 4) {
      return text.substring(0, text.length - 2);
    }
    if (text.endsWith('s') && !text.endsWith('ss') && text.length > 3) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  /// Plain pantry lines. Kept for callers that only have the label.
  bool isPantrySafe(String raw) =>
      classify(raw).kind == IngredientKind.pantrySafe;
}
