import 'generation_request.dart';
import 'generation_result.dart';
import 'recipe_validator.dart';

/// Turns a selection of foods into a structured recipe.
///
/// Implementations: the cloud service (a Supabase Edge Function, added when
/// the backend exists), a clearly labelled development mock, and an
/// "unavailable" service for builds that have neither. The result is always
/// untrusted: the app validates it again before showing or saving it.
abstract interface class RecipeGenerationService {
  /// Generates a recipe for [request]. Throws [GenerationFailure]. Calling it
  /// again with the same `idempotencyKey` must not create a second recipe on
  /// the server.
  ///
  /// [repair] lists what was wrong with the previous attempt, for the one
  /// repair retry.
  Future<GenerationResult> generate(
    GenerationRequest request, {
    List<ValidationIssue> repair = const [],
  });
}
