import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';
import 'package:moon_cycle/features/discovery/data/providers/recipe_api_client.dart';
import 'package:moon_cycle/features/discovery/domain/provider_policy.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/fake_provider_http.dart';
import '../../helpers/test_catalogue.dart';

/// Candidate Provider B, against documentation-derived fixtures. It is never
/// configured or enabled in the app.
void main() {
  FakeNetwork network() => FakeNetwork((url) {
    final path = url.path;
    if (path.endsWith('/ingredients')) {
      return FakeNetwork.ok(readFixture('recipeapi_ingredients_chickpea.json'));
    }
    if (path.endsWith('/recipes')) {
      return FakeNetwork.ok(readFixture('recipeapi_recipes_chickpea.json'));
    }
    if (path.endsWith('/recipes/r-1')) {
      return FakeNetwork.ok(readFixture('recipeapi_detail_r1.json'));
    }
    if (path.endsWith('/recipes/r-3')) {
      return FakeNetwork.ok(readFixture('recipeapi_detail_r3.json'));
    }
    return (status: 404, body: '{}');
  });

  RecipeApiClient client(FakeNetwork net, {ProviderPolicy? p}) {
    final pol = (p ?? RecipeApiClient.policyDefaults).copyWith(enabled: true);
    return RecipeApiClient(
      http: ProviderHttp(
        policy: pol,
        ledger: InMemoryUsageLedger(),
        get: net.get,
      ),
      catalogue: testCatalogue,
      policy: pol,
      baseUrl: Uri.parse('https://proxy.example.test/functions/v1/recipes'),
    );
  }

  test('it is not enabled, and has the Developer plan limits', () {
    expect(RecipeApiClient.policyDefaults.enabled, isFalse);
    expect(RecipeApiClient.policyDefaults.monthlyRequestBudget, 250);
    expect(RecipeApiClient.policyDefaults.cacheTtl, const Duration(hours: 24));
  });

  test('a detail becomes a normalised recipe', () {
    final c = client(network());
    final e = c.parseRecipe(
      (readFixture('recipeapi_detail_r1.json') as Map<String, Object?>)['data']!
          as Map<String, Object?>,
    )!;
    expect(e.recipe.id, 'x-recipeapi-r-1');
    expect(e.recipe.title, 'Chickpea & Spinach Stew');
    expect(e.recipe.minutes, 45);
    expect(e.recipe.serves, 4);
    expect(e.recipe.steps, hasLength(3));
    final q = {for (final l in e.recipe.ingredients) l.label: l.qtyText};
    expect(q['Chickpeas'], '400 g');
    expect(q['Spinach'], '200 g');
    expect(q['Onion'], '1');
    expect(q['Garlic'], '2.5 cloves');
    expect(q['Smoked paprika'], isNull);
    expect(e.recipe.keyFoodIds, containsAll(['chickpea', 'spinach', 'onion']));
    final byLabel = {for (final l in e.recipe.ingredients) l.label: l.foodId};
    expect(byLabel['Smoked paprika'], isNull); // unmapped, not guessed
  });

  test('rights: full display, no attribution, nothing stored, no photo', () {
    final e = client(network()).parseRecipe(
      (readFixture('recipeapi_detail_r1.json') as Map<String, Object?>)['data']!
          as Map<String, Object?>,
    )!;
    expect(e.rights.mayDisplayFull, isTrue);
    expect(e.rights.attribution, isNull);
    expect(e.rights.mayStore, isFalse);
    expect(e.rights.mayShowImage, isFalse);
    expect(e.recipe.imageUrl, isNull); // falls back to the Moon Cycle art
  });

  test('missing method, name or ingredients: not shown', () {
    final c = client(network());
    final d = Map.of(
      (readFixture('recipeapi_detail_r1.json') as Map<String, Object?>)['data']!
          as Map<String, Object?>,
    );
    expect(c.parseRecipe({...d, 'instructions': <Object?>[]}), isNull);
    expect(c.parseRecipe({...d, 'name': null}), isNull);
    expect(c.parseRecipe({...d, 'ingredients': <Object?>[]}), isNull);
  });

  test('times and servings parse, and absence is not invented', () {
    expect(RecipeApiClient.isoMinutes('PT1H15M'), 75);
    expect(RecipeApiClient.isoMinutes('PT45M'), 45);
    expect(RecipeApiClient.isoMinutes('PT2H'), 120);
    expect(RecipeApiClient.isoMinutes(null), isNull);
    expect(RecipeApiClient.isoMinutes('soon'), isNull);
    expect(RecipeApiClient.servings('4 servings'), 4);
    expect(RecipeApiClient.servings(null), isNull);
  });

  group('searching', () {
    test(
      'free searches first; only the best recipes are opened (paid)',
      () async {
        final net = network();
        final found = await client(net)
            .search(MealChoice(['chickpea']), FoodFilter.none);
        expect(found.map((e) => e.externalId), containsAll(['r-1', 'r-3']));
        final paid = net.calls.where((u) => u.path.contains('/recipes/r-'));
        expect(paid.length, found.length + 1); // r-2 had no fixture: 404
      },
    );

    test('an ingredient with no exact match is not guessed', () async {
      final net = network();
      final found = await client(net).search(
        MealChoice(['chickpea', 'tofu']), // the fixture has no "Tofu"
        FoodFilter.none,
      );
      expect(found, isNotEmpty);
      expect(
        net.calls.where((u) => u.queryParameters['q'] == 'tofu'),
        hasLength(1),
      );
    });

    test('a vegan is only offered recipes the provider flags Vegan', () async {
      final found = await client(network())
          .search(MealChoice(['chickpea']), const FoodFilter(diet: Diet.vegan));
      expect(found.map((e) => e.externalId), ['r-1']);
    });

    test(
      'an allergen needs the matching "-Free" flag and no warning',
      () async {
        final found = await client(network()).search(
          MealChoice(['chickpea']),
          const FoodFilter(
            avoidances: [AllergenAvoidance(id: 'a', allergenId: 'dairy')],
          ),
        );
        // r-2 is flagged "not suitable for Dairy-Free"; r-3 has no dairy flag.
        expect(found.map((e) => e.externalId), ['r-1']);
      },
    );

    test(
      'an allergen the provider cannot label is never assumed safe',
      () async {
        final found = await client(network()).search(
          MealChoice(['chickpea']),
          const FoodFilter(
            avoidances: [AllergenAvoidance(id: 'a', allergenId: 'mustard')],
          ),
        );
        expect(found, isEmpty);
      },
    );

    test(
      'with no restrictions, recipes without dietary data still appear',
      () async {
        final found = await client(network())
            .search(MealChoice(['chickpea']), FoodFilter.none);
        expect(found, isNotEmpty);
      },
    );

    test('the budget of unique recipes is enforced', () async {
      final net = network();
      final found = await client(
        net,
        p: RecipeApiClient.policyDefaults.copyWith(monthlyRequestBudget: 2),
      ).search(MealChoice(['chickpea']), FoodFilter.none);
      // Two paid lookups (one is a 404 and still counts), then the budget stops.
      expect(found.map((e) => e.externalId), ['r-1']);
    });
  });
}
