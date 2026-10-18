/// Why a generation did not produce a recipe.
enum GenerationFailureKind {
  /// No generation service is configured in this build (production today).
  unavailable,

  /// Generation needs an account and the user is signed out.
  notSignedIn,

  /// The server says the account is not entitled (Premium).
  notEntitled,

  /// The monthly allowance is used up.
  quotaExceeded,

  /// Too many requests in a short time.
  rateLimited,

  /// The provider took too long.
  timeout,

  /// No connection, or the server could not be reached.
  network,

  /// The generator's answer failed validation, even after one repair attempt.
  invalidResult,

  /// The selection itself is not valid (wrong number of foods, a food the
  /// user avoids). Not retryable: change the choices.
  invalidSelection,

  /// Anything else.
  unknown,
}

/// Thrown by a generation service, and carried by a failed job.
final class GenerationFailure implements Exception {
  const GenerationFailure(this.kind, [this.detail]);

  final GenerationFailureKind kind;

  /// For logs only (never recipe text); not shown to users.
  final String? detail;

  /// Whether pressing "Try again" with the same request can help.
  bool get retryable => switch (kind) {
    GenerationFailureKind.timeout ||
    GenerationFailureKind.network ||
    GenerationFailureKind.rateLimited ||
    GenerationFailureKind.invalidResult ||
    GenerationFailureKind.unknown => true,
    _ => false,
  };

  @override
  String toString() => 'GenerationFailure(${kind.name}, $detail)';
}
