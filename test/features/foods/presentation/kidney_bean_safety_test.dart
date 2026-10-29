import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';

import '../../../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../../../helpers/golden_screen.dart';
import '../../../helpers/test_catalogue.dart';

/// Dried red kidney beans are toxic if raw or undercooked. The FDA says to soak
/// for at least 5 hours and boil in fresh water for at least 30 minutes (not
/// 10), and not to use a slow cooker; canned beans are already cooked. This
/// guards the wording everywhere it can be shown.
void main() {
  const oldWording = 'boil hard for 10 minutes';

  test('the catalogue gives the FDA instructions for dried beans', () {
    final text = testCatalogue.food('kidney-bean')!.cautions.join('\n');
    expect(text, contains('at least 5 hours'));
    expect(text, contains('fresh water for at least 30 minutes'));
    expect(text, contains('slow cooker'));
    expect(text, isNot(contains('10 minutes')));
  });

  test('canned beans are distinguished from dried beans', () {
    final cautions = testCatalogue.food('kidney-bean')!.cautions;
    final dried = cautions.where((c) => c.startsWith('Dried kidney beans'));
    final canned = cautions.where((c) => c.startsWith('Canned kidney beans'));
    expect(dried, hasLength(1));
    expect(canned, hasLength(1));
    expect(canned.single, contains('already cooked'));
    // The cooking times belong to the dried-bean instruction only.
    expect(canned.single, isNot(contains('minutes')));
    expect(canned.single, isNot(contains('hours')));
  });

  test('no content file or draft profile still carries the old wording', () {
    final files = [
      ...Directory('assets/content')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json')),
      ...Directory('docs/food-profiles').listSync().whereType<File>().where(
        (f) => RegExp(
          r'(draft-batch-\d+|wave-1-candidate|complete-draft-dataset)\.json$',
        ).hasMatch(f.path),
      ),
    ];
    expect(files, isNotEmpty);
    for (final f in files) {
      expect(
        f.readAsStringSync().toLowerCase(),
        isNot(contains(oldWording)),
        reason: '${f.path} still has the outdated kidney bean instruction',
      );
    }
  });

  test(
    'the draft profile carries the same corrected sentences as the catalogue',
    () {
      final catalogue = testCatalogue.food('kidney-bean')!.cautions;
      final draft =
          ((jsonDecode(
                    File('docs/food-profiles/complete-draft-dataset.json')
                        .readAsStringSync(),
                  ) as Map<String, Object?>)['profiles']!
                  as Map<String, Object?>)['kidney-bean']!
              as Map<String, Object?>;
      final texts = (draft['cautions']! as List)
          .map((c) => (c as Map<String, Object?>)['text'])
          .toList();
      for (final c in catalogue) {
        expect(
          texts,
          contains(c),
          reason: 'draft profile out of step with the catalogue',
        );
      }
    },
  );

  testWidgets('Food Detail shows the corrected warning, dried and canned', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const FoodDetailPage(
        foodId: 'kidney-bean',
        phase: Phase.menstrual,
        general: false,
      ),
      dark: false,
      width: 390,
      height: 2000,
      overrides: [cycleStateProvider.overrideWithValue(stateOnDay(7))],
    );
    final note = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('food-cautions')),
        matching: find.byType(Text),
      ),
    );
    final shown = note.textSpan!.toPlainText();
    expect(shown, contains('at least 5 hours'));
    expect(shown, contains('at least 30 minutes'));
    expect(shown, contains('slow cooker'));
    expect(shown, contains('Canned kidney beans are already cooked'));
    expect(shown, isNot(contains('10 minutes')));
  });
}
