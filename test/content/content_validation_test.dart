import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';

import '../helpers/test_catalogue.dart';

/// Checks the bundled content (`assets/content/`) against the approved
/// handoff (`design/content/`), which stays read-only.
Map<String, Object?> handoff(String path) =>
    jsonDecode(File('design/content/$path').readAsStringSync())
        as Map<String, Object?>;

List<Map<String, Object?>> list(Object? json) => [
  for (final e in json! as List<Object?>) e! as Map<String, Object?>,
];

void main() {
  final foodsFile = list(readContentFile('foods')['foods']);
  final phasesFile = list(readContentFile('phases')['phases']);
  final recipesFile = list(readContentFile('recipes')['recipes']);
  final audit = handoff('ingredients.json');
  final sample = handoff('sample-content.json');
  final recovered = handoff('recovered/emergent-recipes.json');
  final nameOf = {for (final f in foodsFile) f['id']: f['name']};
  const notShipReady = {'hijiki', 'salt', 'alcohol', 'ketchup'};

  test('157 foods, 4 phases and 12 recipes; ids are unique', () {
    expect(foodsFile, hasLength(157));
    expect(phasesFile, hasLength(4));
    expect(recipesFile, hasLength(12));
    expect(nameOf.keys.toSet(), hasLength(157));
    expect(recipesFile.map((r) => r['id']).toSet(), hasLength(12));
  });

  test('the catalogue loads; not-ship-ready foods are absent everywhere', () {
    final c = testCatalogue;
    expect(c.foods, hasLength(153));
    for (final id in notShipReady) {
      expect(c.food(id), isNull, reason: id);
      for (final phase in Phase.values) {
        expect(c.phase(phase).foodIds, isNot(contains(id)), reason: id);
      }
    }
    expect(c.recipes, hasLength(12));
  });

  test('placement matches the Emergent export exactly, in order', () {
    for (final (i, p) in list(sample['phases']).indexed) {
      final ours = phasesFile[i];
      expect(ours['id'], p['phase']);
      final theirs = [
        for (final c in list(p['categories'])) [c['name'], c['foods']],
      ];
      final taxonomy = {
        for (final c in list(readContentFile('taxonomy')['categories']))
          c['id']: c['name'],
      };
      final mine = [
        for (final c in list(ours['categories']))
          [
            taxonomy[c['category']],
            [for (final id in c['foods']! as List<Object?>) nameOf[id]],
          ],
      ];
      expect(mine, theirs, reason: p['phase'] as String);
    }
  });

  test('phase copy is verbatim', () {
    final auditPhases = audit['phases']! as Map<String, Object?>;
    for (final p in phasesFile) {
      final a = auditPhases[p['id']]! as Map<String, Object?>;
      for (final key in ['season', 'tagline', 'focus', 'cooking']) {
        expect(p[key], a[key], reason: '${p['id']} $key');
      }
      // Summary + focus body are the focus copy split after its first
      // sentence.
      expect('${p['summary']} ${p['focusBody']}', a['focus']);
    }
  });

  test('food copy, cautions and ship status are verbatim', () {
    for (final (i, a) in list(audit['ingredients']).indexed) {
      final f = foodsFile[i];
      expect(f['id'], a['id']);
      expect(f['name'], a['name']);
      expect(f['shipReady'], a['shipReady']);
      expect(f['cautions'], a['cautions']);
      final why = (a['phaseWhy']! as Map<String, Object?>)
        ..removeWhere((_, v) => v == null);
      expect(f['why'], why, reason: a['id'] as String);
    }
  });

  test('every shippable food has copy for each phase it is placed in', () {
    final c = testCatalogue;
    for (final phase in Phase.values) {
      for (final food in c.foodsFor(phase)) {
        expect(food.why[phase], isNotNull, reason: '${food.id} $phase');
      }
    }
  });

  test('recipes are verbatim, in the export order', () {
    final byId = {for (final r in list(recovered['recipes'])) r['id']: r};
    final order = [for (final r in list(sample['recipes'])) r['name']];
    expect([for (final r in recipesFile) r['title']], order);
    for (final r in recipesFile) {
      final source = byId[r['id']]!;
      expect(r['title'], source['title']);
      expect(r['phase'], source['phase']);
      expect(r['category'], source['storedCategory']);
      expect(r['minutes'], source['minutes']);
      expect(r['serves'], source['servings']);
      expect(r['intro'], source['description']);
      expect(r['steps'], source['steps']);
      final lines = list(source['ingredients']);
      final ours = list(r['ingredients']);
      expect(ours, hasLength(lines.length));
      for (final (i, line) in lines.indexed) {
        expect(ours[i]['label'], line['label']);
        expect(ours[i]['food'], line['foodId']);
        expect(ours[i]['amount'], line['amount']);
      }
      final tags = [
        for (final t in source['tags']! as List<Object?>)
          nameOf.entries.firstWhere((e) => e.value == t).key,
      ];
      expect(r['keyFoods'], tags);
    }
  });

  test(
    'every phase has three recipes; the stored order puts its feature first',
    () {
      for (final phase in Phase.values) {
        expect(testCatalogue.recipesFor(phase), hasLength(3), reason: '$phase');
      }
      expect(
        testCatalogue.recipesFor(Phase.follicular).first.id,
        'zesty-lentil-broccoli-bowl',
      );
    },
  );
}
