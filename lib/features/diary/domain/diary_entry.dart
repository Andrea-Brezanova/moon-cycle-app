import '../../../core/domain/local_date.dart';

/// The four meals of a day, in order.
enum DiaryMeal {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snacks');

  const DiaryMeal(this.label);

  final String label;

  /// A sensible default for "now": before 10 breakfast, before 15 lunch,
  /// before 18 snacks, otherwise dinner.
  static DiaryMeal forHour(int hour) => hour < 10
      ? breakfast
      : hour < 15
      ? lunch
      : hour < 18
      ? snack
      : dinner;
}

/// What an entry points at. `custom` is a meal the user typed ("Your own
/// meal"): there is no catalogue item, and no nutrition is ever invented.
enum DiaryItemKind { food, recipe, custom }

/// How an amount is counted. Recipes are always counted in servings.
enum DiaryUnit {
  serving('serving', 'servings', 0.5),
  gram('g', 'g', 25),
  ounce('oz', 'oz', 1),
  cup('cup', 'cups', 0.25),
  piece('piece', 'pieces', 1);

  const DiaryUnit(this.id, this.plural, this.step);

  /// Stored text.
  final String id;
  final String plural;

  /// What the − and + buttons change the amount by.
  final double step;

  static DiaryUnit parse(String id) =>
      values.firstWhere((u) => u.id == id, orElse: () => serving);

  double get defaultAmount => switch (this) {
    serving => 1,
    gram => 100,
    ounce => 4,
    cup => 1,
    piece => 1,
  };

  /// "1 serving", "1.5 servings", "100 g", "2 pieces".
  String format(double amount) {
    final text = _amountText(amount);
    return switch (this) {
      serving => '$text ${amount == 1 ? 'serving' : 'servings'}',
      piece => '$text ${amount == 1 ? 'piece' : 'pieces'}',
      cup => '$text ${amount == 1 ? 'cup' : 'cups'}',
      gram => '$text g',
      ounce => '$text oz',
    };
  }
}

String _amountText(double v) {
  final whole = v.truncate();
  final frac = v - whole;
  final g = switch (double.parse(frac.toStringAsFixed(2))) {
    0.25 => '¼',
    0.5 => '½',
    0.75 => '¾',
    _ => null,
  };
  if (frac == 0) return '$whole';
  if (g != null) return whole == 0 ? g : '$whole$g';
  return v.toStringAsFixed(1);
}

/// One thing the user ate, on one day, in one meal.
final class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.kind,
    required this.itemId,
    required this.title,
    required this.amount,
    required this.unit,
    required this.createdAt,
    this.note,
  });

  final String id;
  final LocalDate date;
  final DiaryMeal meal;
  final DiaryItemKind kind;

  /// The catalogue food id or the recipe id.
  final String itemId;

  /// The name when it was logged.
  final String title;
  final double amount;
  final DiaryUnit unit;
  final DateTime createdAt;

  /// The user's note, or null.
  final String? note;

  String get quantity => unit.format(amount);
}

/// A new entry, before it has an id. Logging the same item again in the same
/// meal and unit adds to the amount: the diary never holds two identical rows.
final class DiaryDraft {
  const DiaryDraft({
    required this.date,
    required this.meal,
    required this.kind,
    required this.itemId,
    required this.title,
    required this.amount,
    required this.unit,
    this.note,
  });

  final LocalDate date;
  final DiaryMeal meal;
  final DiaryItemKind kind;
  final String itemId;
  final String title;
  final double amount;
  final DiaryUnit unit;
  final String? note;
}

/// A whole day, meal by meal.
final class DiaryDay {
  const DiaryDay(this.date, this.entries);

  final LocalDate date;
  final List<DiaryEntry> entries;

  List<DiaryEntry> of(DiaryMeal meal) => [
    for (final e in entries)
      if (e.meal == meal) e,
  ];

  bool get isEmpty => entries.isEmpty;
}
