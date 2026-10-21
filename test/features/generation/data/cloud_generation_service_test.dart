import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/generation/data/cloud_generation_service.dart';
import 'package:moon_cycle/features/generation/domain/generation_failure.dart';
import 'package:moon_cycle/features/generation/domain/generation_request.dart';
import 'package:moon_cycle/features/generation/domain/generation_result.dart';
import 'package:moon_cycle/features/generation/domain/recipe_validator.dart';

import '../../../helpers/test_catalogue.dart';

final _request = GenerationRequest(
  idempotencyKey: 'key-0000001',
  phase: Phase.luteal,
  proteinId: 'tofu',
  baseId: 'farro',
  plantIds: const ['kale', 'carrot'],
);

final _recipe = {
  'schema_version': 1,
  'title': 'Tofu & Farro Bowl',
  'intro': 'A simple bowl of tofu and farro.',
  'category': 'dinner',
  'minutes': 30,
  'serves': 2,
  'ingredients': [
    {
      'label': 'Tofu',
      'food_id': 'tofu',
      'amount': 150,
      'unit': 'g',
      'qty_text': null,
    },
  ],
  'steps': ['one step here', 'two step here', 'three step here'],
};

CloudRecipeGenerationService service(
  HttpPost post, {
  String? token = 'jwt',
  Duration timeout = const Duration(seconds: 5),
}) => CloudRecipeGenerationService(
  functionsBaseUrl: Uri.parse('http://127.0.0.1:54321/functions/v1'),
  accessToken: () async => token,
  apiKey: 'public-key',
  post: post,
  timeout: timeout,
);

HttpPost reply(int status, Object body) =>
    (url, headers, b) async => (status: status, body: jsonEncode(body));

void main() {
  _contract();
  test('sends only food ids, the token and the public key', () async {
    late Uri url;
    late Map<String, String> headers;
    late Map<String, Object?> sent;
    final s = service((u, h, b) async {
      url = u;
      headers = h;
      sent = jsonDecode(b) as Map<String, Object?>;
      return (
        status: 200,
        body: jsonEncode({
          'recipe_id': 'r',
          'recipe': _recipe,
          'origin': 'cloud',
          'provider': 'p',
          'model': 'm',
        }),
      );
    });
    final result = await s.generate(_request);
    expect(url.path, '/functions/v1/generate-recipe');
    expect(headers['authorization'], 'Bearer jwt');
    expect(headers['apikey'], 'public-key');
    expect(sent.keys, {
      'idempotency_key',
      'phase',
      'protein_id',
      'base_id',
      'plant_ids',
    });
    expect(result.recipe.title, 'Tofu & Farro Bowl');
    expect(result.provenance.origin, GenerationOrigin.cloud);
  });

  test('a local stub result is never labelled as live', () async {
    final result = await service(
      reply(200, {
        'recipe': _recipe,
        'origin': 'local_stub',
        'provider': 'local-stub',
        'model': 'template-v1',
      }),
    ).generate(_request);
    expect(result.provenance.origin, GenerationOrigin.devMock);
  });

  test('signed out: no request is made', () async {
    var called = false;
    final s = service((u, h, b) async {
      called = true;
      return (status: 200, body: '{}');
    }, token: null);
    await expectLater(
      s.generate(_request),
      throwsA(
        isA<GenerationFailure>().having(
          (f) => f.kind,
          'kind',
          GenerationFailureKind.notSignedIn,
        ),
      ),
    );
    expect(called, isFalse);
  });

  group('server errors become the app\'s failures', () {
    const cases = {
      (401, 'not_signed_in'): GenerationFailureKind.notSignedIn,
      (403, 'not_entitled'): GenerationFailureKind.notEntitled,
      (429, 'quota_exceeded'): GenerationFailureKind.quotaExceeded,
      (429, 'rate_limited'): GenerationFailureKind.rateLimited,
      (503, 'budget_exhausted'): GenerationFailureKind.unavailable,
      (503, 'generation_disabled'): GenerationFailureKind.unavailable,
      (422, 'invalid_selection'): GenerationFailureKind.invalidSelection,
      (422, 'invalid_result'): GenerationFailureKind.invalidResult,
      (504, 'timeout'): GenerationFailureKind.timeout,
    };
    for (final MapEntry(key: (status, error), value: kind) in cases.entries) {
      test('$status $error', () async {
        await expectLater(
          service(reply(status, {'error': error})).generate(_request),
          throwsA(isA<GenerationFailure>().having((f) => f.kind, 'kind', kind)),
        );
      });
    }
    test('an unreadable 500 is a network-style retryable failure', () async {
      await expectLater(
        service((u, h, b) async => (status: 500, body: '<html>'))
            .generate(_request),
        throwsA(
          isA<GenerationFailure>().having(
            (f) => f.retryable,
            'retryable',
            true,
          ),
        ),
      );
    });
  });

  test('timeouts and lost connections', () async {
    await expectLater(
      service(
        (u, h, b) => Completer<({int status, String body})>().future,
        timeout: const Duration(milliseconds: 20),
      ).generate(_request),
      throwsA(
        isA<GenerationFailure>().having(
          (f) => f.kind,
          'kind',
          GenerationFailureKind.timeout,
        ),
      ),
    );
    await expectLater(
      service((u, h, b) async => throw const SocketException('down'))
          .generate(_request),
      throwsA(
        isA<GenerationFailure>().having(
          (f) => f.kind,
          'kind',
          GenerationFailureKind.network,
        ),
      ),
    );
  });

  test('a malformed recipe in a 200 is an invalid result', () async {
    await expectLater(
      service(
        reply(200, {
          'recipe': {'title': 'x'},
          'origin': 'cloud',
          'provider': 'p',
          'model': 'm',
        }),
      ).generate(_request),
      throwsA(
        isA<GenerationFailure>().having(
          (f) => f.kind,
          'kind',
          GenerationFailureKind.invalidResult,
        ),
      ),
    );
  });
}

// A real response captured from the Edge Function running on the local
/// Supabase stack (stub model): the app parses and accepts what the server
/// sends.
void _contract() {
  test('contract: the real function response parses and validates', () async {
    final body = File('test/fixtures/generation/function_response.json')
        .readAsStringSync();
    final result = await service((u, h, b) async => (status: 200, body: body))
        .generate(_request);
    expect(result.provenance.origin, GenerationOrigin.devMock);
    final report = RecipeValidator(testCatalogue)
        .validate(result.recipe, _request, FoodFilter.none);
    expect(report.isValid, isTrue, reason: report.toString());
  });
}
