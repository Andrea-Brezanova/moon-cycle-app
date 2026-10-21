import 'dart:convert';
import 'dart:io';

import '../domain/personal_recipe.dart';
import '../domain/recipe_submission_service.dart';
import 'cloud_generation_service.dart' show HttpPost, ioHttpPost;

/// Calls the `submit-recipe` Edge Function. Sends the recipe id and the user's
/// explicit consent; the server checks ownership and lifecycle.
class CloudSubmissionService implements RecipeSubmissionService {
  CloudSubmissionService({
    required this.functionsBaseUrl,
    required this.accessToken,
    required this.apiKey,
    this.post = ioHttpPost,
  });

  final Uri functionsBaseUrl;
  final Future<String?> Function() accessToken;
  final String apiKey;
  final HttpPost post;

  @override
  Future<RecipeLifecycle> submit(String remoteRecipeId) async {
    final token = await accessToken();
    if (token == null) {
      throw const SubmissionException(SubmissionFailure.notSignedIn);
    }
    final ({int status, String body}) r;
    try {
      r = await post(
        functionsBaseUrl.resolve('${functionsBaseUrl.path}/submit-recipe'),
        {
          'authorization': 'Bearer $token',
          'apikey': apiKey,
          'content-type': 'application/json',
        },
        jsonEncode({'recipe_id': remoteRecipeId, 'consent': true}),
      );
    } on SocketException {
      throw const SubmissionException(SubmissionFailure.network);
    }
    if (r.status == 200) {
      final status =
          (jsonDecode(r.body) as Map<String, Object?>)['status'] as String?;
      return status == 'validated'
          ? RecipeLifecycle.validated
          : RecipeLifecycle.candidate;
    }
    final error = _error(r.body);
    throw SubmissionException(switch ((r.status, error)) {
      (401, _) => SubmissionFailure.notSignedIn,
      (404, _) => SubmissionFailure.notFound,
      (409, 'not_reviewable') => SubmissionFailure.notReviewable,
      (409, _) => SubmissionFailure.alreadySubmitted,
      _ => SubmissionFailure.network,
    });
  }

  static String? _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, Object?>)['error'] as String?;
    } on Object {
      return null;
    }
  }
}
