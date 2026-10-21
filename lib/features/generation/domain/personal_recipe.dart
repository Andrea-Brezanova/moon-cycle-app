import '../../content/domain/recipe.dart';
import 'generation_result.dart';
import 'recipe_image_service.dart';

/// Where a recipe is in its life. Everything starts [privateSaved]; moving on
/// is always an explicit step, and publishing needs an editor's approval on the
/// server (Stage 5). Nothing is published automatically.
enum RecipeLifecycle { privateSaved, candidate, validated, approved, published }

/// A recipe the user generated and owns.
final class PersonalRecipe {
  const PersonalRecipe({
    required this.recipe,
    required this.ownerId,
    required this.idempotencyKey,
    required this.fingerprint,
    required this.provenance,
    required this.createdAt,
    this.lifecycle = RecipeLifecycle.privateSaved,
    this.imageStatus = ImageStatus.none,
    this.imageRef,
    this.remoteId,
  });

  /// The id is namespaced `u-…`, so it cannot collide with a bundled recipe.
  final Recipe recipe;
  final String ownerId;
  final String idempotencyKey;
  final String fingerprint;
  final Provenance provenance;
  final DateTime createdAt;
  final RecipeLifecycle lifecycle;
  final ImageStatus imageStatus;
  final RecipeImageRef? imageRef;

  /// The server row id, once the recipe exists there.
  final String? remoteId;

  String get id => recipe.id;

  /// Shown on the recipe: this was not made by the live generator.
  bool get isDevSample => provenance.origin == GenerationOrigin.devMock;
}

/// The id prefix of every personal recipe.
const personalRecipePrefix = 'u-';
