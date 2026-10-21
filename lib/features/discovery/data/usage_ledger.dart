import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/provider_policy.dart';

/// Provider usage kept on the phone, so a monthly budget survives restarts.
class DriftUsageLedger implements UsageLedger {
  DriftUsageLedger(this._db);

  final AppDatabase _db;

  @override
  Future<ProviderUsage> usage(String providerId, DateTime now) async {
    final row =
        await (_db.select(_db.providerUsages)..where(
              (t) =>
                  t.providerId.equals(providerId) &
                  t.month.equals(usageMonth(now)),
            ))
            .getSingleOrNull();
    return row == null
        ? ProviderUsage.none
        : ProviderUsage(requests: row.requests, costMicros: row.costMicros);
  }

  @override
  Future<void> record(
    String providerId,
    DateTime now, {
    required int requests,
    required int costMicros,
  }) => _db.transaction(() async {
    final month = usageMonth(now);
    final old = await usage(providerId, now);
    await _db
        .into(_db.providerUsages)
        .insertOnConflictUpdate(
          ProviderUsagesCompanion.insert(
            providerId: providerId,
            month: month,
            requests: Value(old.requests + requests),
            costMicros: Value(old.costMicros + costMicros),
          ),
        );
  });
}

final usageLedgerProvider = Provider<UsageLedger>(
  (ref) => DriftUsageLedger(ref.watch(appDatabaseProvider)),
);
