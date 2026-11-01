import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the 98 unpublished Wave 1 profiles consistent with the catalogue and
/// the draft dataset they were built from (docs/food-profiles/
/// wave1_exception_report.py checks more, offline). Nothing here publishes.
void main() {
  Map<String, Object?> read(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

  final candidate =
      (read('docs/food-profiles/wave-1-candidate.json')['profiles']! as Map)
          .cast<String, Map<String, Object?>>();
  final drafts =
      (read('docs/food-profiles/complete-draft-dataset.json')['profiles']!
              as Map)
          .cast<String, Map<String, Object?>>();
  final foods = {
    for (final f
        in (read('assets/content/foods.json')['foods']! as List)
            .cast<Map<String, Object?>>())
      f['id']! as String: f,
  };

  const allergenWords = {
    'peanut': r'peanut',
    'tree-nut': r'tree[- ]?nut',
    'shellfish': r'shellfish|crustacean|mollus',
    'fish': r'\bfish\b',
    'dairy': r'dairy|milk',
    'egg': r'\begg',
    'gluten': r'gluten|wheat',
    'soy': r'\bsoy',
    'sesame': r'sesame',
  };

  test('98 candidates, each a real ship-ready catalogue food', () {
    expect(candidate, hasLength(98));
    for (final MapEntry(key: id, value: p) in candidate.entries) {
      final food = foods[id];
      expect(food, isNotNull, reason: '$id is not in the catalogue');
      expect(food!['shipReady'], isTrue, reason: id);
      expect(p['catalogueId'], id);
      expect(
        (p['name']! as String).toLowerCase(),
        (food['name']! as String).toLowerCase(),
        reason: '$id: names agree',
      );
    }
  });

  test('every catalogue allergen is named in the profile cautions', () {
    for (final MapEntry(key: id, value: p) in candidate.entries) {
      final cautions = [
        for (final c in (p['cautions']! as List).cast<Map<String, Object?>>())
          c['text']! as String,
      ].join(' ');
      for (final a
          in ((foods[id]!['allergens'] ?? const []) as List).cast<String>()) {
        expect(
          RegExp(allergenWords[a]!, caseSensitive: false).hasMatch(cautions),
          isTrue,
          reason: '$id: allergen $a missing from the cautions',
        );
      }
      for (final c in (p['cautions']! as List).cast<Map<String, Object?>>()) {
        expect((c['source'] as String?)?.isNotEmpty, isTrue, reason: '$id');
      }
    }
  });

  test('source and figures are identical to the draft dataset (not stale)', () {
    for (final MapEntry(key: id, value: p) in candidate.entries) {
      final d = drafts[id];
      expect(d, isNotNull, reason: '$id has no draft');
      expect(p['source'], d!['source'], reason: '$id source');
      final perServing = Map<String, Object?>.of(
        d['perServing']! as Map<String, Object?>,
      )..remove('sodiumMg');
      expect(p['perServing'], perServing, reason: '$id per-serving figures');
    }
  });

  test(
    'table percentages follow the shown amounts (allowing for rounding)',
    () {
      for (final MapEntry(key: id, value: p) in candidate.entries) {
        for (final n
            in ((p['perServing']! as Map)['keyNutrients']! as List)
                .cast<Map<String, Object?>>()) {
          final raw = n['amount']! as num;
          final amount = raw.toDouble();
          // An integer amount was rounded to a whole unit; a decimal to its digits.
          final decimals = raw is int ? 0 : raw.toString().split('.')[1].length;
          final half = 0.5 * _pow10neg(decimals);
          for (final r
              in ((n['reference'] ?? const []) as List)
                  .cast<Map<String, Object?>>()) {
            final value = (r['value']! as num).toDouble();
            final percent = (r['percent']! as num).toDouble();
            final lo = 100 * (amount - half) / value - 0.5;
            final hi = 100 * (amount + half) / value + 0.5;
            expect(
              percent,
              allOf(greaterThanOrEqualTo(lo), lessThanOrEqualTo(hi)),
              reason: '$id ${n['name']}: $percent% for $amount of $value',
            );
          }
        }
      }
    },
  );

  test('animal source and allergen tags agree across the catalogue', () {
    for (final MapEntry(key: id, value: f) in foods.entries) {
      final src = f['animalSource'];
      final al = ((f['allergens'] ?? const []) as List).cast<String>().toSet();
      if (src == 'egg') expect(al, contains('egg'), reason: id);
      if (src == 'seafood') {
        expect(al.intersection({'fish', 'shellfish'}), isNotEmpty, reason: id);
      }
    }
  });
}

double _pow10neg(int n) {
  var v = 1.0;
  for (var i = 0; i < n; i++) {
    v /= 10;
  }
  return v;
}
