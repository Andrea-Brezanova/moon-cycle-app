import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../foods/application/meal_selection.dart';
import '../data/dev_mock_generation_service.dart';
import '../data/personal_recipe_repository.dart';
import '../domain/generation_failure.dart';
import '../domain/generation_request.dart';
import '../domain/personal_recipe.dart';
import '../domain/recipe_generation_service.dart';
import '../domain/recipe_image_service.dart';
import 'recipe_creator.dart';

/// Whether the development mock generator may exist: a debug build of the dev
/// flavour only. Both switches are false in profile and release builds and in
/// the prod flavour, so a shipped app can never create or show mock recipes.
final devGenerationAllowedProvider = Provider<bool>(
  (ref) =>
      ref.watch(debugPreviewAllowedProvider) &&
      ref.watch(debugUnlockAtStartProvider),
);

/// The signed-in account, or null. There is no real sign-in yet (it arrives
/// with the backend), so only the development session exists, and only where
/// [devGenerationAllowedProvider] allows it.
final authSessionProvider = Provider<AuthSession?>(
  (ref) => ref.watch(devGenerationAllowedProvider)
      ? const AuthSession(userId: 'dev-local-user', isDevelopment: true)
      : null,
);

final recipeGenerationServiceProvider = Provider<RecipeGenerationService>(
  (ref) => ref.watch(devGenerationAllowedProvider)
      ? DevMockGenerationService(catalogue: ref.watch(catalogueProvider))
      : const UnavailableGenerationService(),
);

final recipeImageServiceProvider = Provider<RecipeImageService>(
  (ref) => ref.watch(devGenerationAllowedProvider)
      ? PlaceholderRecipeImageService()
      : const UnavailableImageService(),
);

/// Whether this build can create recipes at all. When false the app says so
/// instead of showing a button that cannot work.
final generationAvailableProvider = Provider<bool>(
  (ref) =>
      ref.watch(recipeGenerationServiceProvider)
          is! UnavailableGenerationService,
);

final recipeCreatorProvider = Provider<RecipeCreator>((ref) {
  const uuid = Uuid();
  return RecipeCreator(
    service: ref.watch(recipeGenerationServiceProvider),
    imageService: ref.watch(recipeImageServiceProvider),
    repository: ref.watch(personalRecipeRepositoryProvider),
    catalogue: ref.watch(catalogueProvider),
    filter: () => ref.read(foodFilterProvider),
    session: () => ref.read(authSessionProvider),
    newRecipeId: uuid.v4,
    now: DateTime.now,
  );
});

/// The current user's recipes, newest first. Empty when signed out.
final personalRecipesProvider = StreamProvider<List<PersonalRecipe>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref.watch(personalRecipeRepositoryProvider).watchAll(session.userId);
});

/// One personal recipe by id (null when it is not the user's or is gone).
final personalRecipeProvider = StreamProvider.family<PersonalRecipe?, String>((
  ref,
  id,
) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(null);
  return ref
      .watch(personalRecipeRepositoryProvider)
      .watchById(session.userId, id);
});

// ---------------------------------------------------------------------------

sealed class CreationState {
  const CreationState();
}

final class CreationIdle extends CreationState {
  const CreationIdle();
}

final class CreationRunning extends CreationState {
  const CreationRunning(this.step);
  final CreationStep step;
}

/// A recipe is ready: just made, or already saved ([existing]).
final class CreationDone extends CreationState {
  const CreationDone(
    this.recipe, {
    this.existing = false,
    this.sameRequest = true,
  });
  final PersonalRecipe recipe;
  final bool existing;
  final bool sameRequest;
}

final class CreationError extends CreationState {
  const CreationError(this.failure);
  final GenerationFailure failure;
}

final recipeCreationProvider =
    NotifierProvider<RecipeCreationController, CreationState>(
      RecipeCreationController.new,
    );

/// One creation at a time. A tap makes a request with a fresh idempotency key;
/// Retry reuses it, so a retry can never make a second recipe.
class RecipeCreationController extends Notifier<CreationState> {
  GenerationRequest? _request;
  var _busy = false;

  /// The picture step of the last created recipe (for tests to await).
  Future<void> imageSettled = Future.value();

  @override
  CreationState build() => const CreationIdle();

  /// Starts creating from a complete [selection] for the viewing phase.
  Future<void> start(MealSelection selection) async {
    if (_busy || !selection.isComplete) return;
    _request = GenerationRequest(
      idempotencyKey: const Uuid().v4(),
      phase: ref.read(viewingPhaseProvider),
      proteinId: selection.proteinId!,
      baseId: selection.baseId!,
      plantIds: selection.plantIds,
    );
    await _run();
  }

  /// Tries the same request again (same idempotency key).
  Future<void> retry() => _run();

  /// "Make another version" of a selection that already has a saved recipe.
  Future<void> makeAnother() async {
    final r = _request;
    if (_busy || r == null) return;
    _request = GenerationRequest(
      idempotencyKey: const Uuid().v4(),
      phase: r.phase,
      proteinId: r.proteinId,
      baseId: r.baseId,
      plantIds: r.plantIds,
    );
    await _run(allowSameSelection: true);
  }

  void reset() {
    if (!_busy) state = const CreationIdle();
  }

  Future<void> _run({bool allowSameSelection = false}) async {
    final request = _request;
    if (_busy || request == null) return;
    _busy = true;
    final creator = ref.read(recipeCreatorProvider);
    state = const CreationRunning(CreationStep.checking);
    try {
      final outcome = await creator.create(
        request,
        allowSameSelection: allowSameSelection,
        onStep: (s) => state = CreationRunning(s),
      );
      switch (outcome) {
        case Created(:final recipe):
          state = CreationDone(recipe);
          // The picture is optional and separate: it never blocks the recipe.
          imageSettled = creator.makeImage(recipe);
          unawaited(imageSettled);
        case Existing(:final recipe, :final sameRequest):
          state = CreationDone(
            recipe,
            existing: true,
            sameRequest: sameRequest,
          );
        case CreationFailed(:final failure):
          state = CreationError(failure);
      }
    } finally {
      _busy = false;
    }
  }
}

/// Tries a recipe's picture again after it failed.
final retryImageProvider = Provider<Future<void> Function(PersonalRecipe)>(
  (ref) =>
      (recipe) => ref.read(recipeCreatorProvider).makeImage(recipe),
);

/// Whether [ImageStatus] says a picture is still being made.
bool imageIsPending(PersonalRecipe r) => r.imageStatus == ImageStatus.pending;
