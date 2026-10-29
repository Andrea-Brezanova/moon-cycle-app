import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The provenance matrix (docs/food-profiles/phase-assignment-provenance-matrix.json)
/// is a record of where each food-to-phase assignment came from. It must describe
/// the catalogue as it is: if an assignment changes, the matrix has to be rebuilt
/// with phase_provenance_audit.py. The matrix never changes the catalogue.
void main() {
  final matrix =
      ((jsonDecode(
                File(
                  'docs/food-profiles/phase-assignment-provenance-matrix.json',
                ).readAsStringSync(),
              ) as Map)['foods']
              as List)
          .cast<Map<String, Object?>>();
  final catalogue = {
    for (final f
        in (jsonDecode(File('assets/content/foods.json').readAsStringSync())
                as Map)['foods']
            as List)
      (f as Map)['id'] as String: f,
  };

  test(
    'the matrix covers exactly the phase-assigned foods, in their phase',
    () {
      final assigned = {
        for (final MapEntry(key: id, value: f) in catalogue.entries)
          if ((f['why'] as Map).isNotEmpty)
            id: (f['why'] as Map).keys.single as String,
      };
      expect(matrix, hasLength(142));
      expect({
        for (final m in matrix) m['id'] as String: m['currentPhase'],
      }, assigned);
    },
  );

  test(
    'every food has a category A to E, a first commit and no unearned claims',
    () {
      for (final m in matrix) {
        final id = m['id'];
        expect(
          ['A', 'B', 'C', 'D', 'E'],
          contains(m['classification']),
          reason: '$id',
        );
        expect(
          (m['firstIdentifiableCommit']! as Map)['commit'],
          isNotEmpty,
          reason: '$id',
        );
        expect(m['documentedOriginalSource'], isNotEmpty, reason: '$id');
        expect(m['furtherReviewRequired'], isTrue, reason: '$id');
        // No placement is documented as independently justified, and USDA
        // composition is never treated as phase-specific evidence.
        expect(m['independentlyJustified'], 'no', reason: '$id');
        final support = m['scientificSupport']! as Map;
        expect(
          support['phaseSpecificRequirementEvidence'],
          'none identified',
          reason: '$id',
        );
        expect(
          support['noReliablePhaseSpecificEvidence'],
          isTrue,
          reason: '$id',
        );
      }
      expect(
        matrix.where(
          (m) => m['classification'] == 'A' || m['classification'] == 'C',
        ),
        isEmpty,
        reason: 'A and C need documentary evidence that was not found',
      );
    },
  );

  test('the report numbers match the matrix', () {
    final summary = jsonDecode(
      File('docs/food-profiles/phase-assignment-provenance-summary.json')
          .readAsStringSync(),
    ) as Map;
    final counts = <String, int>{};
    for (final m in matrix) {
      counts.update(
        m['classification']! as String,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    expect(
      (summary['classificationCounts']! as Map).cast<String, int>()
        ..removeWhere((k, v) => v == 0),
      counts,
    );
    expect(
      File('docs/food-profiles/phase-assignment-provenance-audit.md')
          .existsSync(),
      isTrue,
    );
  });
}
