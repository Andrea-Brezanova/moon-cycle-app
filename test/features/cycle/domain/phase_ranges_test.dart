import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_rules.dart';
import 'package:moon_cycle/features/cycle/domain/phase_ranges.dart';

CycleLengths lengths(int cycle, int period, int luteal) => CycleLengths(
  cycleLength: cycle,
  periodLength: period,
  lutealLength: luteal,
  source: LengthsSource.typical,
);

List<List<int>> asPairs(PhaseRanges r) =>
    r.all.map((x) => [x.firstDay, x.lastDay]).toList();

void main() {
  test(
    '28-day cycle, 5-day period, default luteal: 1–5, 6–11, 12–15, 16–28',
    () {
      expect(asPairs(phaseRangesFor(lengths(28, 5, 14))), [
        [1, 5],
        [6, 11],
        [12, 15],
        [16, 28],
      ]);
    },
  );

  group('parity with the approved reference (design/code/cycle.ts)', () {
    // Proves the Dart port matches the reference algorithm exactly. It does
    // not validate the medical assumptions of that algorithm.
    final fixture = jsonDecode(
      File('test/fixtures/cycle_ts_phase_ranges.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final cases = (fixture['cases']! as List<Object?>)
        .cast<Map<String, Object?>>();

    test('fixture was generated from the current reference file', () {
      final result = Process.runSync('git', [
        'hash-object',
        'design/code/cycle.ts',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(
        (result.stdout as String).trim(),
        fixture['sourceGitBlob'],
        reason: 'design/code/cycle.ts changed after the fixture was made',
      );
    });

    test('fixture covers every valid combination', () {
      const expected =
          (CycleRules.maxCycleLength - CycleRules.minCycleLength + 1) *
          (CycleRules.maxPeriodLength - CycleRules.minPeriodLength + 1) *
          (CycleRules.maxLutealLength - CycleRules.minLutealLength + 1);
      expect(expected, 1575);
      expect(cases, hasLength(expected));
    });

    test('Dart ranges equal cycle.ts for all 1,575 combinations', () {
      for (final c in cases) {
        final input = lengths(
          c['cycle']! as int,
          c['period']! as int,
          c['luteal']! as int,
        );
        final expected = (c['ranges']! as List<Object?>)
            .map((p) => (p! as List<Object?>).cast<int>())
            .toList();
        expect(
          asPairs(phaseRangesFor(input)),
          expected,
          reason:
              'cycle ${c['cycle']}, period ${c['period']}, '
              'luteal ${c['luteal']}',
        );
      }
    });
  });

  test('invariants hold for every valid combination', () {
    for (var cycle = 21; cycle <= 45; cycle++) {
      for (var period = 2; period <= 10; period++) {
        for (var luteal = 10; luteal <= 16; luteal++) {
          final r = phaseRangesFor(lengths(cycle, period, luteal));
          final why = '$cycle/$period/$luteal: ${r.all}';
          expect(r.all.map((x) => x.phase), Phase.values, reason: why);
          expect(r.all.first.firstDay, 1, reason: why);
          expect(r.cycleLength, cycle, reason: why);
          for (var i = 1; i < 4; i++) {
            expect(r.all[i].firstDay, r.all[i - 1].lastDay + 1, reason: why);
          }
          for (final x in r.all) {
            expect(x.length, greaterThanOrEqualTo(1), reason: why);
          }
          expect(r.of(Phase.menstrual).length, period, reason: why);
          expect(
            r.of(Phase.ovulatory).length,
            lessThanOrEqualTo(4),
            reason: why,
          );
        }
      }
    }
  });

  group('edge combinations', () {
    test(
      'short cycle, long period, short luteal: luteal absorbs the squeeze',
      () {
        expect(asPairs(phaseRangesFor(lengths(21, 10, 10))), [
          [1, 10],
          [11, 11], // follicular keeps its 1-day minimum
          [12, 15],
          [16, 21],
        ]);
      },
    );

    test('short cycle, short period, long luteal', () {
      expect(asPairs(phaseRangesFor(lengths(21, 2, 16))), [
        [1, 2],
        [3, 3],
        [4, 7],
        [8, 21],
      ]);
    });

    test('long cycles', () {
      expect(asPairs(phaseRangesFor(lengths(45, 2, 10))), [
        [1, 2],
        [3, 32],
        [33, 36],
        [37, 45],
      ]);
      expect(asPairs(phaseRangesFor(lengths(45, 10, 16))), [
        [1, 10],
        [11, 26],
        [27, 30],
        [31, 45],
      ]);
    });

    test(
      'the displayed luteal phase is luteal length − 1 in the usual case',
      () {
        expect(phaseRangesFor(lengths(28, 5, 14)).of(Phase.luteal).length, 13);
        expect(phaseRangesFor(lengths(35, 5, 12)).of(Phase.luteal).length, 11);
      },
    );
  });

  group('PhaseRanges and PhaseRange', () {
    final r = phaseRangesFor(lengths(28, 5, 14));

    test('forDay finds the containing range', () {
      expect(r.forDay(1).phase, Phase.menstrual);
      expect(r.forDay(5).phase, Phase.menstrual);
      expect(r.forDay(6).phase, Phase.follicular);
      expect(r.forDay(15).phase, Phase.ovulatory);
      expect(r.forDay(16).phase, Phase.luteal);
      expect(r.forDay(28).phase, Phase.luteal);
    });

    test('forDay rejects days outside the cycle', () {
      expect(() => r.forDay(0), throwsRangeError);
      expect(() => r.forDay(29), throwsRangeError);
    });

    test('the list cannot be modified', () {
      expect(() => r.all.add(r.all.first), throwsUnsupportedError);
    });

    test('value behaviour', () {
      const a = PhaseRange(Phase.follicular, 6, 11);
      expect(a, const PhaseRange(Phase.follicular, 6, 11));
      expect(a.hashCode, const PhaseRange(Phase.follicular, 6, 11).hashCode);
      expect(a == const PhaseRange(Phase.follicular, 6, 12), isFalse);
      expect(a.length, 6);
      expect(a.contains(6) && a.contains(11), isTrue);
      expect(a.contains(5) || a.contains(12), isFalse);
      expect(a.toString(), 'follicular 6–11');
    });
  });
}
