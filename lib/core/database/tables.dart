import 'package:drift/drift.dart';

import '../domain/local_date.dart';

/// Columns every user table has, so rows can sync later (plan §8.3):
/// a client-made id, timestamps from the device clock, and a tombstone
/// instead of a hard delete.
mixin UserRow on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set instead of deleting the row (a tombstone).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Calendar dates are stored as `YYYY-MM-DD` text.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toString();
}

/// One row: the user's typical cycle values.
@DataClassName('CycleProfileRow')
class CycleProfiles extends Table with UserRow {
  IntColumn get cycleLength => integer()();
  IntColumn get periodLength => integer()();
  IntColumn get lutealLength => integer().nullable()();
  BoolColumn get useHistoryAverages =>
      boolean().withDefault(const Constant(true))();
}

@TableIndex.sql(
  'CREATE UNIQUE INDEX period_logs_start_live '
  'ON period_logs (start_date) WHERE deleted_at IS NULL',
)
@DataClassName('PeriodLogRow')
class PeriodLogs extends Table with UserRow {
  TextColumn get startDate => text().map(const LocalDateConverter())();
  TextColumn get endDate => text().map(const LocalDateConverter()).nullable()();

  /// `onboarding` or `manual`.
  TextColumn get source => text()();
  BoolColumn get isEstimated => boolean().withDefault(const Constant(false))();
}

/// One row: diet, reminder and appearance settings.
@DataClassName('UserPreferenceRow')
class UserPreferences extends Table with UserRow {
  /// `omnivore`, `pescatarian`, `vegetarian` or `vegan`.
  TextColumn get diet => text()();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get remindPhaseChange =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get remindBeforePeriod =>
      boolean().withDefault(const Constant(true))();

  /// `system`, `light` or `dark` (Settings › Appearance).
  TextColumn get appearance => text().withDefault(const Constant('system'))();
}

@DataClassName('FoodAvoidanceRow')
class FoodAvoidances extends Table with UserRow {
  /// `allergen`, `food` or `custom`; exactly one of the next three is set.
  TextColumn get kind => text()();
  TextColumn get allergenId => text().nullable()();
  TextColumn get foodId => text().nullable()();
  TextColumn get customLabel => text().nullable()();
}

@TableIndex.sql(
  'CREATE UNIQUE INDEX shopping_items_key_live '
  'ON shopping_items ("key") WHERE deleted_at IS NULL',
)
@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table with UserRow {
  /// `food:<foodId>` or `text:<normalised name>` (plan §9.1).
  TextColumn get key => text()();
  TextColumn get foodId => text().nullable()();

  /// The name as shown, kept so the row still renders if a food is retired.
  TextColumn get name => text()();
  TextColumn get aisleId => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
}

/// Why an item is on the list. The displayed quantity is derived from these
/// rows, so merging only ever adds a source.
@DataClassName('ShoppingSourceRow')
class ShoppingSources extends Table with UserRow {
  TextColumn get itemId => text().references(ShoppingItems, #id)();

  /// `phaseFood`, `recipe` or `manual`.
  TextColumn get type => text()();
  TextColumn get phaseId => text().nullable()();
  TextColumn get recipeId => text().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get qtyText => text().nullable()();
}

/// Local-only app state (never synced). One row.
@DataClassName('AppStateRow')
class AppStates extends Table {
  /// Always 1.
  IntColumn get id => integer()();
  DateTimeColumn get onboardingCompletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
