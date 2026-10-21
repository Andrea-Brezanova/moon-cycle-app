import '../../content/domain/catalogue.dart';
import '../../content/domain/food_filter.dart';
import '../data/personal_recipe_repository.dart';
import '../domain/generated_recipe.dart';
import '../domain/generation_failure.dart';
import '../domain/generation_request.dart';
import '../domain/generation_result.dart';
import '../domain/personal_recipe.dart';
import '../domain/recipe_generation_service.dart';
import '../domain/recipe_image_service.dart';
import '../domain/recipe_validator.dart';

/// The account a generation belongs to. Browsing needs none; creating and
/// saving a recipe does.
final class AuthSession {
  const AuthSession({required this.userId, this.isDevelopment = false});

  final String userId;

  /// A development-only session that exists only in debug builds of the dev
  /// flavour. Never produced by a real sign-in.
  final bool isDevelopment;
}

/// The steps shown while a recipe is made.
enum CreationStep { checking, writing, validating, repairing, saving }

sealed class CreationOutcome {
  const CreationOutcome();
}

/// A new recipe, saved to the user's private library.
final class Created extends CreationOutcome {
  const Created(this.recipe);
  final PersonalRecipe recipe;
}

/// This request (or this selection) was already made: nothing new was
/// generated and no allowance was used.
final class Existing extends CreationOutcome {
  const Existing(this.recipe, {required this.sameRequest});
  final PersonalRecipe recipe;

  /// True for a retry of the same tap; false for the same foods chosen again.
  final bool sameRequest;
}

final class CreationFailed extends CreationOutcome {
  const CreationFailed(this.failure);
  final GenerationFailure failure;
}

/// Runs the whole pipeline for one request:
/// selection check → generate → validate (one repair retry) → save privately.
/// The picture is a separate, optional step ([makeImage]).
///
/// Plain Dart with injected parts, so every failure path is unit-tested
/// without Flutter.
class RecipeCreator {
  RecipeCreator({
    required this.service,
    required this.imageService,
    required this.repository,
    required this.catalogue,
    required this.filter,
    required this.session,
    required this.newRecipeId,
    required this.now,
  });

  final RecipeGenerationService service;
  final RecipeImageService imageService;
  final PersonalRecipeRepository repository;
  final Catalogue catalogue;
  final FoodFilter Function() filter;
  final AuthSession? Function() session;
  final String Function() newRecipeId;
  final DateTime Function() now;

  /// Why [request] is not a valid selection, or null.
  GenerationFailure? checkSelection(GenerationRequest request) {
    GenerationFailure bad(String why) =>
        GenerationFailure(GenerationFailureKind.invalidSelection, why);
    final ids = request.foodIds;
    if (request.kind == GenerationKind.tryNew) {
      if (ids.length != 3) return bad('foods: ${ids.length}');
      if (request.variant < 0 || request.variant > 2) return bad('variant');
    } else if (request.plantIds.length < 2 || request.plantIds.length > 3) {
      return bad('plants: ${request.plantIds.length}');
    }
    if (ids.toSet().length != ids.length) return bad('a food twice');
    for (final id in ids) {
      final food = catalogue.food(id);
      if (food == null) return bad('unknown food $id');
      if (!filter().allowsFood(food)) return bad('avoided food $id');
    }
    return null;
  }

  /// Creates a recipe. [allowSameSelection] is true only when the user chose
  /// "Make another version" after being offered the saved one.
  Future<CreationOutcome> create(
    GenerationRequest request, {
    bool allowSameSelection = false,
    void Function(CreationStep step)? onStep,
  }) async {
    void step(CreationStep s) => onStep?.call(s);
    final owner = session();
    if (owner == null) {
      return const CreationFailed(
        GenerationFailure(GenerationFailureKind.notSignedIn),
      );
    }
    step(CreationStep.checking);
    final invalid = checkSelection(request);
    if (invalid != null) return CreationFailed(invalid);

    // A retry of the same tap finds what the first attempt saved.
    final sameKey = await repository.byIdempotencyKey(
      owner.userId,
      request.idempotencyKey,
    );
    if (sameKey != null) return Existing(sameKey, sameRequest: true);
    if (!allowSameSelection) {
      final same = await repository.byFingerprint(
        owner.userId,
        request.fingerprint,
      );
      if (same != null) return Existing(same, sameRequest: false);
    }

    GenerationResult? result;
    var issues = const <ValidationIssue>[];
    for (var attempt = 0; attempt < 2; attempt++) {
      step(attempt == 0 ? CreationStep.writing : CreationStep.repairing);
      try {
        result = await service.generate(request, repair: issues);
      } on GenerationFailure catch (f) {
        return CreationFailed(f);
      } on FormatException catch (e) {
        result = null;
        issues = [ValidationIssue(IssueCode.schema, e.message)];
        continue;
      }
      step(CreationStep.validating);
      final report = RecipeValidator(catalogue)
          .validate(result.recipe, request, filter());
      if (report.isValid) break;
      issues = report.issues;
      result = null;
    }
    if (result == null) {
      return CreationFailed(
        GenerationFailure(
          GenerationFailureKind.invalidResult,
          issues.map((i) => i.code.name).join(','),
        ),
      );
    }

    step(CreationStep.saving);
    final id = '$personalRecipePrefix${newRecipeId()}';
    final saved = await repository.save(
      PersonalRecipe(
        recipe: result.recipe.toRecipe(
          id: id,
          request: request,
          catalogue: catalogue,
        ),
        ownerId: owner.userId,
        idempotencyKey: request.idempotencyKey,
        fingerprint: request.fingerprint,
        provenance: result.provenance,
        createdAt: now(),
        imageStatus: ImageStatus.pending,
        remoteId: result.remoteId,
      ),
    );
    return Created(saved);
  }

  /// Makes (or retries) the recipe's picture. Never affects the recipe: a
  /// failure leaves it saved with `ImageStatus.failed`.
  Future<void> makeImage(PersonalRecipe saved) async {
    await repository.setImage(
      saved.ownerId,
      saved.id,
      status: ImageStatus.pending,
    );
    try {
      final ref = await imageService.generate(
        recipeId: saved.id,
        recipe: _asGenerated(saved),
        phase: saved.recipe.phase,
      );
      await repository.setImage(
        saved.ownerId,
        saved.id,
        status: ImageStatus.ready,
        ref: ref,
      );
    } on GenerationFailure {
      await repository.setImage(
        saved.ownerId,
        saved.id,
        status: ImageStatus.failed,
      );
    }
  }

  GeneratedRecipe _asGenerated(PersonalRecipe saved) {
    final r = saved.recipe;
    return GeneratedRecipe(
      title: r.title,
      intro: r.intro,
      category: r.category,
      minutes: r.minutes,
      serves: r.serves,
      ingredients: [
        for (final l in r.ingredients)
          GeneratedIngredient(
            label: l.label,
            foodId: l.foodId,
            amount: l.amount,
            unit: l.unit,
            qtyText: l.qtyText,
          ),
      ],
      steps: r.steps,
    );
  }
}
