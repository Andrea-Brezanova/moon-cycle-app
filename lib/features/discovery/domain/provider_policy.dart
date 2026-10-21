/// What one external recipe provider may do, in one place. Every number here is
/// configuration, never buried in an adapter.
final class ProviderPolicy {
  const ProviderPolicy({
    required this.id,
    required this.name,
    this.enabled = false,
    this.developmentOnly = false,
    this.timeout = const Duration(seconds: 8),
    this.monthlyRequestBudget = 1000,
    this.maxRequestsPerMinute = 30,
    this.maxDetailLookups = 12,
    this.costMicrosPerRequest = 0,
    this.cacheTtl = Duration.zero,
  });

  /// Short stable id, also the recipe-id namespace: `x-<id>-<provider id>`.
  final String id;
  final String name;

  /// Master switch. A provider that is not enabled is never called.
  final bool enabled;

  /// Free/test access only: usable in a debug dev build, never in release.
  final bool developmentOnly;

  /// Longest a whole search on this provider may take.
  final Duration timeout;

  /// Requests allowed per calendar month; further calls are refused locally.
  final int monthlyRequestBudget;

  /// Requests allowed in any rolling minute.
  final int maxRequestsPerMinute;

  /// How many full recipes one search may fetch.
  final int maxDetailLookups;

  /// Approximate cost of one request, in millionths of a US dollar.
  final int costMicrosPerRequest;

  /// How long a fetched recipe may be kept in memory. Zero where the terms do
  /// not allow caching or say nothing.
  final Duration cacheTtl;

  ProviderPolicy copyWith({
    bool? enabled,
    int? monthlyRequestBudget,
    int? maxRequestsPerMinute,
    Duration? timeout,
    int? maxDetailLookups,
    Duration? cacheTtl,
  }) => ProviderPolicy(
    id: id,
    name: name,
    enabled: enabled ?? this.enabled,
    developmentOnly: developmentOnly,
    timeout: timeout ?? this.timeout,
    monthlyRequestBudget: monthlyRequestBudget ?? this.monthlyRequestBudget,
    maxRequestsPerMinute: maxRequestsPerMinute ?? this.maxRequestsPerMinute,
    maxDetailLookups: maxDetailLookups ?? this.maxDetailLookups,
    costMicrosPerRequest: costMicrosPerRequest,
    cacheTtl: cacheTtl ?? this.cacheTtl,
  );
}

/// Why a provider could not answer. The search carries on with the others.
enum ProviderProblem {
  disabled,
  budgetExhausted,
  rateLimited,
  timeout,
  network,
  badResponse,
}

final class ProviderUnavailable implements Exception {
  const ProviderUnavailable(this.problem, [this.detail]);
  final ProviderProblem problem;
  final String? detail;

  @override
  String toString() => 'ProviderUnavailable(${problem.name}, $detail)';
}

/// Requests made and approximate money spent, per provider and calendar month.
abstract interface class UsageLedger {
  Future<ProviderUsage> usage(String providerId, DateTime now);
  Future<void> record(
    String providerId,
    DateTime now, {
    required int requests,
    required int costMicros,
  });
}

final class ProviderUsage {
  const ProviderUsage({required this.requests, required this.costMicros});
  static const none = ProviderUsage(requests: 0, costMicros: 0);
  final int requests;
  final int costMicros;
}

/// Month key `YYYY-MM`.
String usageMonth(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

class InMemoryUsageLedger implements UsageLedger {
  final _data = <String, ProviderUsage>{};

  @override
  Future<ProviderUsage> usage(String providerId, DateTime now) async =>
      _data['$providerId|${usageMonth(now)}'] ?? ProviderUsage.none;

  @override
  Future<void> record(
    String providerId,
    DateTime now, {
    required int requests,
    required int costMicros,
  }) async {
    final key = '$providerId|${usageMonth(now)}';
    final old = _data[key] ?? ProviderUsage.none;
    _data[key] = ProviderUsage(
      requests: old.requests + requests,
      costMicros: old.costMicros + costMicros,
    );
  }
}
