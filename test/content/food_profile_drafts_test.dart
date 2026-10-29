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

  test(
    'every catalogue food is approved, drafted or blocked with a reason',
    () {
      final drafted = <String>{
        for (final f in files)
          ...((jsonDecode(f.readAsStringSync()) as Map)['profiles'] as Map).keys
              .cast<String>(),
      };
      final blocked = (jsonDecode(
        File('docs/food-profiles/blocked.json').readAsStringSync(),
      ) as Map).cast<String, String>();
      for (final id in foods) {
        final states = [
          approved.containsKey(id),
          drafted.contains(id),
          blocked.containsKey(id),
        ];
        expect(states.where((s) => s).length, 1, reason: '$id: $states');
      }
      for (final reason in blocked.values) {
        expect(reason.trim(), isNotEmpty);
      }
    },
  );

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
            expect(
              text.contains('TBD'),
              isFalse,
              reason: '$id $k is a placeholder',
            );
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

  group('audit regression checks (all drafts together)', () {
    final all = <String, Map<String, Object?>>{
      for (final f in files)
        ...((jsonDecode(f.readAsStringSync()) as Map)['profiles'] as Map)
            .cast<String, Map<String, Object?>>(),
    };
    final catalogue = {
      for (final f
          in (jsonDecode(File('assets/content/foods.json').readAsStringSync())
                  as Map)['foods']
              as List)
        (f as Map)['id'] as String: f,
    };
    Map<String, Object?> src(String id) =>
        all[id]!['source']! as Map<String, Object?>;

    test('every draft cites its USDA record, preparation and serving', () {
      final ids = <int>{};
      for (final id in all.keys) {
        final s = src(id);
        expect(s['usdaFdcId'], isA<int>(), reason: id);
        expect(
          ids.add(s['usdaFdcId']! as int),
          isTrue,
          reason: '$id reuses an FDC id',
        );
        for (final k in [
          'usdaDescription',
          'dataType',
          'published',
          'preparationState',
          'portion',
        ]) {
          expect((s[k] as String?)?.trim(), isNotEmpty, reason: '$id $k');
        }
        expect(
          ['SR Legacy', 'Foundation'],
          contains(s['dataType']),
          reason: id,
        );
        expect(s['portionGrams'] as num, greaterThan(0), reason: id);
        expect(
          (all[id]!['sections']! as Map)['practicalServing'],
          s['portion'],
          reason: '$id serving text must match the source portion',
        );
      }
    });

    test('the preparation named matches the USDA description', () {
      // Raw foods must say raw and cooked foods cooked: a profile must never
      // describe a raw record as cooked, or the other way round.
      for (final id in all.keys) {
        final desc = (src(id)['usdaDescription']! as String).toLowerCase();
        final state = (src(id)['preparationState']! as String).toLowerCase();
        for (final w in [
          'raw',
          'cooked',
          'canned',
          'roasted',
          'baked',
          'boiled',
          'steamed',
          'smoked',
        ]) {
          // "baked" in a record name can be a dish (baked beans, canned).
          if (w == 'baked' && state.contains('canned')) continue;
          if (RegExp('\\b$w\\b').hasMatch(desc)) {
            final cooked = RegExp(r'cooked|baked|boiled|roasted|steamed|fried');
            expect(
              const {
                    'cooked',
                    'baked',
                    'boiled',
                    'roasted',
                    'steamed',
                  }.contains(w)
                  ? cooked.hasMatch(state)
                  : w == 'raw'
                  ? RegExp(r'raw|dry|uncooked').hasMatch(state)
                  : state.contains(w),
              isTrue,
              reason: '$id: record says "$w", state says "$state"',
            );
          }
        }
        if (RegExp(r'\braw\b').hasMatch(state)) {
          // A record that names a cooked or processed state is never raw.
          expect(
            RegExp(r'cooked|boiled|roasted|canned|baked|steamed|dried')
                .hasMatch(desc),
            isFalse,
            reason: '$id: state says raw, record "$desc"',
          );
        }
      }
    });

    test('sodium is recorded and recomputes from the USDA value', () {
      for (final id in all.keys) {
        final per100 = (src(id)['per100g']! as Map).cast<String, num>();
        final serving = all[id]!['perServing']! as Map<String, Object?>;
        expect(per100, contains('na'), reason: '$id has no sodium value');
        final grams = (src(id)['portionGrams']! as num).toDouble();
        expect(serving['sodiumMg'], isNotNull, reason: id);
        expect(
          (serving['sodiumMg']! as num).toDouble(),
          closeTo(per100['na']! * grams / 100, 0.51),
          reason: '$id sodium',
        );
      }
    });

    test('allergen tags match the catalogue and appear in the cautions', () {
      const words = {
        'tree-nut': ['tree-nut', 'tree nut'],
        'peanut': ['peanut'],
        'fish': ['fish allergen'],
        'shellfish': ['crustacean', 'mollusc', 'shellfish'],
        'gluten': ['gluten', 'wheat'],
        'dairy': ['dairy'],
        'soy': ['soy'],
        'egg': ['egg allergen'],
        'sesame': ['sesame'],
      };
      for (final id in all.keys) {
        final cat = catalogue[id]!;
        final p = all[id]!;
        expect(
          (p['allergens']! as List).toSet(),
          (cat['allergens'] as List).toSet(),
          reason: '$id allergens must equal the catalogue',
        );
        expect(
          (p['mayContainAllergens']! as List).toSet(),
          ((cat['mayContainAllergens'] as List?) ?? const []).toSet(),
          reason: '$id may-contain',
        );
        final text = (p['cautions']! as List)
            .map((c) => (c as Map)['text'].toString().toLowerCase())
            .join(' ');
        for (final a in (p['allergens']! as List).cast<String>()) {
          expect(
            words[a]!.any(text.contains),
            isTrue,
            reason: '$id: allergen "$a" is not stated in its cautions',
          );
        }
        // Every catalogue caution is kept.
        for (final c in (cat['cautions'] as List).cast<String>()) {
          expect(
            text,
            contains(c.toLowerCase()),
            reason: '$id lost caution "$c"',
          );
        }
      }
    });

    test('cautions are real: sourced, never placeholders, salty foods say sodium', () {
      for (final id in all.keys) {
        final cautions = (all[id]!['cautions']! as List)
            .cast<Map<String, Object?>>();
        for (final c in cautions) {
          expect((c['text'] as String).trim(), isNotEmpty, reason: id);
          expect((c['source'] as String).trim(), isNotEmpty, reason: id);
          expect(
            '${c['text']}${c['source']}',
            isNot(contains('TBD')),
            reason: id,
          );
        }
        final serving = all[id]!['perServing']! as Map<String, Object?>;
        if ((serving['sodiumMg']! as num) >= 345) {
          expect(
            cautions.any((c) => (c['text'] as String).contains('mg of sodium')),
            isTrue,
            reason:
                '$id has ${serving['sodiumMg']} mg of sodium and no sodium note',
          );
        }
      }
    });

    test(
      'prose has no placeholders, boilerplate, doubled words or unit slips',
      () {
        final doubled = RegExp(r'\b(\w{3,})\s+\1\b', caseSensitive: false);
        for (final id in all.keys) {
          final sections = (all[id]!['sections']! as Map)
              .cast<String, String>();
          for (final MapEntry(key: k, value: t) in sections.entries) {
            expect(
              t,
              isNot(contains('{')),
              reason: '$id $k has a template slot',
            );
            expect(
              RegExp(r'\b1 calories').hasMatch(t),
              isFalse,
              reason: '$id $k',
            );
            expect(
              doubled.hasMatch(t),
              isFalse,
              reason: '$id $k repeats a word: $t',
            );
            expect(
              t,
              isNot(matches(RegExp(r'\s{2,}'))),
              reason: '$id $k has double spaces',
            );
            expect(t.trim(), t, reason: '$id $k has stray whitespace');
          }
          final cycle = sections['cycleRelevance']!;
          expect(
            cycle.toLowerCase(),
            isNot(contains('this profile')),
            reason: id,
          );
          expect(
            cycle.toLowerCase(),
            isNot(contains('varied diet')),
            reason: id,
          );
          expect(
            RegExp(r'(cycle-phase|phase-specific) claim').hasMatch(cycle),
            isTrue,
            reason: '$id must say no phase claim is made',
          );
          // Opening line leads with the food, not the raw USDA record name.
          final record = src(id)['usdaDescription']! as String;
          if (record.contains(',')) {
            expect(
              sections['whatItOffers'],
              isNot(contains(record)),
              reason: id,
            );
          }
        }
      },
    );

    test(
      'no hormone, fertility, PMS, mood or phase-benefit claims anywhere',
      () {
        final claim = RegExp(
          r'hormon|fertil|ovulat|follicular|luteal|premenstrual|\bPMS\b|cramp|'
          r'\bmood|estrogen|oestrogen|progesterone|testosterone|detox|\bboosts?\b|'
          r'inflammat|immune|immunity|period (pain|symptoms)|menstrual (phase|pain|symptoms)',
          caseSensitive: false,
        );
        for (final id in all.keys) {
          final sections = (all[id]!['sections']! as Map)
              .cast<String, String>();
          for (final MapEntry(key: k, value: t) in sections.entries) {
            expect(claim.hasMatch(t), isFalse, reason: '$id $k: $t');
          }
          // The only menstrual wording allowed is the sourced iron sentence.
          final cycle = sections['cycleRelevance']!;
          if (cycle.toLowerCase().contains('menstrual')) {
            expect(
              cycle,
              contains('menstrual blood loss (NIH ODS)'),
              reason: id,
            );
          }
        }
      },
    );

    test('every blocked food has a complete decision-table entry', () {
      final blocked = (jsonDecode(
        File('docs/food-profiles/blocked.json').readAsStringSync(),
      ) as Map).keys.toSet();
      final decisions = jsonDecode(
        File('docs/food-profiles/blocked-decisions.json').readAsStringSync(),
      ) as Map;
      expect(decisions.keys.toSet(), blocked);
      for (final MapEntry(key: id, value: d) in decisions.entries) {
        for (final k in [
          'why',
          'standardNutrientInfo',
          'alternativeFormat',
          'keepInCatalogue',
          'recommendation',
        ]) {
          expect(
            ((d as Map)[k] as String?)?.trim(),
            isNotEmpty,
            reason: '$id $k',
          );
        }
      }
    });
  });
}
