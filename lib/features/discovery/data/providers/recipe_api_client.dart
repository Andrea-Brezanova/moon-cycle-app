import '../../../../core/domain/phase.dart';
import '../../../content/domain/catalogue.dart';
import '../../../content/domain/food_filter.dart';
import '../../../content/domain/recipe.dart';
import '../../../content/domain/text_match.dart';
import '../../../preferences/domain/diet.dart';
import '../../domain/ingredient_mapper.dart';
import '../../domain/provider_policy.dart';
import '../../domain/recipe_matcher.dart';
import '../../domain/recipe_source.dart';
import '../recipe_sources.dart';
import 'ingredient_lines.dart';
import 'provider_http.dart';

/// **Candidate Provider B: Recipe API (recipe-api.com). Built and tested
/// against documented fixtures only; NOT configured, NOT enabled, never called.**
///
/// Written from the provider's public docs (see `docs/external-recipe-api-
/// evaluation.md`). Two things are unverified until a trial key exists, and the
/// parser is deliberately tolerant of both: the exact shape of an ingredient's
/// amount, and the real size of the collection.
///
/// The provider key must stay on a server, so the app would reach it through a
/// Supabase Edge Function that adds `X-API-Key`; [baseUrl] is that proxy.
///
/// - Ingredient search is free but takes ingredient UUIDs, and a multi-UUID
///   search means *all of them*. So a search resolves each chosen food to a UUID
///   (free), lists recipes for each food separately (free) and ranks by how many
///   foods listed a recipe.
/// - Opening a full recipe costs one of a small monthly allowance of unique
///   recipes, so only the best few are fetched.
class RecipeApiClient implements ExternalRecipeClient {
  RecipeApiClient({
    required this.http,
    required this.catalogue,
    required this.policy,
    required this.baseUrl,
  }) : _mapper = IngredientMapper(catalogue);

  static const id = 'recipeapi';

  /// Developer plan, as listed on the provider's pricing page: $29 a month,
  /// 250 unique recipes, 60 requests a minute, 24-hour caching.
  static const policyDefaults = ProviderPolicy(
    id: id,
    name: 'Recipe API',
    monthlyRequestBudget: 250,
    maxRequestsPerMinute: 60,
    maxDetailLookups: 6,
    costMicrosPerRequest: 116000, // $29 / 250 recipes
    cacheTtl: Duration(hours: 24),
  );

  final ProviderHttp http;
  final Catalogue catalogue;
  final ProviderPolicy policy;
  final Uri baseUrl;
  final IngredientMapper _mapper;

  @override
  String get providerId => id;

  Uri _url(String path, [Map<String, String>? query]) => baseUrl.replace(
    path: '${baseUrl.path}/$path'.replaceAll('//', '/'),
    queryParameters: query,
  );

  @override
  Future<List<ExternalRecipe>> search(
    MealChoice choice,
    FoodFilter filter,
  ) async {
    final hits = <String, ({String name, int count})>{};
    var anyAnswered = false;
    ProviderUnavailable? lastError;
    for (final foodId in choice.ids) {
      final food = catalogue.food(foodId);
      if (food == null) continue;
      try {
        final ingredientIds = await _ingredientIds(food.displayName);
        // A recipe listed for several forms of one food counts once.
        final seen = <String>{};
        for (final ingredientId in ingredientIds) {
          final json = await http.getJson(
            _url('recipes', {'ingredients': ingredientId, 'per_page': '25'}),
            free: true,
          );
          anyAnswered = true;
          for (final r in _data(json)) {
            final rid = _text(r['id']);
            final name = _text(r['name']);
            if (rid == null || name == null) continue;
            final dietary = _dietary(r);
            if (dietary != null) _flagsById['x-$id-$rid'] = dietary;
            // A recipe the provider itself marks unsuitable is dropped before
            // it can cost a lookup.
            if (!_flagsAllow(filter, dietary)) continue;
            if (!seen.add(rid)) continue;
            final old = hits[rid];
            hits[rid] = (name: name, count: (old?.count ?? 0) + 1);
          }
        }
      } on ProviderUnavailable catch (e) {
        lastError = e;
        if (_stops(e)) break;
      }
    }
    if (!anyAnswered && lastError != null) throw lastError;
    final ranked = hits.entries.toList()
      ..sort((a, b) {
        final c = b.value.count.compareTo(a.value.count);
        return c != 0 ? c : a.value.name.compareTo(b.value.name);
      });
    final out = <ExternalRecipe>[];
    for (final e in ranked.take(policy.maxDetailLookups)) {
      try {
        final recipe = await byId(e.key);
        if (recipe != null && _providerFlagsAllow(filter, recipe)) {
          out.add(recipe);
        }
      } on ProviderUnavailable catch (err) {
        if (_stops(err)) break; // one bad recipe is skipped, a limit ends it
      }
    }
    return out;
  }

