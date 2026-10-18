import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';
import 'package:moon_cycle/features/discovery/data/providers/themealdb_client.dart';
import 'package:moon_cycle/features/discovery/domain/provider_policy.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';

import '../../helpers/fake_provider_http.dart';
import '../../helpers/test_catalogue.dart';

ProviderPolicy policy({
  int budget = 1000,
  int perMinute = 1000,
  int details = 12,
}) => TheMealDbClient.policyDefaults.copyWith(
  enabled: true,
  monthlyRequestBudget: budget,
  maxRequestsPerMinute: perMinute,
  maxDetailLookups: details,
);

TheMealDbClient client(
  FakeNetwork net, {
  ProviderPolicy? p,
  InMemoryUsageLedger? ledger,
  DateTime Function()? now,
}) {
  final pol = p ?? policy();
  return TheMealDbClient(
    http: ProviderHttp(
      policy: pol,
      ledger: ledger ?? InMemoryUsageLedger(),
      get: net.get,
    ),
    catalogue: testCatalogue,
    policy: pol,
    now: now,
  );
}

Map<String, Object?> meal(String id) =>
    ((readFixture('themealdb_lookups.json') as Map<String, Object?>)[id]!
            as Map<String, Object?>)['meals']!
        is List
    ? (((readFixture('themealdb_lookups.json') as Map<String, Object?>)[id]!
                      as Map<String, Object?>)['meals']!
                  as List<Object?>)
              .first!
          as Map<String, Object?>
    : {};

