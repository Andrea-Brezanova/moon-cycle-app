import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/generation/data/cloud_generation_service.dart';
import 'package:moon_cycle/features/generation/data/cloud_submission_service.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';
import 'package:moon_cycle/features/generation/domain/recipe_submission_service.dart';

CloudSubmissionService service(HttpPost post, {String? token = 'jwt'}) =>
    CloudSubmissionService(
      functionsBaseUrl: Uri.parse('http://127.0.0.1:54321/functions/v1'),
      accessToken: () async => token,
      apiKey: 'public-key',
      post: post,
    );

Matcher failure(SubmissionFailure f) =>
    throwsA(isA<SubmissionException>().having((e) => e.failure, 'failure', f));

void main() {
  test(
    'sends the recipe id with explicit consent, and the user token',
    () async {
      late Map<String, Object?> sent;
      late Map<String, String> headers;
      final s = service((u, h, b) async {
        sent = jsonDecode(b) as Map<String, Object?>;
        headers = h;
        expect(u.path, '/functions/v1/submit-recipe');
        return (status: 200, body: '{"status":"validated"}');
      });
      expect(await s.submit('srv-1'), RecipeLifecycle.validated);
      expect(sent, {'recipe_id': 'srv-1', 'consent': true});
      expect(headers['authorization'], 'Bearer jwt');
    },
  );

  test('a held-back recipe stays a candidate', () async {
    final s = service(
      (u, h, b) async => (status: 200, body: '{"status":"pending"}'),
    );
    expect(await s.submit('x'), RecipeLifecycle.candidate);
  });

  test('server answers become typed failures', () async {
    Future<void> check(int status, String body, SubmissionFailure f) =>
        expectLater(
          service((u, h, b) async => (status: status, body: body)).submit('x'),
          failure(f),
        );
    await check(
      401,
      '{"error":"not_signed_in"}',
      SubmissionFailure.notSignedIn,
    );
    await check(404, '{"error":"not_found"}', SubmissionFailure.notFound);
    await check(
      409,
      '{"error":"not_private"}',
      SubmissionFailure.alreadySubmitted,
    );
    await check(
      409,
      '{"error":"not_reviewable"}',
      SubmissionFailure.notReviewable,
    );
    await check(500, 'oops', SubmissionFailure.network);
  });

  test('signed out sends nothing', () async {
    var called = false;
    await expectLater(
      service((u, h, b) async {
        called = true;
        return (status: 200, body: '{}');
      }, token: null).submit('x'),
      failure(SubmissionFailure.notSignedIn),
    );
    expect(called, isFalse);
  });

  test('the default build cannot submit', () async {
    await expectLater(
      const UnavailableSubmissionService().submit('x'),
      failure(SubmissionFailure.unavailable),
    );
  });
}
