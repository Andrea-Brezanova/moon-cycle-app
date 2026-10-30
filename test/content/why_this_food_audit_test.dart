import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the "Why this food?" catalogue copy while its wording is under review
/// (docs/food-profiles/why-this-food-audit.md). Production copy is unchanged.
void main() {
  final foods =
      (jsonDecode(File('assets/content/foods.json').readAsStringSync())
              as Map<String, Object?>)['foods']
          as List<Object?>;
  final approved =
      (jsonDecode(File('assets/content/food_profiles.json').readAsStringSync())
              as Map<String, Object?>)['profiles']
          as Map<String, Object?>;
  final drafts =
      ((jsonDecode(
            File('docs/food-profiles/complete-draft-dataset.json')
                .readAsStringSync(),
          ) as Map)['profiles']
          as Map);

  // Stated "about N% of the daily value per serving" figures that do not match
  // the verified serving. Listed in the audit with proposed replacements; no
  // new one may appear.
  const knownMismatches = {'oyster', 'sardine', 'quinoa', 'anchovies'};

  test(
    'stated iron percentages match the verified serving, except the known',
    () {
      final mismatched = <String>{};
      for (final f in foods.cast<Map<String, Object?>>()) {
        final id = f['id'] as String;
        final profile = (approved[id] ?? drafts[id]) as Map<String, Object?>?;
        for (final w
            in ((f['why']! as Map).values).cast<Map<String, Object?>>()) {
          final m = RegExp(r'(\d+)% of the daily value')
              .firstMatch(w['short'] as String);
          if (m == null) continue;
          expect(profile, isNotNull, reason: '$id has a figure but no profile');
          final src = profile!['source']! as Map<String, Object?>;
          final iron = (((src['per100g']! as Map)['iron']!) as num).toDouble();
          final pct = 100 * iron * (src['portionGrams'] as num) / 100 / 18;
          if ((pct - int.parse(m.group(1)!)).abs() > 2.5) mismatched.add(id);
        }
      }
      expect(mismatched, knownMismatches);
    },
  );

  test('no why-copy promises a hormonal, fertility, PMS or mood effect', () {
    final claim = RegExp(
      r'hormon|fertil|ovulat\w* (support|boost)|\bPMS\b|\bmood\b|cramp|detox|balanc',
      caseSensitive: false,
    );
    for (final f in foods.cast<Map<String, Object?>>()) {
      for (final w
          in ((f['why']! as Map).values).cast<Map<String, Object?>>()) {
        expect(
          claim.hasMatch(w['short'] as String),
          isFalse,
          reason: '${f['id']}',
        );
        expect(
          claim.hasMatch(w['detail'] as String),
          isFalse,
          reason: '${f['id']}',
        );
      }
    }
  });

  test('the audit lists every phase-linked line with a replacement', () {
    final audit = jsonDecode(
      File('docs/food-profiles/why-this-food-audit.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final flagged = (audit['foods']! as List)
        .cast<Map<String, Object?>>()
        .where((r) => r['needsChange'] == true);
    expect(flagged, isNotEmpty);
    for (final r in flagged) {
      expect(r['proposedReplacement'], isNotNull, reason: '${r['id']}');
      expect(
        r['proposedReplacement'] as String,
        isNot(contains('menstruation')),
      );
      expect(r['proposedReplacement'] as String, isNot(contains('luteal')));
    }
    // The proposals are in the audit only: production still has the old lines.
    final text = File('assets/content/foods.json').readAsStringSync();
    expect(text, contains('highlight them during menstruation'));
  });
}
