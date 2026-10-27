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

  test('Foods intro copy: two points per phase, no exclusivity wording', () {
    for (final phase in Phase.values) {
      final c = foodsIntroCopy(phase);
      for (final text in [c.need, c.how]) {
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

  test('Your focus: the final 12 lines, with no health claims', () {
    final lines = {
      for (final phase in Phase.values)
        phase: [
          for (final p in phaseFocusCompact(phase)) '${p.title} | ${p.line}',
        ],
    };
    expect(lines, {
      Phase.menstrual: [
        'Iron + vitamin C | Pair iron-rich foods with vitamin C.',
        'Warm, nourishing meals | Choose comforting, substantial foods.',
        'Gentle cooking | Think soups, stews, porridge and warm bowls.',
      ],
      Phase.follicular: [
        'Fresh variety | Build meals from a colourful mix of whole foods.',
        'Light and balanced | Keep meals fresh, simple and satisfying.',
        'Quick preparation | Think bowls, salads, steaming and quick sautés.',
      ],
      Phase.ovulatory: [
        'Fresh and hydrating | Choose juicy fruit and crisp vegetables.',
        'Bright, balanced meals | Keep combinations colourful and simple.',
        'Light preparation | Think salads, chilled dishes and quick cooking.',
      ],
      Phase.luteal: [
        'Protein + fibre | Build satisfying meals.',
        'Slower carbohydrates | Choose substantial whole-food bases.',
        'Warm and grounding | Think roasts, bakes, bowls and one-pot meals.',
      ],
    });
    final banned = RegExp(
      'hormon|fertil|detox|treat|cure|symptom|cramp|pms|boost',
      caseSensitive: false,
    );
    for (final text in lines.values.expand((l) => l)) {
      expect(banned.hasMatch(text), isFalse, reason: text);
    }
  });
}
