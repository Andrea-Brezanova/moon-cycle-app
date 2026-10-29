import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The independent assessment (docs/food-profiles/phase-independent-assessment.json)
/// reviews the 142 phase-assigned foods without changing any of them.
void main() {
  final foods = {
    for (final f
        in (jsonDecode(File('assets/content/foods.json').readAsStringSync())
                as Map)['foods']
            as List)
      (f as Map)['id'] as String: f,
  };
  final doc = jsonDecode(
    File('docs/food-profiles/phase-independent-assessment.json')
        .readAsStringSync(),
  ) as Map;
  final rows = (doc['foods'] as List).cast<Map<String, Object?>>();

  test('it covers exactly the phase-assigned foods and changes none', () {
    final assigned = {
      for (final MapEntry(key: id, value: f) in foods.entries)
        if ((f['why'] as Map).isNotEmpty) id: (f['why'] as Map).keys.single,
    };
    expect({for (final r in rows) r['id']: r['existingPhase']}, assigned);
    for (final r in rows) {
      expect(r['proposedPhaseChange'], isNull, reason: '${r['id']}');
      expect(
        r['scientificallySupportedAsPhaseSpecific'],
        isFalse,
        reason: '${r['id']}: no reliable phase-specific research was found',
      );
      expect(r['phaseDependentResearch'], 'none identified');
    }
  });

  test('every food has a rationale class, sources and limitations', () {
    for (final r in rows) {
      expect(
        (r['proposedIndependentClassification']! as String),
        matches(RegExp(r'^R[123] ')),
        reason: '${r['id']}',
      );
      expect((r['sources']! as List), isNotEmpty);
      expect((r['limitations']! as String).trim(), isNotEmpty);
    }
  });

  test(
    'the methodology names its evidence and promises no hormonal claims',
    () {
      final text = File('docs/food-profiles/independent-phase-methodology.md')
          .readAsStringSync();
      for (final pmid in [
        '39008822',
        '17684511',
        '9731851',
        '26177393',
        '41018334',
        '8077314',
      ]) {
        expect(text, contains(pmid));
      }
      expect(text, contains('CD002124'));
      expect(text, contains('Nothing here changes the app'));
      // Public documents must not name another publisher's framework.
      expect(text.toLowerCase(), isNot(contains('vitti')));
    },
  );
}
