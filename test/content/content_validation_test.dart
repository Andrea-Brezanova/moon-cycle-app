import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../helpers/test_catalogue.dart';

/// Checks the bundled content (`assets/content/`) against the Foods v2
/// content contract: each highlighted food is featured in exactly one phase
/// (35 / 32 / 31 / 44 = 142), phase-specific copy for that phase only, a
/// universal note, valid taxonomy references, conditional allergens, and no
/// internal rationale labels in anything a user can see.
///
/// The legacy handoff (`design/content/`) stays read-only and is used only to
/// prove that permanent ids were never dropped.
List<Map<String, Object?>> list(Object? json) => [
  for (final e in json! as List<Object?>) e! as Map<String, Object?>,
];

List<String> strings(Object? json) => [
  for (final e in (json as List<Object?>? ?? const [])) e! as String,
];

void main() {
  final foodsFile = list(readContentFile('foods')['foods']);
  final phasesFile = list(readContentFile('phases')['phases']);
  final recipesFile = list(readContentFile('recipes')['recipes']);
  final taxonomy = readContentFile('taxonomy');
  final foodById = {for (final f in foodsFile) f['id']! as String: f};
  final categoryIds = {for (final c in list(taxonomy['categories'])) c['id']};
  final aisleIds = {for (final a in list(taxonomy['aisles'])) a['id']};
  final allergenIds = {for (final a in list(taxonomy['allergens'])) a['id']};

  const universalNote =
      'These are suggestions, not rules. We feature different foods across '
      'your cycle to encourage variety — you can enjoy any food at any time.';
  const internalLabels = [
    'editorial',
    'supporting',
    'evidence_informed',
    'framework_informed',
    'evidenceInformed',
    'frameworkInformed',
  ];

  const phaseSizes = {
    'menstrual': 35,
    'follicular': 32,
    'ovulatory': 31,
    'luteal': 44,
  };

  test('four phases and 112 recipes; food ids are unique', () {
    expect(phasesFile, hasLength(4));
    expect(recipesFile, hasLength(112));
    expect(foodById, hasLength(foodsFile.length));
    expect(recipesFile.map((r) => r['id']).toSet(), hasLength(112));
    expect(phasesFile.map((p) => p['id']), [
      'menstrual',
      'follicular',
      'ovulatory',
      'luteal',
    ]);
  });

  test('every id from the original catalogue is still present', () {
    // Shopping items and avoidances store food ids; they must keep resolving.
    final handoff = jsonDecode(
      File('design/content/ingredients.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final original = [
      for (final i in list(handoff['ingredients'])) i['id']! as String,
    ];
    expect(original, isNotEmpty);
    expect(foodById.keys, containsAll(original));
  });

  test('the catalogue loads and holds exactly the ship-ready foods', () {
    final shipReady = foodsFile.where((f) => f['shipReady'] == true);
    final categoryIds = {for (final c in list(taxonomy['categories'])) c['id']};
    for (final f in foodsFile) {
      expect(categoryIds, contains(f['category']), reason: f['id']! as String);
    }
    expect(testCatalogue.foods, hasLength(shipReady.length));
    for (final f in foodsFile.where((f) => f['shipReady'] != true)) {
      expect(testCatalogue.food(f['id']! as String), isNull, reason: '$f');
    }
  });

  group('phases', () {
    for (final p in phasesFile) {
      final id = p['id']! as String;
      final phase = Phase.values.byName(id);

      test('$id: the frozen number of distinct highlighted foods', () {
        final ids = [
          for (final c in list(p['categories'])) ...strings(c['foods']),
        ];
        expect(ids, hasLength(phaseSizes[id]));
        expect(ids.toSet(), hasLength(phaseSizes[id]));
        expect(testCatalogue.foodsFor(phase), hasLength(phaseSizes[id]));
      });

      test('$id: every food exists, is ship-ready and has its why copy', () {
        for (final c in list(p['categories'])) {
          for (final foodId in strings(c['foods'])) {
            final food = foodById[foodId];
            expect(food, isNotNull, reason: '$id/$foodId does not exist');
            expect(food!['shipReady'], isTrue, reason: '$id/$foodId');
            final whys = food['why']! as Map<String, Object?>;
            // Exactly one "why": for the single featured phase.
            expect(whys.keys, [id], reason: '$id/$foodId');
            final why = whys[id];
            final w = why! as Map<String, Object?>;
            expect((w['short']! as String).trim(), isNotEmpty);
            expect((w['detail']! as String).trim(), isNotEmpty);
          }
        }
      });

      test('$id: has the universal note and intro copy', () {
        expect(p['note'], universalNote);
        for (final key in ['season', 'tagline', 'summary', 'focusBody']) {
          expect((p[key]! as String).trim(), isNotEmpty, reason: key);
        }
        expect(p['cooking'], isNotEmpty);
        expect('${p['summary']} ${p['focusBody']}', p['focus']);
        expect(testCatalogue.phase(phase).note, universalNote);
      });

      test('$id: categories exist in the taxonomy, in taxonomy order', () {
        final used = [for (final c in list(p['categories'])) c['category']];
        expect(used.toSet(), hasLength(used.length));
        for (final c in used) {
          expect(categoryIds, contains(c), reason: '$id: $c');
        }
        final order = categoryIds.toList();
        final positions = [for (final c in used) order.indexOf(c)];
        expect(positions, orderedEquals([...positions]..sort()));
      });

      test('$id: no hidden or removed food is highlighted', () {
        final highlighted = {
          for (final c in list(p['categories'])) ...strings(c['foods']),
        };
        final hidden = {
          for (final f in foodsFile)
            if (f['shipReady'] != true) f['id']! as String,
        };
        expect(highlighted.intersection(hidden), isEmpty);
      });
    }
  });

  test('142 unique highlighted foods, each featured in exactly one phase', () {
    final placements = [
      for (final p in phasesFile)
        for (final c in list(p['categories'])) ...strings(c['foods']),
    ];
    expect(placements, hasLength(142));
    expect(placements.toSet(), hasLength(142));
    expect(phaseSizes.values.reduce((a, b) => a + b), 142);
    // Only highlighted foods carry "why" copy.
    for (final f in foodsFile) {
      final id = f['id']! as String;
      final why = f['why']! as Map<String, Object?>;
      expect(why.isEmpty, !placements.contains(id), reason: id);
    }
  });

  test('searchable foods outside every phase list stay in the catalogue', () {
    final highlighted = {
      for (final p in Phase.values) ...testCatalogue.phase(p).foodIds,
    };
    final general = [
      for (final f in testCatalogue.foods)
        if (!highlighted.contains(f.id)) f,
    ];
    expect(general, isNotEmpty);
    expect(testCatalogue.foods.length, highlighted.length + general.length);
  });

  test('recipes: every food id still resolves to a ship-ready food', () {
    for (final r in recipesFile) {
      final ids = <String>{
        ...strings(r['keyFoods']),
        for (final line in list(r['ingredients']))
          if (line['food'] != null) line['food']! as String,
      };
      for (final id in ids) {
        expect(foodById[id], isNotNull, reason: '${r['id']} uses $id');
        expect(foodById[id]!['shipReady'], isTrue, reason: '${r['id']}: $id');
      }
    }
    expect(testCatalogue.recipes, hasLength(112));
  });

  group('Recipes v2 contract', () {
    const legacyIds = {
      'miso-mushroom-kale-soup',
      'beet-adzuki-wild-rice-bowl',
      'blueberry-buckwheat-porridge',
      'zesty-lentil-broccoli-bowl',
      'citrus-oat-breakfast-bowl',
      'lemon-herb-chicken-artichoke',
      'quinoa-salmon-bowl',
      'berry-coconut-amaranth',
      'red-lentil-spinach-dal',
      'sweet-potato-chickpea-tray',
      'ginger-pumpkin-soup',
      'baked-apple-pear-millet',
    };

    test('27 / 29 / 26 / 30 per phase, no legacy ids', () {
      const perPhase = {
        'menstrual': 27,
        'follicular': 29,
        'ovulatory': 26,
        'luteal': 30,
      };
      for (final MapEntry(key: phase, value: n) in perPhase.entries) {
        expect(
          recipesFile.where((r) => r['phase'] == phase),
          hasLength(n),
          reason: phase,
        );
      }
      expect(
        recipesFile.map((r) => r['id']).toSet().intersection(legacyIds),
        isEmpty,
      );
    });

    test('every recipe has why-this-phase, 3-5 steps and total minutes', () {
      for (final r in recipesFile) {
        final id = r['id']! as String;
        expect(
          (r['whyThisPhase'] as String?)?.trim(),
          isNotEmpty,
          reason: '$id whyThisPhase',
        );
        expect(
          RegExp(r'[.!?](\s|$)').allMatches(r['whyThisPhase']! as String),
          hasLength(1),
          reason: '$id is one sentence',
        );
        expect(strings(r['steps']).length, inInclusiveRange(3, 5), reason: id);
        expect(r['minutes'], isA<int>(), reason: id);
        expect(r['minutes']! as int, greaterThan(0), reason: id);
      }
    });

    test('lines have a food or an aisle, and metric is display-only', () {
      for (final r in recipesFile) {
        for (final line in list(r['ingredients'])) {
          expect(line['amount'], isNotNull, reason: '${r['id']} amount');
          expect(line['unit'], isNotNull, reason: '${r['id']} unit');
          if (line['food'] == null) {
            expect(
              aisleIds,
              contains(line['aisle']),
              reason: r['id']! as String,
            );
          }
          if (line['metric'] != null) {
            expect(line['metric'], isA<String>());
          }
        }
      }
    });

    test('every catalogue food links to the recipes that use it', () {
      final usedBy = <String, int>{};
      for (final r in testCatalogue.recipes) {
        for (final id in r.keyFoodIds.toSet()) {
          usedBy[id] = (usedBy[id] ?? 0) + 1;
        }
      }
      expect(usedBy, isNotEmpty);
      for (final id in usedBy.keys) {
        expect(testCatalogue.food(id), isNotNull, reason: id);
      }
    });

    test('no gluten-free-looking stock hides a generic stock line', () {
      for (final r in testCatalogue.recipes) {
        final stock = r.ingredients.where(
          (l) => l.label.toLowerCase().contains('stock'),
        );
        for (final l in stock) {
          expect(l.extraAllergenIds, isEmpty, reason: r.id);
        }
      }
    });
  });

  test('allergen, aisle and diet metadata is valid', () {
    const animalSources = {'none', 'dairy', 'egg', 'seafood', 'meat', 'honey'};
    for (final f in foodsFile) {
      final id = f['id'];
      expect(aisleIds, contains(f['aisle']), reason: '$id aisle');
      expect(animalSources, contains(f['animalSource']), reason: '$id');
      for (final a in strings(f['allergens'])) {
        expect(allergenIds, contains(a), reason: '$id allergen $a');
      }
      for (final a in strings(f['mayContainAllergens'])) {
        expect(allergenIds, contains(a), reason: '$id may contain $a');
      }
      // A conditional allergen is never also a permanent one.
      expect(
        strings(f['allergens'])
            .toSet()
            .intersection(strings(f['mayContainAllergens']).toSet()),
        isEmpty,
        reason: '$id',
      );
    }
  });

  group('conditional allergens keep avoidance filtering safe', () {
    FoodFilter avoids(String allergenId) => FoodFilter(
      avoidances: [AllergenAvoidance(id: 'a', allergenId: allergenId)],
    );

    test('oats and oat bran are not a gluten allergen, but gluten-avoiders '
        'still do not see them', () {
      for (final id in ['oat', 'oat-bran']) {
        final food = testCatalogue.food(id)!;
        expect(food.allergenIds, isNot(contains('gluten')), reason: id);
        expect(food.mayContainAllergenIds, contains('gluten'), reason: id);
        expect(avoids('gluten').allowsFood(food), isFalse, reason: id);
        expect(
          food.cautions,
          contains('Choose certified gluten-free oats if avoiding gluten.'),
        );
      }
      // Wheat foods are still definite gluten.
      expect(
        testCatalogue.food('whole-grain-bread')!.allergenIds,
        contains('gluten'),
      );
      // Someone avoiding something else still sees oats.
      expect(avoids('soy').allowsFood(testCatalogue.food('oat')!), isTrue);
    });

    test('kimchi has no permanent fish chip, keeps its cautions and is still '
        'left out for fish and shellfish avoiders', () {
      final kimchi = testCatalogue.food('kimchi')!;
      expect(kimchi.allergenIds, isEmpty);
      expect(kimchi.mayContainAllergenIds, {'fish', 'shellfish'});
      expect(avoids('fish').allowsFood(kimchi), isFalse);
      expect(avoids('shellfish').allowsFood(kimchi), isFalse);
      expect(avoids('dairy').allowsFood(kimchi), isTrue);
      expect(kimchi.cautions, hasLength(2));
      expect(kimchi.cautions.join(' '), contains('fish sauce or shrimp'));
      expect(kimchi.cautions.join(' '), contains('vegetarian or vegan'));
      expect(kimchi.cautions, contains('High in salt'));
    });

    test('recipes with oats are left out for gluten-avoiders', () {
      final withOats = testCatalogue.recipes.where(
        (r) => r.ingredients.any((l) => l.foodId == 'oat'),
      );
      for (final r in withOats) {
        expect(
          avoids('gluten').allowsRecipe(r, testCatalogue),
          isFalse,
          reason: r.id,
        );
      }
    });
  });

  test('approved safety cautions and allergens are kept', () {
    List<String> cautions(String id) => testCatalogue.food(id)!.cautions;
    expect(
      cautions('spinach'),
      contains(
        'Very high vitamin K: keep intake consistent if taking warfarin',
      ),
    );
    expect(
      cautions('kale'),
      contains(
        'Very high vitamin K: keep intake consistent if taking warfarin',
      ),
    );
    expect(cautions('clam'), contains('Cook thoroughly'));
    expect(cautions('mussel'), contains('Cook thoroughly'));
    expect(
      cautions('chia-seeds'),
      contains('Soak before eating: dry seeds swell when wet'),
    );
    expect(cautions('greek-yogurt'), contains('Dairy allergen'));
    expect(cautions('cottage-cheese'), contains('Dairy allergen'));
    expect(testCatalogue.food('greek-yogurt')!.allergenIds, {'dairy'});
    expect(testCatalogue.food('tofu')!.allergenIds, {'soy'});
    expect(testCatalogue.food('tempeh')!.allergenIds, {'soy'});
    // Kiwi: a plain caution, not a major-allergen chip.
    expect(testCatalogue.food('kiwi')!.allergenIds, isEmpty);
    expect(
      cautions('kiwi'),
      contains(
        'Kiwi can cause allergic reactions; people with latex allergy may '
        'also react.',
      ),
    );
  });

  test('user-visible content never exposes internal rationale labels', () {
    for (final name in ['foods', 'phases', 'taxonomy']) {
      final text = File('assets/content/$name.json').readAsStringSync();
      for (final label in internalLabels) {
        expect(text, isNot(contains(label)), reason: '$name.json: $label');
      }
    }
    final foodKeys = {for (final f in foodsFile) ...f.keys};
    expect(
      foodKeys.difference({
        'id',
        'name',
        'aisle',
        'category',
        'animalSource',
        'allergens',
        'mayContainAllergens',
        'synonyms',
        'shipReady',
        'cautions',
        'why',
      }),
      isEmpty,
    );
  });

  test('copy makes no medical, hormone or treatment claims', () {
    final banned = RegExp(
      r'hormon|estrogen|oestrogen|progesterone|detox|regulat|prevent|'
      r'\btreat|\bcure|\bfix\b|deficien|\bpms\b|cramp|scientific|proven|'
      r'science|clinical',
      caseSensitive: false,
    );
    final texts = <String>[
      for (final p in phasesFile)
        for (final k in ['tagline', 'summary', 'focusBody', 'cooking', 'note'])
          p[k]! as String,
      for (final f in foodsFile)
        for (final w in (f['why']! as Map<String, Object?>).values)
          for (final k in ['short', 'detail'])
            (w! as Map<String, Object?>)[k]! as String,
    ];
    for (final t in texts) {
      expect(banned.hasMatch(t), isFalse, reason: t);
    }
  });
}
