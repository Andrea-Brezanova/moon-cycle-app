import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/foods/application/meal_selection.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/generation_failure.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';

import '../../../helpers/test_catalogue.dart';

const _complete = MealSelection(
  proteinId: 'green-lentil',
  baseId: 'farro',
  plantIds: ['spinach', 'carrot'],
);

ProviderContainer make({bool debugBuild = true, bool devFlavourUnlock = true}) {
  final db = AppDatabase(NativeDatabase.memory());
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(FoodFilter.none),
      actualPhaseProvider.overrideWithValue(Phase.menstrual),
      debugPreviewAllowedProvider.overrideWithValue(debugBuild),
      debugUnlockAtStartProvider.overrideWithValue(devFlavourUnlock),
    ],
  );
  addTearDown(() async {
    c.dispose();
    await db.close();
  });
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('the development mock cannot exist outside a debug dev build', () {
    test('release / profile build: unavailable, no session, no mock', () {
      final c = make(debugBuild: false);
      expect(c.read(devGenerationAllowedProvider), isFalse);
      expect(c.read(generationAvailableProvider), isFalse);
      expect(c.read(authSessionProvider), isNull);
      expect(
        c.read(recipeGenerationServiceProvider),
        isA<UnavailableGenerationService>(),
      );
      expect(
        c.read(recipeImageServiceProvider),
        isA<UnavailableImageService>(),
      );
    });

    test('prod flavour (unlock-at-start false): unavailable', () {
      final c = make(devFlavourUnlock: false);
      expect(c.read(generationAvailableProvider), isFalse);
      expect(c.read(authSessionProvider), isNull);
    });

    test('debug dev build: mock service and a development session', () {
      final c = make();
      expect(c.read(generationAvailableProvider), isTrue);
      expect(c.read(authSessionProvider)!.isDevelopment, isTrue);
      expect(
        c.read(recipeGenerationServiceProvider),
        isA<DevMockGenerationService>(),
      );
    });

    test('the Premium switch in Settings does not open server access', () {
      // The client Premium gate is presentation; creation depends on the
      // service and session, which this switch does not touch.
      final c = make(debugBuild: false);
      c.read(debugPremiumPreviewProvider.notifier).toggle();
      expect(c.read(generationAvailableProvider), isFalse);
    });
  });

  group('creation controller', () {
    test('creates, saves privately and ends with the recipe', () async {
      final c = make();
      final controller = c.read(recipeCreationProvider.notifier);
      await controller.start(_complete);
      await controller.imageSettled;
      final state = c.read(recipeCreationProvider) as CreationDone;
      expect(state.existing, isFalse);
      expect(state.recipe.lifecycle, RecipeLifecycle.privateSaved);
      final saved = await c
          .read(personalRecipeRepositoryProvider)
          .all('dev-local-user');
      expect(saved.single.id, state.recipe.id);
    });

    test(
      'starting twice with the same choices offers the saved recipe',
      () async {
        final c = make();
        final controller = c.read(recipeCreationProvider.notifier);
        await controller.start(_complete);
        final first = (c.read(recipeCreationProvider) as CreationDone).recipe;
        await controller.start(_complete);
        final second = c.read(recipeCreationProvider) as CreationDone;
        expect(second.existing, isTrue);
        expect(second.sameRequest, isFalse);
        expect(second.recipe.id, first.id);
        await controller.makeAnother();
        final third = c.read(recipeCreationProvider) as CreationDone;
        expect(third.recipe.id, isNot(first.id));
      },
    );

    test('an incomplete selection does nothing', () async {
      final c = make();
      await c
          .read(recipeCreationProvider.notifier)
          .start(const MealSelection(proteinId: 'tofu'));
      expect(c.read(recipeCreationProvider), isA<CreationIdle>());
    });

    test('where generation is unavailable it fails honestly', () async {
      final c = make(debugBuild: false);
      await c.read(recipeCreationProvider.notifier).start(_complete);
      final state = c.read(recipeCreationProvider) as CreationError;
      expect(state.failure.kind, GenerationFailureKind.notSignedIn);
    });
  });
}
