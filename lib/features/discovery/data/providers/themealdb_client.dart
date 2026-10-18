import '../../../../core/domain/phase.dart';
import '../../../content/domain/catalogue.dart';
import '../../../content/domain/food_filter.dart';
import '../../../content/domain/recipe.dart';
import '../../domain/ingredient_mapper.dart';
import '../../domain/provider_policy.dart';
import '../../domain/recipe_matcher.dart';
import '../../domain/recipe_source.dart';
import '../recipe_sources.dart';
import 'provider_http.dart';

/// TheMealDB: a community recipe database with a free **test key** that is
/// allowed for development and education only. Its terms say an app cannot be
/// published to an app store without a paid supporter key, so this adapter is
/// **development-only** until that is approved and bought.
///
/// - Free search is one ingredient at a time (`filter.php?i=`); multi-ingredient
///   filtering is a paid feature. So a search asks once per chosen food, ranks
///   the meals by how many of the foods listed them, and fetches full details
///   (`lookup.php?i=`) for the best few.
/// - Terms do not allow us to assume storage: recipes are shown, not saved.
class TheMealDbClient implements ExternalRecipeClient {
  TheMealDbClient({
    required this.http,
    required this.catalogue,
    required this.policy,
    this.apiKey = testKey,
    DateTime Function()? now,
  }) : _mapper = IngredientMapper(catalogue),
       _now = now ?? DateTime.now;

  /// The documented free test key (development and education only).
  static const testKey = '1';
  static const id = 'themealdb';
  static const _host = 'www.themealdb.com';

  static const policyDefaults = ProviderPolicy(
    id: id,
    name: 'TheMealDB',
    developmentOnly: true,
    monthlyRequestBudget: 2000,
    maxRequestsPerMinute: 30,
    maxDetailLookups: 12,
    costMicrosPerRequest: 0,
    cacheTtl: Duration(minutes: 10),
  );

  final ProviderHttp http;
  final Catalogue catalogue;
  final ProviderPolicy policy;
  final String apiKey;
  final IngredientMapper _mapper;
  final DateTime Function() _now;
  final _detailCache = <String, (DateTime, ExternalRecipe?)>{};

  @override
  String get providerId => id;

  Uri _url(String path, Map<String, String> query) =>
      Uri.https(_host, '/api/json/v1/$apiKey/$path', query);

  /// How TheMealDB spells a food: lower case, underscores.
  static String queryName(String displayName) =>
      displayName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');

  @override
  Future<List<ExternalRecipe>> search(
    MealChoice choice,
    FoodFilter filter,
  ) async {
    // meal id -> (title, how many chosen foods listed it)
    final hits = <String, ({String title, int count})>{};
    var anyAnswered = false;
    ProviderUnavailable? lastError;
    for (final foodId in choice.ids) {
      final food = catalogue.food(foodId);
      if (food == null) continue;
      try {
        final json = await http.getJson(
          _url('filter.php', {'i': queryName(food.displayName)}),
        );
        anyAnswered = true;
        for (final m in _list(json)) {
          final mealId = _text(m['idMeal']);
          final title = _text(m['strMeal']);
          if (mealId == null || title == null) continue;
          final old = hits[mealId];
          hits[mealId] = (title: title, count: (old?.count ?? 0) + 1);
        }
      } on ProviderUnavailable catch (e) {
        lastError = e;
        // Out of budget or rate-limited: stop asking, use what we have.
        if (e.problem == ProviderProblem.budgetExhausted ||
            e.problem == ProviderProblem.rateLimited ||
            e.problem == ProviderProblem.disabled) {
          break;
        }
      }
    }
    if (!anyAnswered && lastError != null) throw lastError;

    final ranked = hits.entries.toList()
      ..sort((a, b) {
        final c = b.value.count.compareTo(a.value.count);
        return c != 0 ? c : a.value.title.compareTo(b.value.title);
      });
    final out = <ExternalRecipe>[];
    for (final entry in ranked.take(policy.maxDetailLookups)) {
      try {
        final recipe = await byId(entry.key);
        if (recipe != null) out.add(recipe);
      } on ProviderUnavailable catch (e) {
        if (out.isEmpty) lastError = e;
        if (e.problem == ProviderProblem.budgetExhausted ||
            e.problem == ProviderProblem.rateLimited) {
          break;
        }
      }
    }
    if (out.isEmpty && lastError != null && hits.isNotEmpty) throw lastError;
    return out;
  }

