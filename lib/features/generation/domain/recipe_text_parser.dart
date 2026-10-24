/// What could be read from pasted recipe text. Every field is optional: what
/// isn't there stays empty, and nothing is made up.
final class PastedRecipe {
  const PastedRecipe({
    this.title = '',
    this.ingredients = const [],
    this.steps = const [],
    this.notes = '',
    this.serves,
    this.minutes,
  });

  final String title;

  /// Ingredient lines exactly as written (quantities stay inside the line).
  final List<String> ingredients;
  final List<String> steps;

  /// Text under a "Notes" or "Tips" heading.
  final String notes;
  final int? serves;
  final int? minutes;

  bool get isEmpty =>
      title.isEmpty &&
      ingredients.isEmpty &&
      steps.isEmpty &&
      notes.isEmpty &&
      serves == null &&
      minutes == null;
}

enum _Section { none, ingredients, steps, notes }

final _ingredientHeading = RegExp(
  r'^(?:the\s+)?ingredients?(?:\s+list)?\s*:?$',
  caseSensitive: false,
);
final _stepsHeading = RegExp(
  r'^(?:method|directions?|instructions?|steps?|preparation|how to make(?: it)?|to make)\s*:?$',
  caseSensitive: false,
);
final _notesHeading = RegExp(
  r'^(?:notes?|tips?|cook.?s notes?)\s*:?$',
  caseSensitive: false,
);

/// "Serves 4", "Servings: 4", "Yield: 6 servings", "4 servings".
final _serves = RegExp(
  r'^(?:serves|servings?|yield|yields)\s*:?\s*(\d{1,3})(?:\s*(?:-|to|–)\s*\d{1,3})?\b'
  r'|^(\d{1,3})\s+servings?\b',
  caseSensitive: false,
);

/// A labelled time: "Prep time: 15 min", "Cook 1 hour 10 minutes",
/// "Total time: 45 minutes", "Ready in 30 minutes".
final _timeLine = RegExp(
  r'^(prep(?:aration)?(?:\s*time)?|cook(?:ing)?(?:\s*time)?|total(?:\s*time)?|ready\s+in|time)\s*:?\s*(.+)$',
  caseSensitive: false,
);

final _hours = RegExp(r'(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)\b');
final _mins = RegExp(r'(\d+)\s*(?:m|min|mins|minute|minutes)\b');

/// "1 hour 10 minutes" → 70, "45 min" → 45, anything else → null.
int? parseDuration(String text) {
  final t = text.toLowerCase();
  final h = _hours.firstMatch(t);
  final m = _mins.firstMatch(t);
  if (h == null && m == null) return null;
  final total =
      ((h == null ? 0 : double.parse(h.group(1)!)) * 60).round() +
      (m == null ? 0 : int.parse(m.group(1)!));
  return total >= 1 && total <= 1440 ? total : null;
}

final _bullet = RegExp(
  r'^([-*•–—·]|\d{1,2}[.)]|step\s*\d{1,2}\s*[:.)-]?)\s+',
  caseSensitive: false,
);

String _strip(String line) => line.trim().replaceFirst(_bullet, '').trim();

/// A line that starts like an ingredient: a number, a fraction, or a common
/// amount word, followed by something.
final _looksLikeIngredient = RegExp(
  r'^(?:\d+[\d\s/.,-]*|[¼½¾⅓⅔⅛]|an?\s|one\s|two\s|three\s|half\s|a\s+(?:pinch|handful|dash|splash)|pinch|handful|dash|salt|pepper|olive oil|to taste)',
  caseSensitive: false,
);

/// Reads pasted recipe text, locally. Looks for a title, "Ingredients" and
/// "Method"-style headings, servings and times. Without headings, lines that
/// start with an amount are taken as ingredients and the longer sentences after
/// them as steps. Anything uncertain is left for the user to place.
PastedRecipe parsePastedRecipe(String text) {
  final lines = text
      .replaceAll(' ', ' ')
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .toList();

  String title = '';
  final ingredients = <String>[];
  final steps = <String>[];
  final notes = <String>[];
  int? serves;
  int? prep;
  int? cook;
  int? total;
  var section = _Section.none;
  var titleSettled = false;

  for (final raw in lines) {
    if (raw.isEmpty) continue;
    final line = raw;

    // Headings switch the section and are not content.
    if (_ingredientHeading.hasMatch(line)) {
      section = _Section.ingredients;
      titleSettled = true;
      continue;
    }
    if (_stepsHeading.hasMatch(line)) {
      section = _Section.steps;
      titleSettled = true;
      continue;
    }
    if (_notesHeading.hasMatch(line)) {
      section = _Section.notes;
      titleSettled = true;
      continue;
    }

    // Servings and times are read wherever they appear, and left out of the
    // lists.
    final sm = _serves.firstMatch(line);
    if (sm != null) {
      serves ??= int.parse(sm.group(1) ?? sm.group(2)!);
      titleSettled = true;
      continue;
    }
    final tm = _timeLine.firstMatch(line);
    if (tm != null) {
      final minutes = parseDuration(tm.group(2)!);
      if (minutes != null) {
        final label = tm.group(1)!.toLowerCase();
        if (label.startsWith('prep')) {
          prep ??= minutes;
        } else if (label.startsWith('cook')) {
          cook ??= minutes;
        } else {
          total ??= minutes; // total, ready in, time
        }
        titleSettled = true;
        continue;
      }
    }

    // The first plain line is the title.
    if (!titleSettled && section == _Section.none) {
      titleSettled = true;
      if (line.length <= 90 && !_looksLikeIngredient.hasMatch(line)) {
        title = _strip(line);
        continue;
      }
    }

    switch (section) {
      case _Section.ingredients:
        ingredients.add(_strip(line));
      case _Section.steps:
        steps.add(_strip(line));
      case _Section.notes:
        notes.add(line);
      case _Section.none:
        // No heading yet: guess from the line itself.
        final l = _strip(line);
        if (steps.isEmpty && _looksLikeIngredient.hasMatch(l)) {
          ingredients.add(l);
        } else if (ingredients.isNotEmpty) {
          steps.add(l);
        } else {
          // Not clearly anything: left for the user, in the notes.
          notes.add(line);
        }
    }
  }

  final minutes =
      total ??
      (prep == null && cook == null ? null : (prep ?? 0) + (cook ?? 0));
  return PastedRecipe(
    title: title,
    ingredients: ingredients.where((l) => l.isNotEmpty).toList(),
    steps: steps.where((l) => l.isNotEmpty).toList(),
    notes: notes.join('\n').trim(),
    serves: serves,
    minutes: minutes != null && minutes >= 1 && minutes <= 1440
        ? minutes
        : null,
  );
}
