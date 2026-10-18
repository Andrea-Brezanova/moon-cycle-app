import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/generated_recipe.dart';
import '../domain/generation_failure.dart';
import '../domain/generation_request.dart';
import '../domain/generation_result.dart';
import '../domain/recipe_generation_service.dart';
import '../domain/recipe_validator.dart';

/// One HTTP exchange: status code and body. Injected so the service is tested
/// without a network.
typedef HttpPost = Future<({int status, String body})> Function(
  Uri url,
  Map<String, String> headers,
  String body,
);

/// The real transport (dart:io). Nothing here knows about recipes.
Future<({int status, String body})> ioHttpPost(
  Uri url,
  Map<String, String> headers,
  String body,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.postUrl(url);
    headers.forEach(request.headers.set);
    request.add(utf8.encode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (status: response.statusCode, body: text);
  } finally {
    client.close(force: true);
  }
}

/// Calls the `generate-recipe` Edge Function. The app holds no provider key:
/// it sends only food ids and the user's access token, and the server decides
/// entitlement, quota and rate limits.
///
/// Not wired into the app yet: there is no sign-in and no hosted backend. It is
/// tested against fakes here and against the local Supabase stack by
/// `supabase/tests/integration.sh`.
class CloudRecipeGenerationService implements RecipeGenerationService {
  CloudRecipeGenerationService({
    required this.functionsBaseUrl,
    required this.accessToken,
    required this.apiKey,
    this.post = ioHttpPost,
    this.timeout = const Duration(seconds: 60),
  });

  /// `https://<project>.supabase.co/functions/v1` (or the local stack's).
  final Uri functionsBaseUrl;

  /// The signed-in user's token, or null when signed out.
  final Future<String?> Function() accessToken;

  /// The project's publishable (public) key. Never a secret or service key.
  final String apiKey;
  final HttpPost post;
  final Duration timeout;

  @override
  Future<GenerationResult> generate(
    GenerationRequest request, {
    List<ValidationIssue> repair = const [],
  }) async {
    final token = await accessToken();
    if (token == null) {
      throw const GenerationFailure(GenerationFailureKind.notSignedIn);
    }
    final ({int status, String body}) response;
    try {
      response = await post(
        functionsBaseUrl.resolve('${functionsBaseUrl.path}/generate-recipe'),
        {
          'authorization': 'Bearer $token',
          'apikey': apiKey,
          'content-type': 'application/json',
        },
        jsonEncode(request.toJson()),
      ).timeout(timeout);
    } on TimeoutException {
      throw const GenerationFailure(GenerationFailureKind.timeout);
    } on SocketException {
      throw const GenerationFailure(GenerationFailureKind.network);
    } on HttpException {
      throw const GenerationFailure(GenerationFailureKind.network);
    }

    if (response.status != 200) {
      throw GenerationFailure(_kindFor(response.status, response.body));
    }
    try {
      final json = jsonDecode(response.body) as Map<String, Object?>;
      final recipe = GeneratedRecipe.fromJson(
        json['recipe']! as Map<String, Object?>,
      );
      final origin = json['origin'] == 'cloud'
          ? GenerationOrigin.cloud
          : GenerationOrigin.devMock; // `local_stub` is never shown as live
      return GenerationResult(
        recipe: recipe,
        provenance: Provenance(
          origin: origin,
          provider: json['provider']! as String,
          model: json['model']! as String,
        ),
      );
    } on FormatException {
      throw const GenerationFailure(GenerationFailureKind.invalidResult);
    } on TypeError {
      throw const GenerationFailure(GenerationFailureKind.invalidResult);
    }
  }

  static GenerationFailureKind _kindFor(int status, String body) {
    String? error;
    try {
      error = (jsonDecode(body) as Map<String, Object?>)['error'] as String?;
    } on Object {
      error = null;
    }
    return switch (error) {
      'not_signed_in' => GenerationFailureKind.notSignedIn,
      'not_entitled' => GenerationFailureKind.notEntitled,
      'quota_exceeded' => GenerationFailureKind.quotaExceeded,
      'rate_limited' => GenerationFailureKind.rateLimited,
      'invalid_selection' => GenerationFailureKind.invalidSelection,
      'invalid_result' => GenerationFailureKind.invalidResult,
      'timeout' => GenerationFailureKind.timeout,
      'unavailable' ||
      'generation_disabled' ||
      'budget_exhausted' => GenerationFailureKind.unavailable,
      _ => switch (status) {
        401 => GenerationFailureKind.notSignedIn,
        403 => GenerationFailureKind.notEntitled,
        429 => GenerationFailureKind.rateLimited,
        504 => GenerationFailureKind.timeout,
        >= 500 => GenerationFailureKind.network,
        _ => GenerationFailureKind.unknown,
      },
    };
  }
}
