import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/discovery/data/recipe_sources.dart';
import 'package:moon_cycle/features/discovery/domain/provider_policy.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_discovery.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_source.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/test_catalogue.dart';

class FakeClient implements ExternalRecipeClient {
  FakeClient(
    this.providerId,
    this.results, {
    this.problem,
    this.delay = Duration.zero,
  });

  @override
  final String providerId;
  final List<ExternalRecipe> results;
  final ProviderProblem? problem;
  final Duration delay;
  int calls = 0;
  DateTime? startedAt;

  @override
  Future<List<ExternalRecipe>> search(
    MealChoice choice,
    FoodFilter filter,
  ) async {
    calls++;
    startedAt = DateTime.now();
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (problem != null) throw ProviderUnavailable(problem!);
    return results;
  }

  @override
  Future<ExternalRecipe?> byId(String externalId) async => null;
}

Recipe recipe(
  String provider,
  String id,
  List<String> foods, {
  String? title,
  List<String> unmapped = const [],
}) => Recipe(
  id: 'x-$provider-$id',
  title: title ?? 'Recipe $provider $id',
  phase: Phase.luteal,
  category: RecipeCategory.dinner,
  minutes: 0,
  serves: 0,
  intro: 'A dish.',
  whyThisPhase: '',
  imageUrl: 'https://example.com/$id.jpg',
  keyFoodIds: foods,
  ingredients: [
    for (final f in foods)
      RecipeIngredient(label: f, foodId: f, aisleId: 'produce'),
    for (final u in unmapped) RecipeIngredient(label: u, aisleId: 'other'),
  ],
  steps: const ['Cook it.', 'Mix it.', 'Serve it.'],
);

const rights = RecipeRights(
  license: 'demo',
  attribution: 'Recipe from Demo',
  sourceUrl: 'https://example.com/r/1',
  requiresLinkBack: true,
  mayStore: false,
  mayShowImage: false,
);

ExternalRecipe ext(String provider, Recipe r, {RecipeRights? rt}) =>
    ExternalRecipe(
      recipe: r,
      rights: rt ?? rights,
      providerId: provider,
      externalId: r.id.split('-').last,
    );

ExternalRecipeSource source(FakeClient client, {ProviderPolicy? policy}) =>
    ExternalRecipeSource(
      client,
      testCatalogue,
      policy:
          policy ??
          ProviderPolicy(
            id: client.providerId,
            name: client.providerId,
            enabled: true,
            timeout: const Duration(milliseconds: 200),
          ),
    );

