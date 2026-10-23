import '../../../core/domain/local_date.dart';
import '../../cycle/domain/cycle_profile.dart';
import '../../cycle/domain/period_log.dart';
import '../../diary/domain/diary_activity.dart';
import '../../diary/domain/diary_entry.dart';
import '../../diary/domain/diary_note.dart';
import '../../generation/domain/personal_recipe.dart';
import '../../generation/domain/recipe_json.dart';
import '../../generation/domain/saved_recipe_ref.dart';
import '../../preferences/domain/diet.dart';
import '../../preferences/domain/food_avoidance.dart';
import '../../preferences/domain/reminder_settings.dart';
import '../../shopping/domain/shopping_item.dart';

/// Identifies the file, so a later import can recognise it.
const exportFormat = 'moon-cycle-export';

/// Bumped whenever a field is renamed or removed.
const exportVersion = 1;

/// Everything the user has stored on the phone, as plain JSON values
/// (plan §12, "Export"). Derived values (phase, cycle day, predictions)
/// aren't included: they're always recalculated.
///
/// [foodName] turns a catalogue food id into its name, so the file is
/// readable on its own.
Map<String, Object?> buildDataExport({
  required DateTime exportedAt,
  required String appVersion,
  required CycleProfile? profile,
  required List<PeriodLog> periods,
  required Diet diet,
  required List<FoodAvoidance> avoidances,
  required ReminderSettings reminders,
  required List<ShoppingItem> shoppingList,
  List<PersonalRecipe> personalRecipes = const [],
  List<DiaryEntry> diary = const [],
  List<DiaryNote> notes = const [],
  List<DiaryActivity> activities = const [],
  List<SavedRecipeRef> savedRecipes = const [],
  required String? Function(String foodId) foodName,
}) => {
  'format': exportFormat,
  'version': exportVersion,
  'exportedAt': exportedAt.toUtc().toIso8601String(),
  'appVersion': appVersion,
  'cycle': {
    'profile': profile == null
        ? null
        : {
            'cycleLength': profile.typicalCycleLength,
            'periodLength': profile.typicalPeriodLength,
            'lutealLength': profile.lutealLength,
            'useHistoryAverages': profile.useHistoryAverages,
          },
    'periods': [
      for (final p in [...periods]..sort((a, b) => a.start.compareTo(b.start)))
        {
          'start': '${p.start}',
          'end': p.end == null ? null : '${p.end}',
          'source': p.source.name,
          'estimated': p.isEstimated,
        },
    ],
  },
  'preferences': {
    'diet': diet.name,
    'avoid': [
      for (final a in avoidances)
        switch (a) {
          AllergenAvoidance(:final allergenId) => {
            'type': 'allergen',
            'id': allergenId,
          },
          FoodItemAvoidance(:final foodId) => {
            'type': 'food',
            'id': foodId,
            'name': foodName(foodId),
          },
          CustomAvoidance(:final label) => {'type': 'custom', 'name': label},
        },
    ],
    'reminders': {
      'enabled': reminders.enabled,
      'phaseChange': reminders.phaseChange,
      'beforePeriod': reminders.beforePeriod,
    },
  },
  'shoppingList': [
    for (final item in shoppingList)
      {
        'name': item.name,
        'foodId': item.foodId,
        'aisle': item.aisleId,
        'done': item.done,
        'addedAt': item.createdAt.toUtc().toIso8601String(),
        'sources': [
          for (final s in item.sources)
            {
              'type': s.type.name,
              'phase': s.phase?.name,
              'recipeId': s.recipeId,
              'amount': s.amount,
              'unit': s.unit,
              'quantity': s.qtyText,
            },
        ],
      },
  ],
  'diary': [
    for (final e in diary)
      {
        'date': '${e.date}',
        'meal': e.meal.name,
        'type': e.kind.name,
        'id': e.itemId,
        'name': e.title,
        'amount': e.amount,
        'unit': e.unit.id,
      },
  ],
  'notes': [
    for (final n in notes)
      {
        'date': '${n.date}',
        'title': n.title,
        'text': n.body,
        'createdAt': n.createdAt.toUtc().toIso8601String(),
        'updatedAt': n.updatedAt.toUtc().toIso8601String(),
      },
  ],
  'activities': [
    for (final a in activities)
      {
        'date': '${a.date}',
        'type': a.type.name,
        'name': a.customName,
        'minutes': a.minutes,
        'intensity': a.intensity?.name,
        'note': a.note,
        'createdAt': a.createdAt.toUtc().toIso8601String(),
        'updatedAt': a.updatedAt.toUtc().toIso8601String(),
      },
  ],
  'savedRecipes': [
    for (final r in savedRecipes)
      {
        'provider': r.providerId,
        'id': r.refId,
        'title': r.title,
        'sourceUrl': r.sourceUrl,
        'savedAt': r.savedAt.toUtc().toIso8601String(),
      },
  ],
  'personalRecipes': [
    for (final r in personalRecipes)
      {
        'id': r.id,
        'createdAt': r.createdAt.toUtc().toIso8601String(),
        'lifecycle': r.lifecycle.name,
        'origin': r.provenance.origin.name,
        'provider': r.provenance.provider,
        'model': r.provenance.model,
        'recipe': recipeToJson(r.recipe),
      },
  ],
};

/// The period history as a small spreadsheet: start, end, days.
String periodLogsCsv(List<PeriodLog> periods) {
  final rows = [
    'start,end,days,estimated',
    for (final p in [...periods]..sort((a, b) => a.start.compareTo(b.start)))
      [
        p.start,
        p.end ?? '',
        if (p.end case final LocalDate end) p.start.daysUntil(end) + 1 else '',
        p.isEstimated,
      ].join(','),
  ];
  return '${rows.join('\n')}\n';
}
