import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';

/// Maps an external provider's ingredient text ("Black Eyed Peas", "minced
/// garlic") to a Moon Cycle food, **only when the mapping is reliable**.
///
/// Reliable means the name equals a food's name or synonym after removing a
/// short list of harmless words (preparation and size) and one plural "s". It
/// never guesses by a shared word: "peanut butter" is not butter, "chicken
/// stock" is not chicken. Anything else is left unmapped, and the caller treats
/// an unmapped ingredient as *unknown*, never as safe.
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
  };

  final _cache = <String, Food?>{};

  Food? map(String raw) => _cache.putIfAbsent(raw, () => _map(raw));

  Food? _map(String raw) {
    final name = normaliseName(raw);
    if (name.isEmpty) return null;
    final words = name.split(' ');
    final kept = [
      for (final w in words)
        if (!_harmless.contains(w)) w,
    ];
    final candidates = <String>{
      name,
      kept.join(' '),
      _singular(name),
      _singular(kept.join(' ')),
    }..removeWhere((c) => c.isEmpty);
    for (final c in candidates) {
      final food = catalogue.foodNamed(c);
      if (food != null) return food;
    }
    return null;
  }

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

  /// Ingredient lines that carry no allergy or diet risk worth refusing a
  /// recipe for. Deliberately tiny: oils, stocks, sauces and spice mixes can
  /// hide sesame, peanut, soy, gluten, dairy or fish, so they are *not* here.
  static final _alwaysSafe = RegExp(
    r'^(water|ice|salt|sea salt|kosher salt|pepper|black pepper|white pepper|'
    r'sugar|brown sugar|caster sugar)$',
  );

  static bool isAlwaysSafe(String raw) =>
      _alwaysSafe.hasMatch(normaliseName(raw));
}
