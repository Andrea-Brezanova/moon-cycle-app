import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/food_filter.dart';
import '../../content/domain/recipe.dart';
import '../../content/domain/text_match.dart';

/// One search across foods and library recipes (docs/product-implementation-plans.md,
/// plan B). Pure and deterministic. NOT wired to any screen yet.

enum SearchKind { food, recipe }

/// Why a hit matched, best reason first. Shown as a quiet second line.
enum SearchMatch { name, nameStart, word, contains, synonym, ingredient }

final class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.score,
    required this.matchedOn,
  });

  final SearchKind kind;

  /// A food id or a recipe id.
  final String id;
  final String title;

  /// Higher is better; only meaningful for ordering one result list.
  final int score;
  final SearchMatch matchedOn;
}

/// Searches the bundled foods and recipes for [query].
///
/// - Every word of the query must match somewhere (AND). Words match whole
///   words or word starts, so "pea" finds "Pea" and "Peanut" but ranks the
///   exact word first.
/// - [filter] is applied first and strictly: a food the user's diet or
///   allergies exclude, and a recipe containing one, are never returned.
/// - Order: score, then foods before recipes, then title, then id. No phase,
///   cycle, popularity or time input.
List<SearchHit> searchCatalogue({
  required Catalogue catalogue,
  required String query,
  FoodFilter filter = FoodFilter.none,
  int limit = 20,
}) {
  final tokens = normaliseName(query).split(' ').where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return const [];
  final words = tokens.toList();
  final hits = <SearchHit>[];

  for (final food in catalogue.foods) {
    if (!filter.allowsFood(food)) continue;
    final hit = _scoreFood(food, words);
    if (hit != null) hits.add(hit);
  }
  for (final recipe in catalogue.recipes) {
    if (!filter.allowsRecipe(recipe, catalogue)) continue;
    final hit = _scoreRecipe(recipe, catalogue, words);
    if (hit != null) hits.add(hit);
  }
  hits.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    if (a.kind != b.kind) return a.kind.index - b.kind.index;
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  });
  return hits.take(limit).toList();
}

SearchHit? _scoreFood(Food food, List<String> words) {
  final name = normaliseName(food.displayName);
  final synonyms = [for (final s in food.synonyms) normaliseName(s)];
  return _score(
    kind: SearchKind.food,
    id: food.id,
    title: food.displayName,
    name: name,
    synonyms: synonyms,
    ingredients: const [],
    words: words,
  );
}

SearchHit? _scoreRecipe(
  Recipe recipe,
  Catalogue catalogue,
  List<String> words,
) {
  final ingredients = [
    for (final id in recipe.keyFoodIds)
      if (catalogue.food(id) case final f?) normaliseName(f.displayName),
  ];
  return _score(
    kind: SearchKind.recipe,
    id: recipe.id,
    title: recipe.title,
    name: normaliseName(recipe.title),
    synonyms: const [],
    ingredients: ingredients,
    words: words,
  );
}

SearchHit? _score({
  required SearchKind kind,
  required String id,
  required String title,
  required String name,
  required List<String> synonyms,
  required List<String> ingredients,
  required List<String> words,
}) {
  var total = 0;
  var best = SearchMatch.ingredient;
  for (final w in words) {
    final (points, how) = _tokenScore(w, name, synonyms, ingredients);
    if (points == 0) return null;
    total += points;
    if (how.index < best.index) best = how;
  }
  if (words.length > 1 && name.contains(words.join(' '))) total += 20;
  return SearchHit(
    kind: kind,
    id: id,
    title: title,
    score: total,
    matchedOn: best,
  );
}

(int, SearchMatch) _tokenScore(
  String w,
  String name,
  List<String> synonyms,
  List<String> ingredients,
) {
  final nameWords = name.split(' ');
  if (name == w) return (100, SearchMatch.name);
  if (name.startsWith(w)) return (80, SearchMatch.nameStart);
  if (nameWords.contains(w)) return (65, SearchMatch.word);
  if (nameWords.any((x) => x.startsWith(w))) return (55, SearchMatch.word);
  if (synonyms.any((s) => s == w || s.split(' ').contains(w))) {
    return (50, SearchMatch.synonym);
  }
  if (synonyms.any((s) => s.startsWith(w))) return (45, SearchMatch.synonym);
  if (w.length >= 3 && name.contains(w)) return (30, SearchMatch.contains);
  if (ingredients.any((i) => i.split(' ').any((x) => x.startsWith(w)))) {
    return (25, SearchMatch.ingredient);
  }
  return (0, SearchMatch.ingredient);
}