  static bool _stops(ProviderUnavailable e) =>
      e.problem == ProviderProblem.budgetExhausted ||
      e.problem == ProviderProblem.rateLimited ||
      e.problem == ProviderProblem.disabled;

  /// Words that may precede a food's name in the provider's ingredient list
  /// without changing what the food is ("canned chickpeas", "dried chickpeas").
  static const _sameFoodPrefixes = {
    'canned',
    'tinned',
    'dried',
    'dry',
    'fresh',
    'raw',
    'frozen',
    'cooked',
    'baby',
    'large',
    'leaf',
    'organic',
  };

  static const _maxIngredientIds = 2;

  /// The provider's ingredient ids for [name]: its exact match when there is one,
  /// otherwise at most [_maxIngredientIds] plain forms of the same food. The
  /// real list is mostly USDA entries ("Chickpeas (garbanzo beans, ...), canned,
  /// drained solids"), flours and pastes, so anything with a comma, brackets or
  /// another noun in front is never used: "chickpea flour" is not chickpeas.
  Future<List<String>> _ingredientIds(String name) async {
    final json = await http.getJson(
      _url('ingredients', {'q': name.toLowerCase()}),
      free: true,
    );
    final wanted = normaliseName(name);
    final entries = _data(json);
    for (final i in entries) {
      if (normaliseName(_text(i['name']) ?? '') == wanted) {
        final id = _text(i['id']);
        if (id != null) return [id];
      }
    }
    final forms = <String>[];
    for (final i in entries) {
      final raw = _text(i['name']) ?? '';
      if (raw.contains(',') || raw.contains('(')) continue;
      final words = normaliseName(raw).split(' ');
      if (words.length < 2 || words.length > 3) continue;
      final last = words.last;
      final base = last.endsWith('s')
          ? last.substring(0, last.length - 1)
          : last;
      if (base != wanted && last != wanted) continue;
      if (!words.take(words.length - 1).every(_sameFoodPrefixes.contains)) {
        continue;
      }
      final id = _text(i['id']);
      if (id != null && !forms.contains(id)) forms.add(id);
      if (forms.length == _maxIngredientIds) break;
    }
    return forms; // nothing safe: never guess a different ingredient
  }

  /// Each recipe's dietary info as the provider listed it.
  final _flagsById = <String, _Dietary>{};

  @override
  Future<ExternalRecipe?> byId(String externalId) async {
    final json = await http.getJson(_url('recipes/$externalId'));
    if (json is! Map<String, Object?>) return null;
    final data = json['data'];
    if (data is! Map<String, Object?>) return null;
    return parseRecipe(data);
  }

  /// A detail response as a normalised recipe, or null when it has no title or
  /// no method (it cannot be shown in full).
  ExternalRecipe? parseRecipe(Map<String, Object?> d) {
    final rid = _text(d['id']);
    final title = _text(d['name']);
    final steps = [for (final s in _list(d['instructions'])) ?_text(s['text'])];
    if (rid == null || title == null || steps.isEmpty) return null;
    final lines = <RecipeIngredient>[];
    final keyFoods = <String>[];
    for (final group in _list(d['ingredients'])) {
      for (final item in _list(group['items'])) {
        final name = _text(item['name']);
        if (name == null) continue;
        final line = ingredientLine(_mapper, name, quantity: _quantity(item));
        lines.add(line);
        final id = line.foodId;
        if (id != null && !keyFoods.contains(id)) keyFoods.add(id);
      }
    }
    if (lines.isEmpty) return null;
    final meta = d['meta'];
    final Map<String, Object?> metaMap = meta is Map<String, Object?>
        ? meta
        : const {};
    final dietary = _dietary(d);
    if (dietary != null) _flagsById['x-$id-$rid'] = dietary;
    return ExternalRecipe(
      providerId: id,
      externalId: rid,
      recipe: Recipe(
        id: 'x-$id-$rid',
        title: title,
        phase: Phase.follicular, // replaced by the user's phase when shown
        category: _category(_text(d['category'])),
        minutes: isoMinutes(_text(metaMap['total_time'])) ?? 0,
        serves: servings(_text(metaMap['yields'])) ?? 0,
        intro: _text(d['description']) ?? '',
        whyThisPhase: '',
        keyFoodIds: keyFoods,
        ingredients: lines,
        steps: steps,
      ),
      rights: const RecipeRights(
        license: 'recipe-api-developer',
        attribution: null, // the provider requires none
        mayDisplayFull: true,
        mayStore: false, // 24-hour caching only: nothing is saved
        mayShowImage: false, // the recipe object has no photograph
        mayPublish: false,
      ),
    );
  }

  /// "PT1H15M" → 75, "PT45M" → 45, "PT2H" → 120.
  static int? isoMinutes(String? iso) {
    if (iso == null) return null;
    final m = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?$').firstMatch(iso);
    if (m == null) return null;
    final total =
        (int.tryParse(m.group(1) ?? '') ?? 0) * 60 +
        (int.tryParse(m.group(2) ?? '') ?? 0);
    return total == 0 ? null : total;
  }