  @override
  Future<ExternalRecipe?> byId(String externalId) async {
    final now = _now();
    final cached = _detailCache[externalId];
    if (cached != null &&
        policy.cacheTtl > Duration.zero &&
        now.difference(cached.$1) < policy.cacheTtl) {
      return cached.$2;
    }
    final json = await http.getJson(_url('lookup.php', {'i': externalId}));
    final meals = _list(json);
    final recipe = meals.isEmpty ? null : parseMeal(meals.first);
    if (policy.cacheTtl > Duration.zero) {
      _detailCache[externalId] = (now, recipe);
    }
    return recipe;
  }

  /// One `lookup.php` meal as a normalised recipe, or null when it cannot be
  /// shown in full (no title or no method).
  ExternalRecipe? parseMeal(Map<String, Object?> m) {
    final mealId = _text(m['idMeal']);
    final title = _text(m['strMeal']);
    final steps = splitInstructions(_text(m['strInstructions']));
    if (mealId == null || title == null || steps.isEmpty) return null;

    final lines = <RecipeIngredient>[];
    final keyFoods = <String>[];
    for (var n = 1; n <= 20; n++) {
      final name = _text(m['strIngredient$n']);
      if (name == null) continue;
      final measure = _text(m['strMeasure$n']);
      final food = _mapper.map(name);
      lines.add(
        RecipeIngredient(
          label: '${name[0].toUpperCase()}${name.substring(1)}',
          foodId: food?.id,
          qtyText: measure,
          aisleId: food?.aisleId ?? 'other',
        ),
      );
      if (food != null && !keyFoods.contains(food.id)) keyFoods.add(food.id);
    }
    if (lines.isEmpty) return null;

    final category = _text(m['strCategory']);
    final area = _text(m['strArea']) ?? _text(m['strCountry']);
    final source = _text(m['strSource']);
    final intro = [?category, ?area].join(' · ');
    return ExternalRecipe(
      providerId: id,
      externalId: mealId,
      recipe: Recipe(
        id: 'x-$id-$mealId',
        title: title,
        // Replaced by the user's phase when it is shown.
        phase: Phase.follicular,
        category: _mealCategory(category),
        minutes: 0, // TheMealDB gives no times
        serves: 0, // nor servings
        intro: intro.isEmpty ? 'A recipe from TheMealDB.' : intro,
        whyThisPhase: '',
        imageUrl: _text(m['strMealThumb']),
        keyFoodIds: keyFoods,
        ingredients: lines,
        steps: steps,
      ),
      rights: RecipeRights(
        license: 'themealdb-test-key',
        attribution: source == null
            ? 'Recipe from TheMealDB'
            : 'Recipe from TheMealDB · original: ${Uri.tryParse(source)?.host ?? source}',
        sourceUrl: source ?? 'https://www.themealdb.com/meal/$mealId',
        mayDisplayFull: true,
        mayStore: false,
        requiresLinkBack: true,
        mayShowImage: true,
        mayPublish: false,
      ),
    );
  }

  static RecipeCategory _mealCategory(String? category) => switch (category) {
    'Breakfast' => RecipeCategory.breakfast,
    'Dessert' => RecipeCategory.snack,
    'Starter' || 'Side' => RecipeCategory.lunch,
    _ => RecipeCategory.dinner,
  };

  /// The method as separate steps: one per line, "Step 1" and "1." markers
  /// removed; a single long paragraph is split into sentences.
  static List<String> splitInstructions(String? text) {
    if (text == null) return const [];
    var lines =
        [
          for (final l in text.split(RegExp(r'\r?\n+')))
            l
                .replaceFirst(
                  RegExp(
                    r'^\s*(step\s*)?\d+\s*[.):-]?\s*',
                    caseSensitive: false,
                  ),
                  '',
                )
                .trim(),
        ]..removeWhere(
          (l) =>
              l.isEmpty ||
              RegExp(r'^step\s*\d*$', caseSensitive: false).hasMatch(l),
        );
    if (lines.length == 1 && lines.first.length > 280) {
      lines = [
        for (final s in lines.first.split(RegExp(r'(?<=[.!?])\s+')))
          if (s.trim().isNotEmpty) s.trim(),
      ];
    }
    return lines;
  }

  static List<Map<String, Object?>> _list(Object? json) {
    if (json is! Map<String, Object?>) return const [];
    final meals = json['meals'];
    if (meals is! List<Object?>) return const []; // null, or "None Found"
    return [
      for (final m in meals)
        if (m is Map<String, Object?>) m,
    ];
  }

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
