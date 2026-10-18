import '../../../core/domain/phase.dart';
import 'generated_recipe.dart';

/// Where a recipe's picture stands. Independent of the recipe itself: a recipe
/// is complete and usable without one.
enum ImageStatus { none, pending, ready, failed }

/// A pointer to a stored picture. The bytes live in storage (the backend's
/// object store, or an app file); the database keeps only this reference.
final class RecipeImageRef {
  const RecipeImageRef({
    required this.kind,
    this.path,
    this.provider,
    this.model,
  });

  /// The built-in fallback: nothing is stored and the tinted placeholder shows.
  static const placeholder = RecipeImageRef(kind: RecipeImageKind.placeholder);

  final RecipeImageKind kind;

  /// Storage path for [RecipeImageKind.stored].
  final String? path;
  final String? provider;
  final String? model;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'path': path,
    'provider': provider,
    'model': model,
  };

  factory RecipeImageRef.fromJson(Map<String, Object?> json) => RecipeImageRef(
    kind: RecipeImageKind.values.byName(json['kind']! as String),
    path: json['path'] as String?,
    provider: json['provider'] as String?,
    model: json['model'] as String?,
  );
}

enum RecipeImageKind { placeholder, stored }

/// Makes a picture for a validated recipe. Optional and recoverable on its own:
/// a failure leaves the recipe saved with `ImageStatus.failed` and a retry.
abstract interface class RecipeImageService {
  /// Throws [GenerationFailure] on provider errors.
  Future<RecipeImageRef> generate({
    required String recipeId,
    required GeneratedRecipe recipe,
    required Phase phase,
  });
}
