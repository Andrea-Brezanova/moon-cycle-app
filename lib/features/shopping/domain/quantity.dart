import '../../content/domain/recipe.dart' show formatAmount;
import 'shopping_item.dart';

/// The quantity shown for an item, from all its sources (plan §9.2):
///
/// - amounts are added up per unit: g and kg together, ml and l together;
///   tsp, tbsp, cup, pieces and every other unit each on their own;
/// - mass and volume are never converted into each other;
/// - quantities in words ("to serve") are listed as they are;
/// - groups are joined with " + " in the order they were added.
///
/// "200 g" + "1 kg" → "1.2 kg"; "1 tbsp" + "100 g" → "1 tbsp + 100 g".
/// Empty when no source asked for an amount.
String displayQuantity(List<ShoppingSource> sources) {
  final totals = <String, double>{};
  final words = <String>[];
  for (final s in sources) {
    if (s.amount != null) {
      final (unit, factor) = _canonical(s.unit);
      totals[unit] = (totals[unit] ?? 0) + s.amount! * factor;
    } else if (s.qtyText != null && !words.contains(s.qtyText)) {
      words.add(s.qtyText!);
    }
  }
  return [
    for (final MapEntry(key: unit, value: total) in totals.entries)
      _format(total, unit),
    ...words,
  ].join(' + ');
}

/// Mass in grams and volume in millilitres; everything else as it is.
(String, double) _canonical(String? unit) => switch (unit) {
  'kg' => ('g', 1000),
  'l' => ('ml', 1000),
  null => ('piece', 1),
  final u => (u, 1),
};

String _format(double total, String unit) => switch (unit) {
  'g' when total >= 1000 => '${formatAmount(total / 1000)} kg',
  'ml' when total >= 1000 => '${formatAmount(total / 1000)} l',
  'piece' => formatAmount(total),
  _ => '${formatAmount(total)} $unit',
};
