import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/provider_policy.dart';

/// One GET: status and body. Injected, so adapters are tested without a
/// network.
typedef HttpGet = Future<({int status, String body})> Function(
  Uri url,
  Map<String, String> headers,
);

/// The real transport (dart:io).
Future<({int status, String body})> ioHttpGet(
  Uri url,
  Map<String, String> headers,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(url);
    headers.forEach(request.headers.set);
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (status: response.statusCode, body: text);
  } finally {
    client.close(force: true);
  }
}

/// Every request an adapter makes goes through here: it is refused when the
/// provider is disabled, over its monthly budget or its per-minute rate, it is
/// timed out, counted in the [UsageLedger], and any failure becomes a
/// [ProviderUnavailable] so one provider failing never breaks a search.
class ProviderHttp {
  ProviderHttp({
    required this.policy,
    required this.ledger,
    this._get = ioHttpGet,
    DateTime Function()? now,
    this.headers = const {},
  }) : _now = now ?? DateTime.now;

  final ProviderPolicy policy;
  final UsageLedger ledger;
  final Map<String, String> headers;
  final HttpGet _get;
  final DateTime Function() _now;
  final _recent = <DateTime>[];

  /// [free] marks a call the provider does not charge for or count against the
  /// quota (Recipe API's searches): it still obeys the rate limit and timeout.
  Future<Object?> getJson(Uri url, {bool free = false}) async {
    if (!policy.enabled) {
      throw const ProviderUnavailable(ProviderProblem.disabled);
    }
    final now = _now();
    if (!free) {
      final used = await ledger.usage(policy.id, now);
      if (used.requests >= policy.monthlyRequestBudget) {
        throw const ProviderUnavailable(ProviderProblem.budgetExhausted);
      }
    }
    _recent.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
    if (_recent.length >= policy.maxRequestsPerMinute) {
      throw const ProviderUnavailable(ProviderProblem.rateLimited);
    }
    _recent.add(now);
    if (!free) {
      await ledger.record(
        policy.id,
        now,
        requests: 1,
        costMicros: policy.costMicrosPerRequest,
      );
    }
    final ({int status, String body}) response;
    try {
      response = await _get(url, headers).timeout(policy.timeout);
    } on TimeoutException {
      throw const ProviderUnavailable(ProviderProblem.timeout);
    } on SocketException catch (e) {
      throw ProviderUnavailable(ProviderProblem.network, e.message);
    } on HttpException catch (e) {
      throw ProviderUnavailable(ProviderProblem.network, e.message);
    }
    if (response.status == 429) {
      throw const ProviderUnavailable(ProviderProblem.rateLimited, 'HTTP 429');
    }
    if (response.status != 200) {
      throw ProviderUnavailable(
        ProviderProblem.badResponse,
        'HTTP ${response.status}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ProviderUnavailable(ProviderProblem.badResponse, 'not JSON');
    }
  }
}
