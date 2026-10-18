import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';
import 'package:moon_cycle/features/discovery/domain/provider_policy.dart';

const _policy = ProviderPolicy(
  id: 'p',
  name: 'P',
  enabled: true,
  monthlyRequestBudget: 3,
  maxRequestsPerMinute: 2,
  timeout: Duration(milliseconds: 50),
  costMicrosPerRequest: 1000,
);

void main() {
  final url = Uri.parse('https://example.test/x');
  var now = DateTime(2026, 10, 5, 9);

  ProviderHttp make({
    ProviderPolicy policy = _policy,
    HttpGet? get,
    UsageLedger? ledger,
  }) => ProviderHttp(
    policy: policy,
    ledger: ledger ?? InMemoryUsageLedger(),
    get: get ?? (u, h) async => (status: 200, body: '{"ok":1}'),
    now: () => now,
  );

  Matcher problem(ProviderProblem p) => throwsA(
    isA<ProviderUnavailable>().having((e) => e.problem, 'problem', p),
  );

  setUp(() => now = DateTime(2026, 10, 5, 9));

  test('returns the JSON and counts the request and its cost', () async {
    final ledger = InMemoryUsageLedger();
    final http = make(ledger: ledger);
    expect(await http.getJson(url), {'ok': 1});
    final u = await ledger.usage('p', now);
    expect(u.requests, 1);
    expect(u.costMicros, 1000);
  });

  test('a disabled provider is never called', () async {
    var called = false;
    final http = make(
      policy: _policy.copyWith(enabled: false),
      get: (u, h) async {
        called = true;
        return (status: 200, body: '{}');
      },
    );
    await expectLater(http.getJson(url), problem(ProviderProblem.disabled));
    expect(called, isFalse);
  });

  test(
    'the monthly budget stops further requests, and resets next month',
    () async {
      final http = make(policy: _policy.copyWith(maxRequestsPerMinute: 100));
      for (var i = 0; i < 3; i++) {
        await http.getJson(url);
      }
      await expectLater(
        http.getJson(url),
        problem(ProviderProblem.budgetExhausted),
      );
      now = DateTime(2026, 11, 1);
      expect(await http.getJson(url), isNotNull);
    },
  );

  test('the per-minute rate limit, which clears after a minute', () async {
    final http = make();
    await http.getJson(url);
    await http.getJson(url);
    await expectLater(http.getJson(url), problem(ProviderProblem.rateLimited));
    now = now.add(const Duration(seconds: 61));
    expect(await http.getJson(url), isNotNull);
  });

  test('free calls (not charged) do not use the budget', () async {
    final ledger = InMemoryUsageLedger();
    final http = make(
      policy: _policy.copyWith(
        monthlyRequestBudget: 1,
        maxRequestsPerMinute: 100,
      ),
      ledger: ledger,
    );
    for (var i = 0; i < 5; i++) {
      await http.getJson(url, free: true);
    }
    expect((await ledger.usage('p', now)).requests, 0);
    await http.getJson(url);
    await expectLater(
      http.getJson(url),
      problem(ProviderProblem.budgetExhausted),
    );
  });

  test('timeouts, network errors, 429, other statuses and bad JSON', () async {
    Future<void> check(HttpGet get, ProviderProblem p) => expectLater(
      make(
        get: get,
        policy: _policy.copyWith(
          maxRequestsPerMinute: 100,
          monthlyRequestBudget: 100,
        ),
      ).getJson(url),
      problem(p),
    );
    await check(
      (u, h) => Completer<({int status, String body})>().future,
      ProviderProblem.timeout,
    );
    await check(
      (u, h) async => throw const SocketException('down'),
      ProviderProblem.network,
    );
    await check(
      (u, h) async => (status: 429, body: ''),
      ProviderProblem.rateLimited,
    );
    await check(
      (u, h) async => (status: 503, body: ''),
      ProviderProblem.badResponse,
    );
    await check(
      (u, h) async => (status: 200, body: '<html>'),
      ProviderProblem.badResponse,
    );
  });

  test('usage is tracked separately per provider', () async {
    final ledger = InMemoryUsageLedger();
    final a = make(ledger: ledger);
    final b = ProviderHttp(
      policy: _policy.copyWith().copyWith(),
      ledger: ledger,
      get: (u, h) async => (status: 200, body: '{}'),
      now: () => now,
    );
    await a.getJson(url);
    expect((await ledger.usage('p', now)).requests, 1);
    expect((await ledger.usage('other', now)).requests, 0);
    expect(b.policy.id, 'p');
  });
}