void main() {
  group('a meal becomes a normalised recipe', () {
    final c = client(mealDbNetwork());

    test('title, namespaced id, image, source and full method', () {
      final e = c.parseMeal(meal('53282'))!; // Algerian Carrots
      expect(e.recipe.id, 'x-themealdb-53282');
      expect(e.providerId, 'themealdb');
      expect(e.externalId, '53282');
      expect(e.recipe.title, 'Algerian Carrots');
      expect(e.recipe.imageUrl, startsWith('https://www.themealdb.com/'));
      expect(e.recipe.steps, isNotEmpty);
      expect(e.recipe.intro, contains('Side'));
    });

    test('rights: shown in full with credit, never stored or published', () {
      final r = c.parseMeal(meal('53282'))!.rights;
      expect(r.mayDisplayFull, isTrue);
      expect(r.mayStore, isFalse);
      expect(r.mayPublish, isFalse);
      expect(r.requiresLinkBack, isTrue);
      expect(r.attribution, startsWith('Recipe from TheMealDB'));
      expect(r.sourceUrl, isNotNull);
      expect(r.license, 'themealdb-test-key');
    });

    test('ingredients keep their wording and map to food ids only when '
        'reliable', () {
      final e = c.parseMeal(meal('53282'))!; // Water, Carrots, Olive Oil, Salt…
      final byLabel = {for (final l in e.recipe.ingredients) l.label: l};
      expect(byLabel['Carrots']!.foodId, 'carrot');
      expect(byLabel['Olive Oil']!.foodId, 'olive-oil');
      expect(byLabel['Water']!.foodId, isNull);
      expect(e.recipe.keyFoodIds, containsAll(['carrot', 'olive-oil']));
      // Quantities are kept as the provider wrote them.
      expect(byLabel['Carrots']!.qtyText, isNotNull);
    });

    test('plurals and capitals map, near-misses do not', () {
      final e = c.parseMeal(meal('53483'))!; // Black Eyed Peas, Garlic…
      final ids = {for (final l in e.recipe.ingredients) l.label: l.foodId};
      expect(ids['Black Eyed Peas'], 'black-eyed-pea');
      expect(ids['Garlic'], 'garlic');
      // Plain flour is wheat flour, and carries gluten even though the dataset
      // omits it.
      expect(ids['Plain Flour'], 'wheat-flour');
      final flour = e.recipe.ingredients.firstWhere(
        (l) => l.label == 'Plain Flour',
      );
      expect(flour.extraAllergenIds, contains('gluten'));
    });

    test('no times or servings are invented', () {
      final r = c.parseMeal(meal('53282'))!.recipe;
      expect(r.minutes, 0);
      expect(r.serves, 0);
    });

    test('missing title, method or ingredients: not shown', () {
      final m = {...meal('53282')};
      expect(c.parseMeal({...m, 'strInstructions': null}), isNull);
      expect(c.parseMeal({...m, 'strInstructions': '  '}), isNull);
      expect(c.parseMeal({...m, 'strMeal': ''}), isNull);
      expect(c.parseMeal({...m, 'idMeal': null}), isNull);
      final bare = {
        'idMeal': '1',
        'strMeal': 'X',
        'strInstructions': 'Cook it.',
      };
      expect(c.parseMeal(bare), isNull); // no ingredients
    });

    test('missing picture and source are handled', () {
      final m = {...meal('53282'), 'strMealThumb': null, 'strSource': null};
      final e = c.parseMeal(m)!;
      expect(e.recipe.imageUrl, isNull);
      expect(e.rights.sourceUrl, 'https://www.themealdb.com/meal/53282');
      expect(e.rights.attribution, 'Recipe from TheMealDB');
    });

    test('blank measures and gaps in the numbered fields are fine', () {
      final m = {
        ...meal('53282'),
        'strMeasure2': '',
        'strIngredient3': null,
        'strIngredient4': '   ',
      };
      final e = c.parseMeal(m)!;
      expect(
        e.recipe.ingredients.every((l) => l.label.trim().isNotEmpty),
        isTrue,
      );
    });

    test('the method splits into steps', () {
      expect(
        TheMealDbClient.splitInstructions(
          'STEP 1\r\nChop.\r\nstep 2\r\n2. Fry.',
        ),
        ['Chop.', 'Fry.'],
      );
      final long = '${'Mix the batter well. ' * 20}Serve warm.';
      expect(TheMealDbClient.splitInstructions(long).length, greaterThan(5));
      expect(TheMealDbClient.splitInstructions(null), isEmpty);
    });
  });

  group('searching', () {
    test(
      'one request per chosen food, then details of the best meals',
      () async {
        final net = mealDbNetwork();
        final found = await client(net)
            .search(MealChoice(['garlic']), FoodFilter.none);
        final filters = net.calls.where((u) => u.path.endsWith('filter.php'));
        expect(filters, hasLength(1));
        expect(filters.single.queryParameters['i'], 'garlic');
        expect(found, isNotEmpty);
        expect(found.length, lessThanOrEqualTo(12));
        // Official endpoint and the documented test key only.
        for (final u in net.calls) {
          expect(u.host, 'www.themealdb.com');
          expect(u.path, startsWith('/api/json/v1/1/'));
        }
      },
    );

    test('multi-word foods use the underscore spelling', () {
      expect(TheMealDbClient.queryName('Green pea'), 'green_pea');
      expect(TheMealDbClient.queryName(' Napa  cabbage '), 'napa_cabbage');
    });

    test(
      'meals listed for more of the chosen foods are fetched first',
      () async {
        // Meal 53282 is listed for both foods; the others for one.
        final both = {
          'meals': [
            {'idMeal': '53282', 'strMeal': 'Algerian Carrots'},
            {'idMeal': '53288', 'strMeal': 'Algerian Flafla'},
          ],
        };
        final one = {
          'meals': [
            {'idMeal': '53282', 'strMeal': 'Algerian Carrots'},
            {'idMeal': '53281', 'strMeal': 'Algerian Kefta'},
          ],
        };
        final net = mealDbNetwork(filters: {'carrot': both, 'garlic': one});
        final found = await client(
          net,
          p: policy(details: 1),
        ).search(MealChoice(['carrot', 'garlic']), FoodFilter.none);
        expect(found.single.externalId, '53282');
      },
    );

    test('the detail limit is respected', () async {
      final net = mealDbNetwork();
      await client(
        net,
        p: policy(details: 3),
      ).search(MealChoice(['garlic']), FoodFilter.none);
      expect(
        net.calls.where((u) => u.path.endsWith('lookup.php')),
        hasLength(3),
      );
    });

    test('"no meals" answers are an empty result, not an error', () async {
      final net = mealDbNetwork();
      expect(
        await client(net).search(MealChoice(['tofu']), FoodFilter.none),
        isEmpty,
      );
    });

    test('one food failing still returns the others', () async {
      final net = mealDbNetwork(failIngredients: {'kale'});
      final found = await client(net)
          .search(MealChoice(['kale', 'garlic']), FoodFilter.none);
      expect(found, isNotEmpty);
    });

    test('every food failing is reported as an outage', () async {
      final net = mealDbNetwork(failIngredients: {'kale', 'garlic'});
      await expectLater(
        client(net).search(MealChoice(['kale', 'garlic']), FoodFilter.none),
        throwsA(isA<ProviderUnavailable>()),
      );
    });
  });

  group('limits, usage and caching', () {
    test('requests are counted in the ledger', () async {
      final ledger = InMemoryUsageLedger();
      await client(
        mealDbNetwork(),
        ledger: ledger,
        p: policy(details: 2),
      ).search(MealChoice(['garlic']), FoodFilter.none);
      final u = await ledger.usage('themealdb', DateTime.now());
      expect(u.requests, 3); // one filter and two lookups
      expect(u.costMicros, 0); // the test key is free
    });

    test(
      'the monthly budget ends the search quietly with what it has',
      () async {
        final net = mealDbNetwork();
        final found = await client(
          net,
          p: policy(budget: 3),
        ).search(MealChoice(['garlic']), FoodFilter.none);
        expect(net.calls.length, 3);
        expect(found, hasLength(2));
      },
    );

    test('rate limiting stops further calls', () async {
      final net = mealDbNetwork();
      final found = await client(
        net,
        p: policy(perMinute: 2),
      ).search(MealChoice(['garlic']), FoodFilter.none);
      expect(net.calls.length, 2);
      expect(found, hasLength(1));
    });

    test('a fetched recipe is reused within its cache time only', () async {
      var t = DateTime(2026, 10, 5, 9);
      final net = mealDbNetwork();
      final c = client(net, now: () => t);
      await c.byId('53282');
      await c.byId('53282');
      expect(net.calls.length, 1);
      t = t.add(const Duration(minutes: 11));
      await c.byId('53282');
      expect(net.calls.length, 2);
    });

    test('with a zero cache time nothing is reused', () async {
      final net = mealDbNetwork();
      final c = client(net, p: policy().copyWith(cacheTtl: Duration.zero));
      await c.byId('53282');
      await c.byId('53282');
      expect(net.calls.length, 2);
    });

    test('byId for an unknown id is null', () async {
      expect(await client(mealDbNetwork()).byId('999'), isNull);
    });

    test('this provider is development-only until approved', () {
      expect(TheMealDbClient.policyDefaults.developmentOnly, isTrue);
      expect(TheMealDbClient.policyDefaults.enabled, isFalse);
      expect(TheMealDbClient.testKey, '1');
    });
  });
}
