import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The draft Food Detail profiles (docs/food-profiles/draft-batch-*.json) are
/// research for editorial review. They must stay unpublishable, make no
/// treatment or hormone claims, and every number must be recomputable from the
/// USDA per-100 g values and the serving weight they name.
void main() {
  final files = Directory('docs/food-profiles')
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'draft-batch-\d+\.json$').hasMatch(f.path))
      .toList();
  final approved =
      (jsonDecode(File('assets/content/food_profiles.json').readAsStringSync())
              as Map)['profiles']
          as Map;
  final queue = {
    for (final i
        in (jsonDecode(
              File('docs/food-profiles/work-queue.json').readAsStringSync(),
            ) as Map)['items']
            as List)
      (i as Map)['foodId'] as String,
  };
  final foods = {
    for (final f
        in (jsonDecode(File('assets/content/foods.json').readAsStringSync())
                as Map)['foods']
            as List)
      (f as Map)['id'] as String,
  };

  test('there is at least one draft batch', () => expect(files, isNotEmpty));

  for (final file in files) {
    final profiles =
        (jsonDecode(file.readAsStringSync()) as Map)['profiles'] as Map;
    group(file.uri.pathSegments.last, () {
      test('no profile is publishable, approved or already in the app', () {
        for (final MapEntry(key: id, value: p) in profiles.entries) {
          final review = (p! as Map<String, Object?>)['review']! as Map;
          expect(review['publishable'], isFalse, reason: '$id');
          expect(approved.containsKey(id), isFalse, reason: '$id is approved');
          expect(queue, contains(id));
          expect(foods, contains(id), reason: 'catalogue id');
        }
      });

      test(
        'serving amounts and percentages recompute from the USDA values',
        () {
          for (final MapEntry(key: id, value: raw) in profiles.entries) {
            final p = raw as Map<String, Object?>;
            final src = p['source']! as Map<String, Object?>;
            final grams = (src['portionGrams'] as num).toDouble();
            final per100 = (src['per100g']! as Map<String, Object?>)
                .cast<String, num>();
            final serving = p['perServing']! as Map<String, Object?>;
            expect(
              serving['energyKcal'],
              (per100['kcal']! * grams / 100).round(),
              reason: '$id kcal',
            );
            const keyOf = {
              'Iron': 'iron',
              'Folate': 'folate',
              'Vitamin C': 'vitc',
              'Vitamin K': 'vitk',
              'Magnesium': 'mg',
              'Zinc': 'zn',
              'Potassium': 'k',
              'Vitamin A': 'vita',
              'Calcium': 'ca',
              'Vitamin B12': 'b12',
              'Vitamin D': 'vitd',
              'Vitamin E': 'vite',
              'Protein': 'protein',
              'Fiber': 'fiber',
              'Omega-3 (EPA + DHA)': 'omega3',
            };
            for (final n
                in (serving['keyNutrients']! as List)
                    .cast<Map<String, Object?>>()) {
              final v = per100[keyOf[n['name']]]! * grams / 100;
              expect(
                (n['amount'] as num).toDouble(),
                closeTo(
                  v,
                  (n['amount'] as num) == (n['amount'] as num).roundToDouble()
                      ? 0.51
                      : 0.06,
                ),
                reason: '$id ${n['name']}',
              );
              for (final r
                  in ((n['reference'] as List?) ?? const [])
                      .cast<Map<String, Object?>>()) {
                expect(
                  r['percent'],
                  (100 * v / (r['value'] as num)).round(),
                  reason: '$id ${n['name']} ${r['group']}',
                );
              }
            }
          }
        },
      );

      test('every profile has the five parts, a source and no forbidden claims', () {
        final banned = RegExp(
          r'detox|hormone[- ]?balanc|balances? (your )?hormones|\bcures?\b|'
          r'\btreats?\b|\bheal(s|ing|ed)?\b|regulates? (your )?(cycle|period)|'
          r'relieves? (cramps|pms|symptoms)',
          caseSensitive: false,
        );
        for (final MapEntry(key: id, value: raw) in profiles.entries) {
          final p = raw as Map<String, Object?>;
          final sections = p['sections']! as Map<String, Object?>;
          for (final k in [
            'whatItOffers',
            'practicalServing',
            'howToEatIt',
            'cycleRelevance',
          ]) {
            final text = sections[k] as String?;
            expect(text, isNotNull, reason: '$id $k');
            expect(text!.trim(), isNotEmpty, reason: '$id $k');
            expect(banned.hasMatch(text), isFalse, reason: '$id $k: $text');
          }
          expect(
            (p['source']! as Map<String, Object?>)['usdaFdcId'],
            isA<int>(),
          );
          for (final c
              in (p['cautions']! as List).cast<Map<String, Object?>>()) {
            expect(
              c['source'],
              isNotEmpty,
              reason: '$id caution needs a source',
            );
          }
        }
      });
    });
  }
}
