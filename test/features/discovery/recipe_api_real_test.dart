import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';
import 'package:moon_cycle/features/discovery/data/providers/recipe_api_client.dart';
import 'package:moon_cycle/features/discovery/domain/ingredient_mapper.dart';
import 'package:moon_cycle/features/discovery/domain/provider_policy.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/fake_provider_http.dart';
import '../../helpers/test_catalogue.dart';

/// Recipe API against real responses captured on 2026-10-18 (trimmed, no key or
/// account data), not documentation. Never calls the network.
void main() {
  const skillet = '28acb36d-68ba-42b0-b628-9874b007f3d5';
  const omelette = '599e324c-c8c4-47dd-af48-fff599e69186';

  Map<String, Object?> detail(String name) =>
      (readFixture('recipeapi_real_detail_$name.json')
              as Map<String, Object?>)['data']!
          as Map<String, Object?>;

  FakeNetwork network({Object? list}) => FakeNetwork((url) {
    final path = url.path;
    if (path.endsWith('/ingredients')) {
      final q = url.queryParameters['q'];
      return switch (q) {
        'spinach' => FakeNetwork.ok(
          readFixture('recipeapi_real_ingredients_spinach.json'),
        ),
        'chickpea' => FakeNetwork.ok(
          readFixture('recipeapi_real_ingredients_chickpea.json'),
        ),
        _ => FakeNetwork.ok({'data': <Object?>[]}),
      };
    }
    if (path.endsWith('/recipes')) {
      final id = url.queryParameters['ingredients'];
      // The captured list is the real one for "baby spinach" (the probe took
      // the first search hit); it stands in for the exact "spinach" ids, whose
      // lists were not fetched. Every chickpea form was empty.
      return id == '00222f5e-5864-40ef-a0ba-e10e9da8426d'
          ? FakeNetwork.ok(
              list ?? readFixture('recipeapi_real_recipes_spinach.json'),
            )
          : FakeNetwork.ok(readFixture('recipeapi_real_recipes_empty.json'));
    }
    if (path.endsWith('/recipes/$skillet')) {
      return FakeNetwork.ok({'data': detail('skillet')});
    }
    if (path.endsWith('/recipes/$omelette')) {
      return FakeNetwork.ok({'data': detail('omelette')});
    }
    return (status: 404, body: '{}'); // not captured: never fetched live
  });

  RecipeApiClient client(FakeNetwork net) {
    final pol = RecipeApiClient.policyDefaults.copyWith(enabled: true);
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

  group('a real detail', () {
    test('title, time, servings, method and quantities', () {
      final e = client(network()).parseRecipe(detail('skillet'))!;
      expect(e.recipe.title, 'Italian Chicken and Spinach Skillet');
      expect(e.recipe.minutes, 30);
      expect(e.recipe.serves, 4);
      expect(e.recipe.steps, hasLength(11));
      final q = {
        for (final l in e.recipe.ingredients) l.label.toLowerCase(): l.qtyText,
      };
      expect(q['chicken breast'], '600 g');
      expect(q['olive oil'], '30 ml');
      expect(q['garlic'], '4'); // a count has no unit
      expect(q['baby spinach'], '150 g');
    });

    test('the response has no photo, source or licence field', () {
      final d = detail('skillet');
      expect(
        d.keys.where(
          (k) => RegExp('image|photo|licen|credit|url|author').hasMatch(k),
        ),
        isEmpty,
      );
      final e = client(network()).parseRecipe(d)!;
      expect(e.recipe.imageUrl, isNull);
      expect(e.rights.mayShowImage, isFalse);
    });

    test('ingredient understanding on the two real recipes', () {
      final m = IngredientMapper(testCatalogue);
      final c = client(network());
      var lines = 0, identified = 0;
      final unknown = <String>[];
      for (final n in ['skillet', 'omelette']) {
        for (final l in c.parseRecipe(detail(n))!.recipe.ingredients) {
          lines++;
          if (l.foodId != null || m.classify(l.label).isIdentified) {
            identified++;
          } else {
            unknown.add(l.label);
          }
        }
      }
      // ignore: avoid_print
      print('REALAPI lines=$lines identified=$identified unknown=$unknown');
      expect(identified, greaterThan(lines ~/ 2));
    });
  });

  group('searching with real shapes', () {
    test('spinach: exact ingredient, then only the flagged-suitable open', () async {
      final net = network();
      final found = await client(net).search(
        MealChoice(['spinach']),
        const FoodFilter(diet: Diet.vegetarian),
      );
      // Of the ten listed, only recipes flagged Vegetarian/Vegan can be opened;
      // only the omelette has a captured detail.
      expect(found.map((e) => e.externalId), [omelette]);
      final opened = net.calls
          .where((u) => RegExp(r'/recipes/[0-9a-f-]{36}$').hasMatch(u.path))
          .length;
      // 7 of the 10 are Vegetarian or Vegan (3 are not), and at most 6 are opened.
      expect(opened, 6);
    });

    test('a vegan sees only Vegan-flagged recipes opened', () async {
      final net = network();
      await client(net)
          .search(MealChoice(['spinach']), const FoodFilter(diet: Diet.vegan));
      final opened = net.calls
          .where((u) => RegExp(r'/recipes/[0-9a-f-]{36}$').hasMatch(u.path))
          .length;
      expect(opened, 3);
    });

    test(
      'a dairy avoider loses recipes with a dairy warning or no flag',
      () async {
        final found = await client(network()).search(
          MealChoice(['spinach']),
          const FoodFilter(
            avoidances: [AllergenAvoidance(id: 'a', allergenId: 'dairy')],
          ),
        );
        expect(found.map((e) => e.externalId), isNot(contains(skillet)));
      },
    );

    test('free-text warnings use allergen words, not only our ids', () async {
      final list = {
        'data': [
          {
            'id': omelette,
            'name': 'Pesto soup',
            'dietary': {
              'flags': ['Nut-Free'],
              'not_suitable_for': [
                'Individuals with tree nut allergies due to pine nuts in pesto',
              ],
            },
          },
        ],
      };
      final found = await client(network(list: list)).search(
        MealChoice(['spinach']),
        const FoodFilter(
          avoidances: [AllergenAvoidance(id: 'a', allergenId: 'tree-nut')],
        ),
      );
      expect(found, isEmpty);
    });

    test(
      'chickpea: plain forms are tried, flours and USDA entries are not',
      () async {
        final net = network();
        final found = await client(net)
            .search(MealChoice(['chickpea']), FoodFilter.none);
        expect(found, isEmpty); // the real index had no recipe for either form
        final asked = net.calls
            .where((u) => u.path.endsWith('/recipes'))
            .map((u) => u.queryParameters['ingredients'])
            .toList();
        expect(asked, [
          '693538c2-09f5-4a24-9460-0d968be35a2f', // canned chickpeas
          'b0066137-2c3e-4dab-9b88-41b32f1f2666', // dried chickpeas
        ]);
        expect(
          net.calls.where(
            (u) => RegExp(r'/recipes/[0-9a-f-]{36}$').hasMatch(u.path),
          ),
          isEmpty,
          reason: 'nothing found, so no paid lookup is made',
        );
      },
    );
  });
}
