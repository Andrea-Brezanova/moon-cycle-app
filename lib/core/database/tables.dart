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

/// Recipes the user generated, saved privately on the phone (Stage 3).
///
/// The recipe itself is stored as JSON in the app's own `Recipe` shape. A
/// signed-in user's rows mirror their server rows (`remote_id`); the server is
/// the source of truth once sync exists.
@TableIndex.sql(
  'CREATE UNIQUE INDEX personal_recipes_owner_key '
  'ON personal_recipes (owner_id, idempotency_key) WHERE deleted_at IS NULL',
)
@DataClassName('PersonalRecipeRow')
class PersonalRecipes extends Table with UserRow {
  /// The account that owns it (a development session id in dev builds).
  TextColumn get ownerId => text()();

  /// One per tap of "Create": a repeated request finds this row.
  TextColumn get idempotencyKey => text()();

  /// Canonical text of the selection, to spot a repeated choice.
  TextColumn get fingerprint => text()();
  TextColumn get title => text()();
  TextColumn get phase => text()();
  TextColumn get recipeJson => text()();

  /// `privateSaved`, `candidate`, `validated`, `approved` or `published`.
  TextColumn get lifecycle =>
      text().withDefault(const Constant('privateSaved'))();

  /// `devMock` or `cloud`, with the provider and model that made it.
  TextColumn get origin => text()();
  TextColumn get provenanceJson => text()();

  /// `none`, `pending`, `ready` or `failed`.
  TextColumn get imageStatus => text().withDefault(const Constant('none'))();
  TextColumn get imageRefJson => text().nullable()();

  /// The server row id, once the recipe exists there.
  TextColumn get remoteId => text().nullable()();
}

/// What the user ate, logged by hand (Log Diary). Local only.
///
/// One row per (day, meal, item, unit): logging the same thing again adds to
/// its amount instead of making a second row. The title is a snapshot so an
/// entry still reads right if its recipe is later deleted.
@TableIndex.sql(
  'CREATE UNIQUE INDEX diary_entries_item_live '
  'ON diary_entries ("date", meal, kind, item_id, unit) '
  'WHERE deleted_at IS NULL',
)
@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table with UserRow {
  TextColumn get date => text().map(const LocalDateConverter())();

  /// `breakfast`, `lunch`, `dinner` or `snack`.
  TextColumn get meal => text()();

  /// `food`, `recipe` or `custom` (a meal the user typed; see [itemId]).
  TextColumn get kind => text()();

  /// The catalogue food id or the recipe id. A `custom` meal has no catalogue
  /// item, so it uses its own row id here: that keeps the unique index below
  /// from ever merging two typed meals.
  TextColumn get itemId => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();

  /// `serving`, `g`, `oz`, `cup` or `piece`.
  TextColumn get unit => text()();

  /// The user's note on this meal (schema 6). Null when there is none.
  TextColumn get note => text().nullable()();
}

/// One answer in a day's symptom check-in (schema 6). Local only.
///
/// A day is a set of rows, not one submission, so answers can be added, changed
/// or removed at any time. [category] is `energy`, `mood`, `body`, `sleep` or
/// `note`; [symptom] is a key from a fixed vocabulary (or `note`). At most one
/// live row per day and symptom; the repository keeps energy and sleep to one
/// answer each. Nothing here is interpreted, scored or diagnosed.
@TableIndex.sql(
  'CREATE UNIQUE INDEX symptom_checkins_live '
  'ON symptom_checkins ("date", category, symptom) '
  'WHERE deleted_at IS NULL',
)
@DataClassName('SymptomCheckinRow')
class SymptomCheckins extends Table with UserRow {
  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get category => text()();
  TextColumn get symptom => text()();

  /// Body symptoms only (`mild|moderate|strong`, or bleeding's
  /// `spotting|light|medium|heavy`). Null when not given.
  TextColumn get severity => text().nullable()();

  /// The free-text note, on the `note` row.
  TextColumn get note => text().nullable()();
}

/// A free-writing diary note (schema 7). Local only, in the encrypted database.
///
/// Several notes per day are allowed. [title] is optional; [body] is the
/// writing itself. Deleting a note tombstones the row *and* empties [title] and
/// [body], so deleted writing is not kept. Nothing here is analysed, scored or
/// sent anywhere.
@TableIndex.sql(
  'CREATE INDEX diary_notes_live '
  'ON diary_notes ("date") '
  'WHERE deleted_at IS NULL',
)
@DataClassName('DiaryNoteRow')
class DiaryNotes extends Table with UserRow {
  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
}

