import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/generation/application/recipe_creator.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/generation_failure.dart';
import 'package:moon_cycle/features/generation/domain/generation_request.dart';
import 'package:moon_cycle/features/generation/domain/generation_result.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';
import 'package:moon_cycle/features/generation/domain/recipe_image_service.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';

GenerationRequest request({
  String key = 'k1',
  String protein = 'green-lentil',
  String base = 'farro',
  List<String> plants = const ['spinach', 'carrot'],
  Phase phase = Phase.menstrual,
}) => GenerationRequest(
  idempotencyKey: key,
  phase: phase,
  proteinId: protein,
  baseId: base,
  plantIds: plants,
);

void main() {
  late AppDatabase db;
  late PersonalRecipeRepository repo;
  late DevMockGenerationService service;
  late PlaceholderRecipeImageService images;
  var filter = FoodFilter.none;
  AuthSession? session = const AuthSession(userId: 'user-a');
  var n = 0;

  RecipeCreator creator() => RecipeCreator(
    service: service,
    imageService: images,
    repository: repo,
    catalogue: testCatalogue,
    filter: () => filter,
    session: () => session,
    newRecipeId: () => 'id${++n}',
    now: () => DateTime.utc(2026, 10, 17),
  );

  DevMockGenerationService mock({
    List<GenerationFailure> failures = const [],
    int invalid = 0,
  }) => DevMockGenerationService(
    catalogue: testCatalogue,
    delay: Duration.zero,
    failures: failures,
    invalidAttempts: invalid,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PersonalRecipeRepository(db);
    service = mock();
    images = PlaceholderRecipeImageService(delay: Duration.zero);
    filter = FoodFilter.none;
    session = const AuthSession(userId: 'user-a');
    n = 0;
  });
  tearDown(() => db.close());

  test('creates a recipe and saves it privately, with provenance', () async {
    final steps = <CreationStep>[];
    final out = await creator().create(request(), onStep: steps.add);
    final saved = (out as Created).recipe;
    expect(saved.id, 'u-id1');
    expect(saved.ownerId, 'user-a');
    expect(saved.lifecycle, RecipeLifecycle.privateSaved);
    expect(saved.provenance.origin, GenerationOrigin.devMock);
    expect(saved.isDevSample, isTrue);
    expect(saved.recipe.phase, Phase.menstrual);
    expect(saved.recipe.keyFoodIds, [
      'green-lentil',
      'farro',
      'spinach',
      'carrot',
    ]);
    expect(steps, [
      CreationStep.checking,
      CreationStep.writing,
      CreationStep.validating,
      CreationStep.saving,
    ]);
    // It is in the library and survives a round trip.
    final stored = await repo.byId('user-a', 'u-id1');
    expect(stored!.recipe.title, saved.recipe.title);
    expect(stored.recipe.ingredients.length, saved.recipe.ingredients.length);
    expect(stored.imageStatus, ImageStatus.pending);
  });

  test('every selection the mock makes passes validation', () async {
    const picks = [
      ('chicken', 'brown-rice', ['broccoli', 'carrot']),
      ('eggs', 'farro', ['spinach', 'carrot', 'lemon']),
      ('salmon', 'brown-rice', ['broccoli', 'spinach']),
      ('tofu', 'brown-rice', ['broccoli', 'carrot']),
      ('kidney-bean', 'brown-rice', ['spinach', 'carrot']),
      ('beef', 'farro', ['onion', 'carrot']),
      ('feta', 'farro', ['spinach', 'carrot']),
    ];
    for (final (i, (p, b, plants)) in picks.indexed) {
      final out = await creator().create(
        request(key: 'p$i', protein: p, base: b, plants: plants),
      );
      expect(out, isA<Created>(), reason: '$p $b $plants -> $out');
    }
  });

  test(
    'a retry of the same tap returns the saved recipe, not a second',
    () async {
      final first = await creator().create(request()) as Created;
      final again = await creator().create(request());
      expect(again, isA<Existing>());
      expect((again as Existing).sameRequest, isTrue);
      expect(again.recipe.id, first.recipe.id);
      expect(service.calls, 1);
      expect((await repo.all('user-a')), hasLength(1));
    },
  );

  test(
    'the same foods again offer the saved recipe; "another" makes a new one',
    () async {
      final first = await creator().create(request()) as Created;
      final dup = await creator().create(
        request(key: 'k2', plants: const ['carrot', 'spinach']),
      );
      expect((dup as Existing).sameRequest, isFalse);
      expect(dup.recipe.id, first.recipe.id);
      expect(service.calls, 1);

      final another = await creator().create(
        request(key: 'k3'),
        allowSameSelection: true,
      );
      expect(another, isA<Created>());
      expect(await repo.all('user-a'), hasLength(2));
    },
  );

  test('a signed-out user cannot create or save', () async {
    session = null;
    final out = await creator().create(request());
    expect(
      (out as CreationFailed).failure.kind,
      GenerationFailureKind.notSignedIn,
    );
    expect(service.calls, 0);
  });

  test('another account never sees or reuses a recipe', () async {
    await creator().create(request());
    session = const AuthSession(userId: 'user-b');
    final out = await creator().create(request());
    expect(out, isA<Created>());
    expect(await repo.all('user-b'), hasLength(1));
    expect(await repo.byId('user-b', 'u-id1'), isNull);
    expect(await repo.byId('user-a', 'u-id1'), isNotNull);
  });

  group('selection checks', () {
    test('wrong number of plants, repeated or unknown foods', () async {
      for (final r in [
        request(plants: const ['spinach']),
        request(plants: const ['spinach', 'carrot', 'lemon', 'onion']),
        request(plants: const ['spinach', 'spinach']),
        request(protein: 'moon-dust'),
      ]) {
        final out = await creator().create(r);
        expect(
          (out as CreationFailed).failure.kind,
          GenerationFailureKind.invalidSelection,
          reason: '$r',
        );
      }
      expect(service.calls, 0);
    });

    test('a food the user avoids is refused before any call', () async {
      filter = const FoodFilter(
        diet: Diet.vegan,
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'gluten')],
      );
      final out = await creator().create(request());
      expect(
        (out as CreationFailed).failure.kind,
        GenerationFailureKind.invalidSelection,
      );
      expect(service.calls, 0);
    });
  });

  group('failure recovery', () {
    test(
      'a timeout fails cleanly; the retry with the same key succeeds',
      () async {
        service = mock(
          failures: const [GenerationFailure(GenerationFailureKind.timeout)],
        );
        final first = await creator().create(request());
        final failure = (first as CreationFailed).failure;
        expect(failure.kind, GenerationFailureKind.timeout);
        expect(failure.retryable, isTrue);
        expect(await repo.all('user-a'), isEmpty);

        final retry = await creator().create(request());
        expect(retry, isA<Created>());
        expect(await repo.all('user-a'), hasLength(1));
      },
    );

    test('non-retryable failures say so', () {
      for (final k in [
        GenerationFailureKind.unavailable,
        GenerationFailureKind.notSignedIn,
        GenerationFailureKind.notEntitled,
        GenerationFailureKind.quotaExceeded,
        GenerationFailureKind.invalidSelection,
      ]) {
        expect(GenerationFailure(k).retryable, isFalse, reason: '$k');
      }
    });

    test('an invalid first answer is repaired by one retry', () async {
      service = mock(invalid: 1);
      final out = await creator().create(request());
      expect(out, isA<Created>());
      expect(service.calls, 2);
    });

    test('two invalid answers fail without saving anything', () async {
      service = mock(invalid: 2);
      final out = await creator().create(request());
      expect(
        (out as CreationFailed).failure.kind,
        GenerationFailureKind.invalidResult,
      );
      expect(service.calls, 2);
      expect(await repo.all('user-a'), isEmpty);
    });

    test('the unavailable service reports unavailable', () async {
      final c = RecipeCreator(
        service: const UnavailableGenerationService(),
        imageService: const UnavailableImageService(),
        repository: repo,
        catalogue: testCatalogue,
        filter: () => filter,
        session: () => session,
        newRecipeId: () => 'x',
        now: DateTime.now,
      );
      final out = await c.create(request());
      expect(
        (out as CreationFailed).failure.kind,
        GenerationFailureKind.unavailable,
      );
    });
  });

  group('the picture is optional and recoverable', () {
    test('a ready picture is a stored reference', () async {
      final saved = (await creator().create(request()) as Created).recipe;
      await creator().makeImage(saved);
      final stored = await repo.byId('user-a', saved.id);
      expect(stored!.imageStatus, ImageStatus.ready);
      expect(stored.imageRef!.kind, RecipeImageKind.placeholder);
    });

    test('a failed picture leaves the recipe intact; retry recovers', () async {
      images = PlaceholderRecipeImageService(
        delay: Duration.zero,
        failTimes: 1,
      );
      final saved = (await creator().create(request()) as Created).recipe;
      await creator().makeImage(saved);
      var stored = await repo.byId('user-a', saved.id);
      expect(stored!.imageStatus, ImageStatus.failed);
      expect(stored.recipe.title, saved.recipe.title);

      await creator().makeImage(stored);
      stored = await repo.byId('user-a', saved.id);
      expect(stored!.imageStatus, ImageStatus.ready);
    });
  });

  group('Try Something New requests', () {
    GenerationRequest tryNew(
      int variant, {
      String key = 'k',
      List<String>? foods,
    }) => GenerationRequest.tryNew(
      idempotencyKey: '$key$variant',
      phase: Phase.luteal,
      foodIds: foods ?? const ['kale', 'carrot', 'tofu'],
      variant: variant,
    );

    test('three variants give three different, valid recipes', () async {
      final titles = <String>{};
      for (var v = 0; v < 3; v++) {
        final out = await creator().create(tryNew(v));
        titles.add((out as Created).recipe.recipe.title);
      }
      expect(titles, hasLength(3));
      expect(await repo.all('user-a'), hasLength(3));
    });

    test('the fingerprint depends on the foods and the variant, not order', () {
      expect(
        tryNew(0, foods: ['kale', 'carrot', 'tofu']).fingerprint,
        tryNew(0, foods: ['tofu', 'kale', 'carrot']).fingerprint,
      );
      expect(tryNew(0).fingerprint, isNot(tryNew(1).fingerprint));
      expect(tryNew(0).toJson()['kind'], 'try_new');
    });

    test('the same trio and variant is retrieved, not made again', () async {
      await creator().create(tryNew(1, key: 'a'));
      final again = await creator().create(tryNew(1, key: 'b'));
      expect(again, isA<Existing>());
      expect(service.calls, 1);
    });

    test(
      'two foods, or an avoided food, are refused before any call',
      () async {
        for (final r in [
          tryNew(0, foods: const ['kale', 'carrot']),
          tryNew(0, foods: const ['kale', 'kale', 'tofu']),
        ]) {
          final out = await creator().create(r);
          expect(
            (out as CreationFailed).failure.kind,
            GenerationFailureKind.invalidSelection,
          );
        }
        filter = const FoodFilter(
          diet: Diet.vegan,
          avoidances: [AllergenAvoidance(id: 'a', allergenId: 'soy')],
        );
        final out = await creator().create(tryNew(0));
        expect(
          (out as CreationFailed).failure.kind,
          GenerationFailureKind.invalidSelection,
        );
        expect(service.calls, 0);
      },
    );
  });

  test('deleting tombstones the recipe and frees its key', () async {
    final saved = (await creator().create(request()) as Created).recipe;
    await repo.delete('user-a', saved.id);
    expect(await repo.all('user-a'), isEmpty);
    final again = await creator().create(request());
    expect(again, isA<Created>());
  });
}