void main() {
  final internal = InternalRecipeSource(testCatalogue);
  final choice = MealChoice(['quinoa', 'orange']);

  test(
    'library recipes come back ranked, with the foods they matched',
    () async {
      final r = await RecipeDiscovery([internal])
          .discover(choice, FoodFilter.none);
      expect(r.results.first.recipe.id, 'black-bean-quinoa-orange-bowl');
      expect(r.results.first.isComplete, isTrue);
      expect(r.results.first.source, RecipeSource.internal);
      expect(r.results.first.providerId, 'moon-cycle');
      expect(r.results.first.rights.license, 'moon-cycle');
      expect(r.results.first.matchCount(2), '2 of 2');
      final counts = [for (final c in r.results) c.match.matchedIds.length];
      expect([...counts]..sort((a, b) => b.compareTo(a)), counts);
      expect(counts.last, 1); // partial matches included, last
    },
  );

  test('at the same number of matched foods the library comes first', () async {
    final a = FakeClient('prova', [
      ext('prova', recipe('prova', '1', ['quinoa'])),
    ]);
    final r = await RecipeDiscovery([internal, source(a)])
        .discover(MealChoice(['quinoa']), FoodFilter.none);
    final firstExternal = r.results.indexWhere(
      (c) => c.source == RecipeSource.externalApi,
    );
    expect(firstExternal, greaterThan(0));
    expect(
      r.results
          .take(firstExternal)
          .every((c) => c.source == RecipeSource.internal),
      isTrue,
    );
  });

  test(
    'a recipe matching more foods outranks library recipes matching fewer',
    () async {
      final a = FakeClient('prova', [
        ext('prova', recipe('prova', '1', ['quinoa', 'orange', 'kale'])),
      ]);
      final r = await RecipeDiscovery([internal, source(a)])
          .discover(MealChoice(['quinoa', 'orange', 'kale']), FoodFilter.none);
      expect(r.results.first.recipe.id, 'x-prova-1');
    },
  );

  test('every provider is asked, at the same time', () async {
    final a = FakeClient('prova', [], delay: const Duration(milliseconds: 80));
    final b = FakeClient('provb', [], delay: const Duration(milliseconds: 80));
    final started = DateTime.now();
    await RecipeDiscovery([internal, source(a), source(b)])
        .discover(choice, FoodFilter.none);
    expect(DateTime.now().difference(started).inMilliseconds, lessThan(150));
    expect(a.calls, 1);
    expect(b.calls, 1);
    expect(
      a.startedAt!.difference(b.startedAt!).inMilliseconds.abs(),
      lessThan(40),
    );
  });

  test('results from two providers and the library are combined and ranked '
      'together', () async {
    final a = FakeClient('prova', [
      ext('prova', recipe('prova', '1', ['quinoa', 'orange', 'kale'])),
    ]);
    final b = FakeClient('provb', [
      ext('provb', recipe('provb', '2', ['quinoa', 'salmon'])),
    ]);
    final r = await RecipeDiscovery([internal, source(a), source(b)])
        .discover(choice, FoodFilter.none);
    final ids = r.results.map((c) => c.recipe.id).toList();
    expect(ids, contains('x-prova-1'));
    expect(ids, contains('x-provb-2'));
    expect(ids, contains('black-bean-quinoa-orange-bowl'));
    // Complete matches (2 of 2) come before the one-of-two recipe.
    final x2 = r.results.firstWhere((c) => c.recipe.id == 'x-provb-2');
    expect(x2.isComplete, isFalse);
    expect(x2.match.matchedIds, ['quinoa']);
    for (final c in r.results.where((c) => c.isComplete)) {
      expect(r.results.indexOf(c), lessThan(r.results.indexOf(x2)));
    }
    expect(
      r.countsByProvider.keys,
      containsAll(['moon-cycle', 'prova', 'provb']),
    );
    final fromA = r.results.firstWhere((c) => c.recipe.id == 'x-prova-1');
    expect(fromA.source, RecipeSource.externalApi);
    expect(fromA.providerId, 'prova');
    expect(fromA.rights.attribution, 'Recipe from Demo');
    expect(fromA.rights.mayStore, isFalse);
    expect(fromA.rights.mayPublish, isFalse);
  });

  group('one provider failing never stops the search', () {
    for (final problem in ProviderProblem.values) {
      test('${problem.name}: the others still answer', () async {
        final bad = FakeClient('prova', [], problem: problem);
        final good = FakeClient('provb', [
          ext('provb', recipe('provb', '2', ['quinoa', 'orange'])),
        ]);
        final r = await RecipeDiscovery([internal, source(bad), source(good)])
            .discover(choice, FoodFilter.none);
        expect(r.failedSources, {'prova': problem});
        expect(r.results.map((c) => c.recipe.id), contains('x-provb-2'));
        expect(
          r.results.map((c) => c.recipe.id),
          contains('black-bean-quinoa-orange-bowl'),
        );
      });
    }

    test('an unexpected error is contained too', () async {
      final r = await RecipeDiscovery([internal, _Throwing()])
          .discover(choice, FoodFilter.none);
      expect(r.failedSources.keys, ['boom']);
      expect(r.results, isNotEmpty);
    });

    test('a provider that hangs is cut off by its own timeout', () async {
      final slow = FakeClient('prova', [], delay: const Duration(seconds: 5));
      final started = DateTime.now();
      final r = await RecipeDiscovery([internal, source(slow)])
          .discover(choice, FoodFilter.none);
      expect(DateTime.now().difference(started).inSeconds, lessThan(2));
      expect(r.failedSources['prova'], ProviderProblem.timeout);
      expect(r.results, isNotEmpty);
    });

    test('a disabled provider is not even asked', () async {
      final off = FakeClient('prova', [
        ext('prova', recipe('prova', '1', ['quinoa'])),
      ]);
      final r = await RecipeDiscovery([
        internal,
        source(
          off,
          policy: const ProviderPolicy(id: 'prova', name: 'A'),
        ),
      ]).discover(choice, FoodFilter.none);
      expect(off.calls, 0);
      expect(r.results.every((c) => c.providerId == 'moon-cycle'), isTrue);
    });
  });

  group('rules every external recipe must meet', () {
    test('terms that forbid full display drop the recipe', () async {
      final c = FakeClient('prova', [
        ext(
          'prova',
          recipe('prova', '1', ['quinoa']),
          rt: const RecipeRights(license: 'summary', mayDisplayFull: false),
        ),
      ]);
      final r = await RecipeDiscovery([source(c)])
          .discover(choice, FoodFilter.none);
      expect(r.isEmpty, isTrue);
    });

    test('the diet and avoidance filter apply to them', () async {
      final c = FakeClient('prova', [
        ext('prova', recipe('prova', '1', ['quinoa', 'orange'])),
        ext('prova', recipe('prova', '2', ['quinoa', 'salmon'])),
      ]);
      final vegan = await RecipeDiscovery([source(c)])
          .discover(choice, const FoodFilter(diet: Diet.vegan));
      expect(vegan.results.map((e) => e.recipe.id), ['x-prova-1']);
      final noOrange = await RecipeDiscovery([source(c)]).discover(
        choice,
        const FoodFilter(
          avoidances: [FoodItemAvoidance(id: 'a', foodId: 'orange')],
        ),
      );
      expect(noOrange.results.map((e) => e.recipe.id), ['x-prova-2']);
    });

    test('an ingredient we cannot identify is never assumed safe', () async {
      final c = FakeClient('prova', [
        ext('prova', recipe('prova', '1', ['quinoa'], unmapped: ['Soy sauce'])),
        ext(
          'prova',
          recipe('prova', '2', ['quinoa'], unmapped: ['Salt', 'Water']),
        ),
      ]);
      // No restrictions: both are shown.
      final free = await RecipeDiscovery([source(c)])
          .discover(MealChoice(['quinoa']), FoodFilter.none);
      expect(free.results, hasLength(2));
      // With any restriction, the one with an unknown ingredient is dropped;
      // plain salt and water are fine.
      final restricted = await RecipeDiscovery([source(c)]).discover(
        MealChoice(['quinoa']),
        const FoodFilter(
          avoidances: [AllergenAvoidance(id: 'a', allergenId: 'gluten')],
        ),
      );
      expect(restricted.results.map((e) => e.recipe.id), ['x-prova-2']);
    });

    test(
      'a typed avoidance catches an unidentified ingredient by name',
      () async {
        final c = FakeClient('prova', [
          ext('prova', recipe('prova', '2', ['quinoa'], unmapped: ['Salt'])),
          ext('prova', recipe('prova', '3', ['quinoa'], unmapped: ['Water'])),
        ]);
        final r = await RecipeDiscovery([source(c)]).discover(
          MealChoice(['quinoa']),
          const FoodFilter(
            avoidances: [CustomAvoidance(id: 'c', label: 'salt')],
          ),
        );
        expect(r.results.map((e) => e.recipe.id), ['x-prova-3']);
      },
    );

    test('external recipes take the user’s phase for display', () async {
      final c = FakeClient('prova', [
        ext('prova', recipe('prova', '1', ['quinoa'])),
      ]);
      final r = await RecipeDiscovery([source(c)]).discover(
        MealChoice(['quinoa']),
        FoodFilter.none,
        currentPhase: Phase.menstrual,
      );
      expect(r.results.single.recipe.phase, Phase.menstrual);
    });
  });

  test(
    'foods that no recipe uses give an empty result, never a generated one',
    () async {
      final r = await RecipeDiscovery([internal])
          .discover(MealChoice(['moon-dust']), FoodFilter.none);
      expect(r.isEmpty, isTrue);
      expect(
        r.results.any((c) => c.source == RecipeSource.aiGenerated),
        isFalse,
      );
    },
  );

  test('with no external provider the library works alone', () async {
    final r = await RecipeDiscovery([internal])
        .discover(choice, FoodFilter.none);
    expect(r.failedSources, isEmpty);
    expect(r.results.every((c) => c.source == RecipeSource.internal), isTrue);
    expect(
      await const NoExternalRecipeClient().search(choice, FoodFilter.none),
      isEmpty,
    );
  });
}

class _Throwing implements RecipeSourceProvider {
  @override
  RecipeSource get source => RecipeSource.externalApi;
  @override
  String get providerId => 'boom';
  @override
  Future<List<Never>> find(
    MealChoice choice,
    FoodFilter filter, {
    Phase? currentPhase,
  }) async => throw StateError('boom');
}
