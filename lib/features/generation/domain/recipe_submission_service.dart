import 'personal_recipe.dart';

/// Why a suggestion was not accepted.
enum SubmissionFailure {
  /// No backend in this build.
  unavailable,
  notSignedIn,

  /// The recipe is not the user's, or no longer exists.
  notFound,

  /// It is already suggested, or past that point.
  alreadySubmitted,

  /// Only recipes made by the live service can be suggested (never a
  /// development sample).
  notReviewable,
  network,
}

final class SubmissionException implements Exception {
  const SubmissionException(this.failure);
  final SubmissionFailure failure;
}

/// "Suggest to Moon Cycle": an explicit, consented request to have one of the
/// user's recipes reviewed for the shared library. It never publishes: the
/// answer is where the recipe stands (validated or still a candidate), and an
/// editor decides the rest.
abstract interface class RecipeSubmissionService {
  /// Returns the lifecycle the server put the recipe in. Throws
  /// [SubmissionException].
  Future<RecipeLifecycle> submit(String remoteRecipeId);
}

/// Builds without a backend (every build today).
class UnavailableSubmissionService implements RecipeSubmissionService {
  const UnavailableSubmissionService();

  @override
  Future<RecipeLifecycle> submit(String remoteRecipeId) =>
      Future.error(const SubmissionException(SubmissionFailure.unavailable));
}
