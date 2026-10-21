import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_ids.dart';
import '../domain/appearance.dart';
import '../domain/diet.dart';
import '../domain/food_avoidance.dart';
import '../domain/reminder_settings.dart';

/// Diet, avoidances, reminder and appearance settings, stored on the phone.
class PreferencesRepository {
  PreferencesRepository(this._db, [RowStamp? stamp])
    : _stamp = stamp ?? RowStamp();

  final AppDatabase _db;
  final RowStamp _stamp;

  /// Omnivore until the user chooses.
  Stream<Diet> watchDiet() => _livePreferences().watchSingleOrNull().map(
    (row) => row == null ? Diet.omnivore : Diet.values.byName(row.diet),
  );

  /// [AppearanceMode.system] until the user chooses.
  Future<AppearanceMode> appearance() async => AppearanceMode.fromName(
    (await _livePreferences().getSingleOrNull())?.appearance,
  );

  Future<void> saveAppearance(AppearanceMode mode) =>
      _savePreferences(UserPreferencesCompanion(appearance: Value(mode.name)));

  Future<void> saveDiet(Diet diet) =>
      _savePreferences(UserPreferencesCompanion(diet: Value(diet.name)));

  Stream<ReminderSettings> watchReminders() =>
      _livePreferences().watchSingleOrNull().map(
        (row) => row == null
            ? const ReminderSettings()
            : ReminderSettings(
                enabled: row.remindersEnabled,
                phaseChange: row.remindPhaseChange,
                beforePeriod: row.remindBeforePeriod,
              ),
      );

  Future<void> saveReminders(ReminderSettings settings) => _savePreferences(
    UserPreferencesCompanion(
      remindersEnabled: Value(settings.enabled),
      remindPhaseChange: Value(settings.phaseChange),
      remindBeforePeriod: Value(settings.beforePeriod),
    ),
  );

  /// Everything the user avoids, oldest first.
  Stream<List<FoodAvoidance>> watchAvoidances() =>
      _liveAvoidances().watch().map((rows) => rows.map(_avoidance).toList());

  Future<List<FoodAvoidance>> avoidances() async =>
      (await _liveAvoidances().get()).map(_avoidance).toList();

  Future<void> avoidAllergen(String allergenId) => _addAvoidance(
    kind: 'allergen',
    allergenId: Value(allergenId),
    matches: (t) => t.allergenId.equals(allergenId),
  );

  Future<void> avoidFood(String foodId) => _addAvoidance(
    kind: 'food',
    foodId: Value(foodId),
    matches: (t) => t.foodId.equals(foodId),
  );

  Future<void> avoidCustom(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return Future.value();
    return _addAvoidance(
      kind: 'custom',
      customLabel: Value(trimmed),
      matches: (t) => t.customLabel.lower().equals(trimmed.toLowerCase()),
    );
  }

  /// Stops avoiding something (a tombstone, so it can sync later).
  Future<void> removeAvoidance(String id) =>
      (_db.update(_db.foodAvoidances)..where((t) => t.id.equals(id))).write(
        FoodAvoidancesCompanion(
          deletedAt: Value(_stamp.now()),
          updatedAt: Value(_stamp.now()),
        ),
      );

  Future<void> _addAvoidance({
    required String kind,
    Value<String?> allergenId = const Value(null),
    Value<String?> foodId = const Value(null),
    Value<String?> customLabel = const Value(null),
    required Expression<bool> Function($FoodAvoidancesTable t) matches,
  }) => _db.transaction(() async {
    final already =
        await (_db.select(_db.foodAvoidances)..where(
              (t) => t.kind.equals(kind) & matches(t) & t.deletedAt.isNull(),
            ))
            .get();
    if (already.isNotEmpty) return;
    final now = _stamp.now();
    await _db
        .into(_db.foodAvoidances)
        .insert(
          FoodAvoidancesCompanion.insert(
            id: _stamp.newId(),
            createdAt: now,
            updatedAt: now,
            kind: kind,
            allergenId: allergenId,
            foodId: foodId,
            customLabel: customLabel,
          ),
        );
  });

  Future<void> _savePreferences(UserPreferencesCompanion values) =>
      _db.transaction(() async {
        final now = _stamp.now();
        final existing = await _livePreferences().getSingleOrNull();
        if (existing == null) {
          await _db
              .into(_db.userPreferences)
              .insert(
                values.copyWith(
                  id: Value(_stamp.newId()),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  diet: values.diet.present
                      ? values.diet
                      : Value(Diet.omnivore.name),
                ),
              );
        } else {
          await (_db.update(_db.userPreferences)
                ..where((t) => t.id.equals(existing.id)))
              .write(values.copyWith(updatedAt: Value(now)));
        }
      });

  SimpleSelectStatement<$UserPreferencesTable, UserPreferenceRow>
  _livePreferences() => _db.select(_db.userPreferences)
    ..where((t) => t.deletedAt.isNull())
    ..limit(1);

  SimpleSelectStatement<$FoodAvoidancesTable, FoodAvoidanceRow>
  _liveAvoidances() => _db.select(_db.foodAvoidances)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  static FoodAvoidance _avoidance(FoodAvoidanceRow row) => switch (row.kind) {
    'allergen' => AllergenAvoidance(id: row.id, allergenId: row.allergenId!),
    'food' => FoodItemAvoidance(id: row.id, foodId: row.foodId!),
    _ => CustomAvoidance(id: row.id, label: row.customLabel!),
  };
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(appDatabaseProvider)),
);