  /// "4 servings" → 4.
  static int? servings(String? yields) => yields == null
      ? null
      : int.tryParse(RegExp(r'\d+').stringMatch(yields) ?? '');

  /// An ingredient's amount as text. The provider's exact field names are not
  /// documented, so several are tried and anything else is left blank.
  static String? _quantity(Map<String, Object?> item) {
    final direct = _text(item['display']) ?? _text(item['quantity_text']);
    if (direct != null) return direct;
    final amount = item['amount'] ?? item['quantity'];
    final unit = _text(item['unit']);
    if (amount is num) {
      final n = amount == amount.roundToDouble()
          ? amount.toInt().toString()
          : amount.toString();
      return unit == null ? n : '$n $unit';
    }
    return _text(amount);
  }

  static RecipeCategory _category(String? c) => switch (c) {
    'Breakfast' => RecipeCategory.breakfast,
    'Lunch' => RecipeCategory.lunch,
    'Snack' || 'Dessert' => RecipeCategory.snack,
    _ => RecipeCategory.dinner,
  };

  static _Dietary? _dietary(Map<String, Object?> r) {
    final d = r['dietary'];
    if (d is! Map<String, Object?>) return null;
    List<String> strings(Object? v) => [
      if (v is List<Object?>)
        for (final x in v)
          if (x is String) x,
    ];
    return _Dietary(strings(d['flags']), strings(d['not_suitable_for']));
  }

  /// Uses the provider's own dietary flags **in addition to** our own food-id
  /// check: a vegan needs a "Vegan" flag, an allergen needs the matching
  /// "-Free" flag, and a "not suitable for" warning naming it excludes the
  /// recipe. A recipe with no dietary information is not assumed safe.
  bool _providerFlagsAllow(FoodFilter filter, ExternalRecipe e) =>
      _flagsAllow(filter, _flagsById[e.recipe.id]);

  static const _allergenFlag = {
    'gluten': 'gluten-free',
    'dairy': 'dairy-free',
    'peanut': 'nut-free',
    'tree-nut': 'nut-free',
    'egg': 'egg-free',
    'soy': 'soy-free',
    'shellfish': 'shellfish-free',
    'fish': 'fish-free',
    'sesame': 'sesame-free',
  };

  /// Words that, in one of the provider's free-text "not suitable for" warnings,
  /// mean this allergen ("Individuals with tree nut allergies due to pine nuts").
  static const _allergenWords = {
    'gluten': ['gluten', 'wheat', 'celiac', 'coeliac', 'barley', 'rye'],
    'dairy': ['dairy', 'lactose', 'milk', 'butter', 'cheese', 'cream'],
    'peanut': ['peanut', 'nut'],
    'tree-nut': ['tree nut', 'nut', 'almond', 'cashew', 'walnut', 'pine'],
    'egg': ['egg'],
    'soy': ['soy'],
    'shellfish': ['shellfish', 'shrimp', 'prawn', 'crab', 'lobster'],
    'fish': ['fish'],
    'sesame': ['sesame'],
  };

  bool _flagsAllow(FoodFilter filter, _Dietary? d) {
    if (filter.isEmpty) return true;
    if (d == null) return false;
    final flags = {for (final f in d.flags) f.toLowerCase()};
    final warns = d.notSuitableFor.map((w) => w.toLowerCase()).toList();
    bool needs(String flag) => flags.contains(flag.toLowerCase());
    switch (filter.diet) {
      case Diet.vegan:
        if (!needs('vegan')) return false;
        if (warns.any((w) => w.contains('vegan'))) return false;
      case Diet.vegetarian:
        if (!needs('vegetarian') && !needs('vegan')) return false;
        if (warns.any((w) => w.contains('vegetarian'))) return false;
      case Diet.pescatarian:
        if (!needs('pescatarian') && !needs('vegetarian') && !needs('vegan')) {
          return false;
        }
      case Diet.omnivore:
        break;
    }
    for (final allergen in filter.allergenIds) {
      final flag = _allergenFlag[allergen];
      if (flag == null) return false; // an allergen we cannot check
      if (!needs(flag)) return false;
      final words = _allergenWords[allergen] ?? [allergen];
      if (warns.any((w) => words.any(w.contains))) return false;
    }
    return true;
  }

  static List<Map<String, Object?>> _data(Object? json) =>
      json is Map<String, Object?> ? _list(json['data']) : const [];

  static List<Map<String, Object?>> _list(Object? v) => [
    if (v is List<Object?>)
      for (final x in v)
        if (x is Map<String, Object?>) x,
  ];

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}

class _Dietary {
  const _Dietary(this.flags, this.notSuitableFor);
  final List<String> flags;
  final List<String> notSuitableFor;
}
