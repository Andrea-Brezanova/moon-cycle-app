import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/domain/phase_guidance.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  test('three principles per phase, none of them an individual food', () {
    final names = {
      for (final f in testCatalogue.foods) f.displayName.toLowerCase(),
    }..removeAll({'oat', 'oats'});
    for (final phase in Phase.values) {
      final principles = phaseFocusPrinciples(phase);
      expect(principles, hasLength(3));
      for (final line in principles) {
        for (final name in names) {
          expect(
            RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(line.toLowerCase()),
            isFalse,
            reason: '"$line" names $name',
          );
        }
      }
    }
  });

  test('descriptions are short and never promise a mood or energy level', () {
    for (final phase in Phase.values) {
      final text = phaseDescription(phase).toLowerCase();
      expect(text.length, lessThan(100));
      for (final word in ['energy', 'energised', 'mood', 'you will feel']) {
        expect(text, isNot(contains(word)), reason: phase.name);
      }
    }
  });

  test('ovulatory copy is about the days around ovulation', () {
    final text = phaseDescription(Phase.ovulatory);
    expect(text, contains('around estimated ovulation'));
    expect(text, isNot(contains('lasts')));
  });

  test('Foods intro copy: three points per phase, no exclusivity wording', () {
    for (final phase in Phase.values) {
      final c = foodsIntroCopy(phase);
      for (final text in [c.need, c.why, c.how]) {
        expect(text.trim(), isNotEmpty);
        expect(text.toLowerCase(), isNot(contains(' only ')));
        expect(text.toLowerCase(), isNot(contains('should')));
        for (final claim in [
          'detox',
          'hormon',
          'fertil',
          'ovulation',
          'cure',
        ]) {
          expect(text.toLowerCase(), isNot(contains(claim)), reason: text);
        }
      }
    }
    expect(foodsUniversalNote, contains('you can enjoy any food at any time'));
  });
}
