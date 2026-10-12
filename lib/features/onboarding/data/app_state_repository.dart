import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Local-only app state: whether onboarding is complete.
class AppStateRepository {
  AppStateRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// The table holds one row.
  static const _row = 1;

  Future<bool> isOnboardingComplete() async {
    final row = await (_db.select(
      _db.appStates,
    )..where((t) => t.id.equals(_row))).getSingleOrNull();
    return row?.onboardingCompletedAt != null;
  }

  Future<void> markOnboardingComplete() => _db
      .into(_db.appStates)
      .insertOnConflictUpdate(
        AppStatesCompanion.insert(
          id: const Value(_row),
          onboardingCompletedAt: Value(_now()),
        ),
      );
}
