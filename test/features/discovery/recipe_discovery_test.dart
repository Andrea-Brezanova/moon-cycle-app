import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/discovery/data/recipe_sources.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_candidate.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_discovery.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_source.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

const bowl = MealChoice(
  proteinId: 'black-turtle-bean',
  baseId: 'quinoa',
  plantIds: ['yellow-bell-pepper', 'orange'],
);

/// A choice no bundled recipe uses completely.
const unusual = MealChoice(
  proteinId: 'tempeh',
  baseId: 'buckwheat',
  plantIds: ['kale', 'pomegranate'],
);

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

Recipe externalRecipe(MealChoice choice, {String id = 'x-demo-1'}) => Recipe(
  id: id,
  title: 'External tempeh bowl',
  phase: Phase.luteal,
  category: RecipeCategory.dinner,
  minutes: 30,
  serves: 2,
  intro: 'A bowl.',
  whyThisPhase: '',
  keyFoodIds: choice.ids,
  ingredients: [
    for (final id in choice.ids)
      RecipeIngredient(label: id, foodId: id, aisleId: 'produce'),
  ],
  steps: const ['Cook it.', 'Mix it.', 'Serve it.'],
);

const providerRights = RecipeRights(
  license: 'demo-provider',
  attribution: 'Recipe from Demo',
  sourceUrl: 'https://example.com/r/1',
  requiresLinkBack: true,
  mayStore: false,
);

void main() {
  final internal = InternalRecipeSource(testCatalogue);

  test(
    'internal complete match is returned and later sources are not asked',
    () async {
      final client = FakeClient([
        ExternalRecipe(recipe: externalRecipe(bowl), rights: providerRights),
      ]);
      final d = RecipeDiscovery([
        internal,
        ExternalRecipeSource(client, testCatalogue),
      ]);
      final r = await d.discover(bowl, FoodFilter.none);
      expect(r.complete.first.recipe.id, 'black-bean-quinoa-orange-bowl');
      expect(r.completeSource, RecipeSource.internal);
      expect(r.complete.first.rights.license, 'moon-cycle');
      expect(r.needsGeneration, isFalse);
      expect(client.calls, 0);
    },
  );

  test(
    'no internal match falls to the external provider, with its rights',
    () async {
      final client = FakeClient([
        ExternalRecipe(recipe: externalRecipe(unusual), rights: providerRights),
      ]);
      final r = await RecipeDiscovery([
        internal,
        ExternalRecipeSource(client, testCatalogue),
      ]).discover(unusual, FoodFilter.none);
      expect(r.completeSource, RecipeSource.externalApi);
      final c = r.complete.single;
      expect(c.source, RecipeSource.externalApi);
      expect(c.rights.attribution, 'Recipe from Demo');
      expect(c.rights.mayStore, isFalse);
      expect(c.rights.mayPublish, isFalse);
      expect(r.needsGeneration, isFalse);
    },
  );

  test(
    'external recipes whose terms forbid full display are dropped',
    () async {
      final client = FakeClient([
        ExternalRecipe(
          recipe: externalRecipe(unusual),
          rights: const RecipeRights(
            license: 'summary-only',
            mayDisplayFull: false,
          ),
        ),
      ]);
      final r = await RecipeDiscovery([
        internal,
        ExternalRecipeSource(client, testCatalogue),
      ]).discover(unusual, FoodFilter.none);
      expect(r.complete, isEmpty);
      expect(r.needsGeneration, isTrue);
    },
  );

  test('external recipes obey the same diet and avoidance filter', () async {
    final client = FakeClient([
      ExternalRecipe(recipe: externalRecipe(unusual), rights: providerRights),
    ]);
    final r =
        await RecipeDiscovery([ExternalRecipeSource(client, testCatalogue)])
            .discover(
              unusual,
              const FoodFilter(
                avoidances: [FoodItemAvoidance(id: 'a', foodId: 'tempeh')],
              ),
            );
    expect(r.complete, isEmpty);
  });

  test(
    'a failing external provider is skipped; the result still comes back',
    () async {
      final r = await RecipeDiscovery([
        internal,
        ExternalRecipeSource(FakeClient(const [], fail: true), testCatalogue),
      ]).discover(unusual, FoodFilter.none);
      expect(r.failedSources, [RecipeSource.externalApi]);
      expect(r.needsGeneration, isTrue);
    },
  );

  test('with nothing complete anywhere, generation is the fallback and '
      'partial matches are only suggestions', () async {
    const nearly = MealChoice(
      proteinId: 'black-turtle-bean',
      baseId: 'quinoa',
      plantIds: ['yellow-bell-pepper', 'orange', 'kale'],
    );
    final r = await RecipeDiscovery([
      internal,
      ExternalRecipeSource(const NoExternalRecipeClient(), testCatalogue),
    ]).discover(nearly, FoodFilter.none);
    expect(r.complete, isEmpty);
    expect(r.needsGeneration, isTrue);
    expect(r.partial, isNotEmpty);
    expect(r.partial.every((c) => !c.isComplete), isTrue);
    expect(r.partial.first.match.missingIds, ['kale']);
    expect(r.partial.length, lessThanOrEqualTo(5));
  });

  test(
    'the production default has no external provider and finds nothing',
    () async {
      final found = await ExternalRecipeSource(
        const NoExternalRecipeClient(),
        testCatalogue,
      ).find(bowl, FoodFilter.none);
      expect(found, isEmpty);
    },
  );
}
