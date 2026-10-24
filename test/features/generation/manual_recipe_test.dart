import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/generation_result.dart';
import 'package:moon_cycle/features/generation/domain/manual_recipe.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';

import '../../helpers/test_catalogue.dart';

void main() {
  final foods = testCatalogue.foods;

  test('splitLines trims and drops bullets, numbers and blank lines', () {
    expect(
      splitLines('  - 2 eggs \n\n• salt\n1. Whisk\n2) Bake\n  \n3-way stuff'),
      ['2 eggs', 'salt', 'Whisk', 'Bake', '3-way stuff'],
    );
  });

  test('matchFood finds the longest catalogue name, whole words only', () {
    expect(matchFood('150 g green lentils', foods)?.id, isNotNull);
    expect(matchFood('a pinch of moon dust', foods), isNull);
    // "pea" must not match inside "peach"-like words.
    final peach = matchFood('2 ripe peaches', foods);
    expect(peach?.id, isNot('green-pea'));
  });

  test('a recipe needs a name and at least an ingredient or a step', () {
    const base = ManualRecipeInput(title: '', category: RecipeCategory.lunch);
    expect(base.problem, 'Give the recipe a name.');
    expect(
      const ManualRecipeInput(
        title: 'Soup',
        category: RecipeCategory.lunch,
      ).problem,
      'Add at least one ingredient or one step.',
    );
    expect(
      const ManualRecipeInput(
        title: 'Soup',
        category: RecipeCategory.lunch,
        stepsText: 'Simmer.',
      ).problem,
      isNull,
    );
  });

  test('buildManualRecipe keeps lines as written and matches foods', () {
    final r = buildManualRecipe(
      id: 'u-1',
      phase: Phase.luteal,
      foods: foods,
      input: const ManualRecipeInput(
        title: '  Gran’s soup ',
        category: RecipeCategory.breakfast,
        minutes: 30,
        notes: ' warm ',
        ingredientsText: '- 150 g green lentils\nA handful of moon dust\n',
        stepsText: '1. Simmer\n2. Serve',
      ),
    );
    expect(r.title, 'Gran’s soup');
    expect(r.id, 'u-1');
    expect((r.minutes, r.serves, r.intro, r.whyThisPhase), (30, 0, 'warm', ''));
    expect(r.ingredients.map((i) => i.label), [
      '150 g green lentils',
      'A handful of moon dust',
    ]);
    expect(r.ingredients[0].foodId, isNotNull); // recognised
    expect(
      r.ingredients[1].foodId,
      isNull,
    ); // kept as written, can't be checked
    expect(r.ingredients[1].aisleId, 'other');
    expect(r.keyFoodIds, [r.ingredients[0].foodId]);
    expect(r.steps, ['Simmer', 'Serve']);
    // The editor starts from the same text.
    final back = inputFromRecipe(r);
    expect(back.ingredientsText, '150 g green lentils\nA handful of moon dust');
    expect(back.minutes, 30);
    expect(back.serves, isNull);
  });

  group('storage', () {
    late AppDatabase db;
    late PersonalRecipeRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PersonalRecipeRepository(db);
    });
    tearDown(() => db.close());

    PersonalRecipe mk(String id, String owner, GenerationOrigin origin) =>
        PersonalRecipe(
          recipe: buildManualRecipe(
            id: id,
            phase: Phase.follicular,
            foods: foods,
            input: ManualRecipeInput(
              title: 'Recipe $id',
              category: RecipeCategory.lunch,
              stepsText: 'Do it.',
            ),
          ),
          ownerId: owner,
          idempotencyKey: 'k$id',
          fingerprint: '',
          provenance: Provenance(origin: origin, provider: 'p', model: 'm'),
          createdAt: DateTime(2026, 10, 20),
        );

    test(
      'local recipes show with the session user’s, never another’s',
      () async {
        await repo.save(mk('u-a', localRecipeOwnerId, GenerationOrigin.manual));
        await repo.save(mk('u-b', 'dev-local-user', GenerationOrigin.devMock));
        await repo.save(mk('u-c', 'someone-else', GenerationOrigin.cloud));
        final signedOut = await repo.allFor([localRecipeOwnerId]);
        expect(signedOut.map((r) => r.id), ['u-a']);
        final withSession = await repo.allFor([
          localRecipeOwnerId,
          'dev-local-user',
        ]);
        expect(withSession.map((r) => r.id).toSet(), {'u-a', 'u-b'});
        expect(withSession.firstWhere((r) => r.id == 'u-a').isManual, isTrue);
      },
    );

    test('updateRecipe changes the text but not the owner or origin', () async {
      final saved = await repo.save(
        mk('u-a', localRecipeOwnerId, GenerationOrigin.manual),
      );
      final edited = buildManualRecipe(
        id: 'u-a',
        phase: Phase.follicular,
        foods: foods,
        input: const ManualRecipeInput(
          title: 'Renamed',
          category: RecipeCategory.snack,
          stepsText: 'New step',
        ),
      );
      await repo.updateRecipe(saved.ownerId, 'u-a', edited);
      final got = (await repo.allFor([localRecipeOwnerId])).single;
      expect(got.recipe.title, 'Renamed');
      expect(got.recipe.steps, ['New step']);
      expect((got.ownerId, got.isManual), (localRecipeOwnerId, true));
      expect(got.lifecycle, RecipeLifecycle.privateSaved);
    });
  });
}
