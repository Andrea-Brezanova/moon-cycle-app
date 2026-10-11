import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';

void main() {
  group('CycleLengths.fromProfile', () {
    test('uses the typical values and the default luteal length', () {
      final l = CycleLengths.fromProfile(
        const CycleProfile(typicalCycleLength: 30, typicalPeriodLength: 6),
      );
      expect(l.cycleLength, 30);
      expect(l.periodLength, 6);
      expect(l.lutealLength, 14);
      expect(l.source, LengthsSource.typical);
    });

    test('uses a custom luteal length', () {
      final l = CycleLengths.fromProfile(
        const CycleProfile(
          typicalCycleLength: 28,
          typicalPeriodLength: 5,
          lutealLength: 12,
        ),
      );
      expect(l.lutealLength, 12);
    });

    test('clamps out-of-range stored values instead of failing', () {
      final low = CycleLengths.fromProfile(
        const CycleProfile(
          typicalCycleLength: 14,
          typicalPeriodLength: 1,
          lutealLength: 5,
        ),
      );
      expect(
        [low.cycleLength, low.periodLength, low.lutealLength],
        [21, 2, 10],
      );

      final high = CycleLengths.fromProfile(
        const CycleProfile(
          typicalCycleLength: 60,
          typicalPeriodLength: 14,
          lutealLength: 20,
        ),
      );
      expect(
        [high.cycleLength, high.periodLength, high.lutealLength],
        [45, 10, 16],
      );
    });
  });

  group('CycleLengths constructor', () {
    test('accepts the limits', () {
      expect(
        () => CycleLengths(
          cycleLength: 21,
          periodLength: 10,
          lutealLength: 16,
          source: LengthsSource.historyAverage,
        ),
        returnsNormally,
      );
    });

    test('rejects values outside the limits', () {
      CycleLengths make({int c = 28, int p = 5, int l = 14}) => CycleLengths(
        cycleLength: c,
        periodLength: p,
        lutealLength: l,
        source: LengthsSource.typical,
      );
      expect(() => make(c: 20), throwsArgumentError);
      expect(() => make(c: 46), throwsArgumentError);
      expect(() => make(p: 1), throwsArgumentError);
      expect(() => make(p: 11), throwsArgumentError);
      expect(() => make(l: 9), throwsArgumentError);
      expect(() => make(l: 17), throwsArgumentError);
    });

    test('value behaviour', () {
      CycleLengths make(LengthsSource s) => CycleLengths(
        cycleLength: 28,
        periodLength: 5,
        lutealLength: 14,
        source: s,
      );
      expect(make(LengthsSource.typical), make(LengthsSource.typical));
      expect(
        make(LengthsSource.typical).hashCode,
        make(LengthsSource.typical).hashCode,
      );
      expect(
        make(LengthsSource.typical) == make(LengthsSource.historyAverage),
        isFalse,
      );
    });
  });

  test('CycleProfile value behaviour', () {
    const a = CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5);
    expect(
      a,
      const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
    );
    expect(
      a.hashCode,
      const CycleProfile(
        typicalCycleLength: 28,
        typicalPeriodLength: 5,
      ).hashCode,
    );
    expect(
      a ==
          const CycleProfile(
            typicalCycleLength: 28,
            typicalPeriodLength: 5,
            lutealLength: 14,
          ),
      isFalse,
    );
    // Built at runtime (as when loaded from storage), equal to the const one.
    for (final stored in [28]) {
      expect(
        CycleProfile(typicalCycleLength: stored, typicalPeriodLength: 5),
        a,
      );
    }
  });
}
