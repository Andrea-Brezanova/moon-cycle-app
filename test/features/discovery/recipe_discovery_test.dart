import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/discovery/data/recipe_sources.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_discovery.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_source.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

class FakeClient implements ExternalRecipeClient {
  FakeClient(this.results, {this.fail = false});
  final List<ExternalRecipe> results;
  final bool fail;
  int calls = 0;

  @override
  Future<List<ExternalRecipe>> search(
    MealChoice choice,
    FoodFilter filter,
  ) async {
    calls++;
    if (fail) throw StateError('provider down');
    return results;
  }
}

Recipe externalRecipe(List<String> foods, {String id = 'x-demo-1'}) => Recipe(
  id: id,
  title: 'External $id',
  phase: Phase.luteal,
  category: RecipeCategory.dinner,
  minutes: 25,
  serves: 2,
  intro: 'A dish.',
  whyThisPhase: '',
  imageUrl: 'https://example.com/$id.jpg',
  keyFoodIds: foods,
  ingredients: [
    for (final f in foods)
      RecipeIngredient(label: f, foodId: f, aisleId: 'produce'),
  ],
  steps: const ['Cook it.', 'Mix it.', 'Serve it.'],
);

const providerRights = RecipeRights(
  license: 'demo-provider',
  attribution: 'Recipe from Demo',
  sourceUrl: 'https://example.com/r/1',
  requiresLinkBack: true,
  mayStore: false,
  mayShowImage: false,
);

void main() {
  final internal = InternalRecipeSource(testCatalogue);
  final choice = MealChoice(['quinoa', 'orange']);

  test(
    'library recipes come back ranked, with the foods they matched',
    () async {
      final r = await RecipeDiscovery([internal])
          .discover(choice, FoodFilter.none);
      expect(r.results, isNotEmpty);
      expect(r.results.first.recipe.id, 'black-bean-quinoa-orange-bowl');
      expect(r.results.first.isComplete, isTrue);
      expect(r.results.first.source, RecipeSource.internal);
      expect(r.results.first.rights.license, 'moon-cycle');
      expect(r.results.first.matchCount(2), '2 of 2');
      // Partial matches (one of two) are included, after the complete ones.
      final counts = [for (final c in r.results) c.match.matchedIds.length];
      expect([...counts]..sort((a, b) => b.compareTo(a)), counts);
      expect(counts.last, 1);
    },
  );

  test(
    'external and library results are combined and ranked together',
    () async {
      final client = FakeClient([
        ExternalRecipe(
          recipe: externalRecipe(['quinoa', 'orange', 'kale']),
          rights: providerRights,
        ),
      ]);
      final r = await RecipeDiscovery([
        internal,
        ExternalRecipeSource(client, testCatalogue),
      ]).discover(choice, FoodFilter.none);
      expect(client.calls, 1); // asked even though the library has matches
      final ids = r.results.map((c) => c.recipe.id).toList();
      expect(ids, contains('x-demo-1'));
      expect(ids, contains('black-bean-quinoa-orange-bowl'));
      // Both use every chosen food; the simpler recipe ranks first.
      expect(
        r.results.where((c) => c.recipe.id == 'x-demo-1').single.isComplete,
        isTrue,
      );
      final external = r.results.firstWhere((c) => c.recipe.id == 'x-demo-1');
      expect(external.source, RecipeSource.externalApi);
      expect(external.rights.attribution, 'Recipe from Demo');
      expect(external.rights.mayShowImage, isFalse);
      expect(external.rights.mayStore, isFalse);
      expect(external.rights.mayPublish, isFalse);
    },
  );

  test('an external recipe with more matches outranks a library one', () async {
    final client = FakeClient([
      ExternalRecipe(
        recipe: externalRecipe(['quinoa', 'orange', 'salmon']),
        rights: providerRights,
      ),
    ]);
    final three = MealChoice(['quinoa', 'orange', 'salmon']);
    final r = await RecipeDiscovery([
      internal,
      ExternalRecipeSource(client, testCatalogue),
    ]).discover(three, FoodFilter.none);
    expect(r.results.first.recipe.id, 'x-demo-1');
    expect(r.results.first.isComplete, isTrue);
  });

  test(
    'external recipes whose terms forbid full display are dropped',
    () async {
      final client = FakeClient([
        ExternalRecipe(
          recipe: externalRecipe(['quinoa', 'orange']),
          rights: const RecipeRights(
            license: 'summary-only',
            mayDisplayFull: false,
          ),
        ),
      ]);
      final r = await RecipeDiscovery([
        ExternalRecipeSource(client, testCatalogue),
      ]).discover(choice, FoodFilter.none);
      expect(r.isEmpty, isTrue);
    },
  );

  test('external recipes obey the same diet and avoidance filter', () async {
    final client = FakeClient([
      ExternalRecipe(
        recipe: externalRecipe(['quinoa', 'orange']),
        rights: providerRights,
      ),
    ]);
    final r =
        await RecipeDiscovery([ExternalRecipeSource(client, testCatalogue)])
            .discover(
              choice,
              const FoodFilter(
                avoidances: [FoodItemAvoidance(id: 'a', foodId: 'orange')],
              ),
            );
    expect(r.isEmpty, isTrue);
  });

  test('a failing provider is skipped; the library still answers', () async {
    final r = await RecipeDiscovery([
      internal,
      ExternalRecipeSource(FakeClient(const [], fail: true), testCatalogue),
    ]).discover(choice, FoodFilter.none);
    expect(r.failedSources, [RecipeSource.externalApi]);
    expect(r.results, isNotEmpty);
  });

  test(
    'the production default has no provider and the library works alone',
    () async {
      final r = await RecipeDiscovery([
        internal,
        ExternalRecipeSource(const NoExternalRecipeClient(), testCatalogue),
      ]).discover(choice, FoodFilter.none);
      expect(r.failedSources, isEmpty);
      expect(r.results.every((c) => c.source == RecipeSource.internal), isTrue);
    },
  );

  test('duplicates by recipe id are shown once', () async {
    final client = FakeClient([
      ExternalRecipe(
        recipe: externalRecipe(['quinoa'], id: 'x-demo-9'),
        rights: providerRights,
      ),
      ExternalRecipe(
        recipe: externalRecipe(['quinoa'], id: 'x-demo-9'),
        rights: providerRights,
      ),
    ]);
    final r = await RecipeDiscovery([
      ExternalRecipeSource(client, testCatalogue),
    ]).discover(MealChoice(['quinoa']), FoodFilter.none);
    expect(r.results.where((c) => c.recipe.id == 'x-demo-9'), hasLength(1));
  });

  test(
    'foods that no recipe uses give an empty result, not a generated one',
    () async {
      final r = await RecipeDiscovery([internal])
          .discover(MealChoice(['moon-dust']), FoodFilter.none);
      expect(r.isEmpty, isTrue);
      expect(r.complete, isEmpty);
    },
  );
}