/// A movement the user chose to note (schema 8). Local only, in the encrypted
/// database.
///
/// [type] is a key from a fixed list (walk, run, yoga, ...; `other` may carry
/// a [customName]). [minutes], [intensity] (`light|moderate|vigorous`) and
/// [note] are optional and null when not given. Nothing is estimated,
/// scored or interpreted: no calories, no targets. Deleting tombstones the row
/// and empties [customName] and [note].
@TableIndex.sql(
  'CREATE INDEX diary_activities_live '
  'ON diary_activities ("date") '
  'WHERE deleted_at IS NULL',
)
@DataClassName('DiaryActivityRow')
class DiaryActivities extends Table with UserRow {
  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get type => text()();
  TextColumn get customName => text().nullable()();
  IntColumn get minutes => integer().nullable()();
  TextColumn get intensity => text().nullable()();
  TextColumn get note => text().nullable()();
}

/// A link the user saved to one of My Collections' three categories (schema
/// 9): a recipe, workout or sound found elsewhere. Only what the user typed is
/// kept (address, title, creator, note); nothing is fetched from the page and
/// no media is copied. [category] is `recipes`, `workouts` or `sounds` and can
/// be changed later. Local only, in the encrypted database. Deleting
/// tombstones the row and empties the creator and note.
@TableIndex.sql(
  'CREATE INDEX collection_links_live '
  'ON collection_links (category) '
  'WHERE deleted_at IS NULL',
)
@DataClassName('CollectionLinkRow')
class CollectionLinks extends Table with UserRow {
  TextColumn get category => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get creator => text().nullable()();

  /// Worked out from the address: `youtube`, `instagram`, `tiktok`,
  /// `pinterest`, `website`.
  TextColumn get platform => text()();
  TextColumn get note => text().nullable()();
}

/// A routine the user built in My Routines (schema 10, DRAFT): a title and
/// optional note. Its ordered steps are in [RoutineSteps]. Local only, in the
/// encrypted database; deleting tombstones the row and empties the note.
@DataClassName('RoutineRow')
class Routines extends Table with UserRow {
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();

  /// `routine` (My Routines) or `workout` (a workout built in Move › Build
  /// Your Workout and kept in My Workouts). Added in schema 11; rows from
  /// schema 10 are routines.
  TextColumn get kind => text().withDefault(const Constant('routine'))();
}

/// One step of a routine, in [position] order: a saved link (by id, never a
/// copy) or a line of the user's own text. [kind] is `link` or `text`.
@TableIndex.sql(
  'CREATE INDEX routine_steps_live '
  'ON routine_steps (routine_id, position) '
  'WHERE deleted_at IS NULL',
)
@DataClassName('RoutineStepRow')
class RoutineSteps extends Table with UserRow {
  TextColumn get routineId => text().references(Routines, #id)();
  IntColumn get position => integer()();
  TextColumn get kind => text()();
  TextColumn get linkId => text().nullable()();
  TextColumn get body => text().nullable()();
}

/// How many requests each external recipe provider has been sent this month,
/// and roughly what they cost, so a monthly budget can be enforced.
@DataClassName('ProviderUsageRow')
class ProviderUsages extends Table {
  TextColumn get providerId => text()();

  /// `YYYY-MM`.
  TextColumn get month => text()();
  IntColumn get requests => integer().withDefault(const Constant(0))();

  /// Millionths of a US dollar.
  IntColumn get costMicros => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, month};
}

/// A recipe the user saved to My recipes, **by reference**: a Moon Cycle recipe
/// id, or an external provider's id with just the title and source link. Never
/// the ingredients or method of a third-party recipe (their terms do not allow
/// keeping them); the recipe is fetched again when it is opened.
@TableIndex.sql(
  'CREATE UNIQUE INDEX saved_recipe_refs_live '
  'ON saved_recipe_refs (provider_id, ref_id) WHERE deleted_at IS NULL',
)
@DataClassName('SavedRecipeRefRow')
class SavedRecipeRefs extends Table with UserRow {
  /// `moon-cycle` or the provider's short id.
  TextColumn get providerId => text()();

  /// The recipe id as the app uses it (`x-themealdb-52772`, or a library id).
  TextColumn get refId => text()();

  /// The provider's own id (null for a library recipe).
  TextColumn get externalId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get sourceUrl => text().nullable()();
}
