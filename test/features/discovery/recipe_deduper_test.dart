import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_candidate.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_deduper.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_source.dart';

RecipeCandidate cand(
  String provider,
  String id,
  String title,
  List<String> foods,
) {
  final recipe = Recipe(
    id: provider == 'moon-cycle' ? id : 'x-$provider-$id',
    title: title,
    phase: Phase.luteal,
    category: RecipeCategory.dinner,
    minutes: 0,
    serves: 0,
    intro: '',
    whyThisPhase: '',
    keyFoodIds: foods,
    ingredients: [
      for (final f in foods)
        RecipeIngredient(label: f, foodId: f, aisleId: 'produce'),
    ],
    steps: const ['a', 'b', 'c'],
  );
  return RecipeCandidate(
    recipe: recipe,
    source: provider == 'moon-cycle'
        ? RecipeSource.internal
        : RecipeSource.externalApi,
    providerId: provider,
    rights: provider == 'moon-cycle'
        ? RecipeRights.moonCycle
        : const RecipeRights(license: 'x', mayStore: false),
    match: RecipeMatch(
      recipe: recipe,
      level: MatchLevel.complete,
      score: 100,
      coverage: 1,
      matchedIds: foods.take(1).toList(),
      missingIds: const [],
      extraFoodIds: const [],
    ),
  );
}

void main() {
  const deduper = RecipeDeduper();
  final stew = ['chickpea', 'spinach', 'onion', 'garlic'];

  test('the same provider and id is one recipe', () {
    final a = cand('p', '1', 'Stew', stew);
    final out = deduper.dedupe([a, a]);
    expect(out, hasLength(1));
  });

  test('the same title and mostly the same ingredients is one recipe, and the '
      'first (better ranked) copy is kept with provenance', () {
    final lib = cand('moon-cycle', 'lib-stew', 'Chickpea & Spinach Stew', stew);
    final a = cand('prova', '9', 'Chickpea and Spinach stew', stew);
    final b = cand('provb', '4', 'chickpea & spinach stew', [...stew, 'lemon']);
    final out = deduper.dedupe([lib, a, b]);
    expect(out, hasLength(1));
    expect(out.single.providerId, 'moon-cycle');
    expect(out.single.alsoFrom, ['prova', 'provb']);
    expect(out.single.rights.mayStore, isTrue); // the kept copy's own rights
  });

  test('the rights of the copy that is shown stay with it', () {
    final a = cand('prova', '1', 'Stew', stew);
    final b = cand('provb', '2', 'Stew', stew);
    final out = deduper.dedupe([a, b]).single;
    expect(out.providerId, 'prova');
    expect(out.rights.license, 'x');
  });

  test('the same title with different ingredients is NOT merged', () {
    final a = cand('prova', '1', 'Chicken Curry', [
      'chicken',
      'onion',
      'garlic',
      'ginger',
    ]);
    final b = cand('provb', '2', 'Chicken Curry', [
      'chicken',
      'coconut-milk',
      'spinach',
      'potato',
    ]);
    expect(deduper.dedupe([a, b]), hasLength(2));
  });

  test('similar ingredients with a different title is NOT merged', () {
    final a = cand('prova', '1', 'Spinach Soup', stew);
    final b = cand('provb', '2', 'Roast Chickpea Salad', stew);
    expect(deduper.dedupe([a, b]), hasLength(2));
  });

  test('close but different titles need strongly matching ingredients', () {
    final a = cand('prova', '1', 'Easy Chickpea Spinach Stew', stew);
    final close = cand('provb', '2', 'Chickpea Spinach Stew', stew);
    final far = cand('provc', '3', 'Chickpea Spinach Stew', [
      'chickpea',
      'spinach',
      'tomato',
      'cumin',
    ]);
    expect(deduper.dedupe([a, close]), hasLength(1));
    expect(deduper.dedupe([a, far]), hasLength(2));
  });

  test('recipes with too few identified ingredients are never merged by '
      'similarity', () {
    final a = cand('prova', '1', 'Stew', ['chickpea', 'spinach']);
    final b = cand('provb', '2', 'Stew', ['chickpea', 'spinach']);
    expect(deduper.dedupe([a, b]), hasLength(2));
  });

  test('order is preserved', () {
    final list = [
      cand('prova', '1', 'A dish', ['a', 'b', 'c']),
      cand('prova', '2', 'B dish', ['d', 'e', 'f']),
      cand('prova', '3', 'C dish', ['g', 'h', 'i']),
    ];
    expect(deduper.dedupe(list).map((c) => c.recipe.id), [
      'x-prova-1',
      'x-prova-2',
      'x-prova-3',
    ]);
  });
}
