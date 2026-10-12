import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/period_log.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/preferences/domain/reminder_settings.dart';
import 'package:moon_cycle/features/privacy/domain/data_export.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_item.dart';

void main() {
  final newer = PeriodLog(
    id: 'b',
    start: LocalDate(2026, 9, 28),
    end: LocalDate(2026, 10, 2),
    source: PeriodLogSource.manual,
  );
  final older = PeriodLog(
    id: 'a',
    start: LocalDate(2026, 8, 31),
    source: PeriodLogSource.onboarding,
    isEstimated: true,
  );

  Map<String, Object?> export() => buildDataExport(
    exportedAt: DateTime.utc(2026, 10, 12, 9),
    appVersion: '1.0.0',
    profile: const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
    periods: [newer, older],
    diet: Diet.vegetarian,
    avoidances: const [
      AllergenAvoidance(id: '1', allergenId: 'peanut'),
      FoodItemAvoidance(id: '2', foodId: 'mushrooms'),
      CustomAvoidance(id: '3', label: 'Coriander'),
    ],
    reminders: const ReminderSettings(enabled: true),
    shoppingList: [
      ShoppingItem(
        id: 'i',
        key: 'food:broccoli',
        foodId: 'broccoli',
        name: 'Broccoli',
        aisleId: 'produce',
        sources: const [
          ShoppingSource(
            id: 's',
            type: SourceType.phaseFood,
            phase: Phase.follicular,
          ),
        ],
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    ],
    foodName: (id) => id == 'mushrooms' ? 'Mushrooms' : null,
  );

  test('the JSON schema', () {
    final json = jsonDecode(jsonEncode(export())) as Map<String, dynamic>;
    expect(json.keys, [
      'format',
      'version',
      'exportedAt',
      'appVersion',
      'cycle',
      'preferences',
      'shoppingList',
    ]);
    expect(json['format'], exportFormat);
    expect(json['version'], 1);
    expect(json['exportedAt'], '2026-10-12T09:00:00.000Z');
    expect(json['cycle'], {
      'profile': {
        'cycleLength': 28,
        'periodLength': 5,
        'lutealLength': null,
        'useHistoryAverages': true,
      },
      'periods': [
        {
          'start': '2026-08-31',
          'end': null,
          'source': 'onboarding',
          'estimated': true,
        },
        {
          'start': '2026-09-28',
          'end': '2026-10-02',
          'source': 'manual',
          'estimated': false,
        },
      ],
    });
    expect(json['preferences'], {
      'diet': 'vegetarian',
      'avoid': [
        {'type': 'allergen', 'id': 'peanut'},
        {'type': 'food', 'id': 'mushrooms', 'name': 'Mushrooms'},
        {'type': 'custom', 'name': 'Coriander'},
      ],
      'reminders': {'enabled': true, 'phaseChange': true, 'beforePeriod': true},
    });
    expect(json['shoppingList'], [
      {
        'name': 'Broccoli',
        'foodId': 'broccoli',
        'aisle': 'produce',
        'done': false,
        'addedAt': '2026-10-01T00:00:00.000Z',
        'sources': [
          {
            'type': 'phaseFood',
            'phase': 'follicular',
            'recipeId': null,
            'amount': null,
            'unit': null,
            'quantity': null,
          },
        ],
      },
    ]);
  });

  test('no derived values (phase, predictions) are exported', () {
    final text = jsonEncode(export());
    for (final word in ['cycleDay', 'nextPeriod', 'ovulat', 'phaseDay']) {
      expect(text, isNot(contains(word)));
    }
  });

  test('periods as CSV, oldest first', () {
    expect(
      periodLogsCsv([newer, older]),
      'start,end,days,estimated\n'
      '2026-08-31,,,true\n'
      '2026-09-28,2026-10-02,5,false\n',
    );
  });
}
