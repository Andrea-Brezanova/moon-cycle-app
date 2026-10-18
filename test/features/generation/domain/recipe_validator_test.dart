import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/generation/domain/generated_recipe.dart';
import 'package:moon_cycle/features/generation/domain/generation_request.dart';
import 'package:moon_cycle/features/generation/domain/recipe_validator.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';

/// The shared validator fixtures: the backend runs the same file.
final _cases = (jsonDecode(
  File('test/fixtures/generation/validator_cases.json').readAsStringSync(),
) as List<Object?>).cast<Map<String, Object?>>();

GenerationRequest _request(Map<String, Object?> j) {
  final phase = Phase.values.byName(j['phase']! as String);
  if (j['kind'] == 'try_new') {
    return GenerationRequest.tryNew(
      idempotencyKey: j['idempotency_key']! as String,
      phase: phase,
      foodIds: (j['food_ids']! as List<Object?>).cast<String>(),
      variant: j['variant']! as int,
    );
  }
  return GenerationRequest(
    idempotencyKey: j['idempotency_key']! as String,
    phase: phase,
    proteinId: j['protein_id']! as String,
    baseId: j['base_id']! as String,
    plantIds: (j['plant_ids']! as List<Object?>).cast<String>(),
  );
}

FoodFilter _filter(Map<String, Object?> j) => FoodFilter(
  diet: Diet.values.byName(j['diet']! as String),
  avoidances: [
    for (final a in (j['allergens']! as List<Object?>).cast<String>())
      AllergenAvoidance(id: 'a-$a', allergenId: a),
  ],
);

void main() {
  for (final c in _cases) {
    test('fixture: ${c['name']}', () {
      final recipe = GeneratedRecipe.fromJson(
        c['recipe']! as Map<String, Object?>,
      );
      final report = RecipeValidator(testCatalogue).validate(
        recipe,
        _request(c['request']! as Map<String, Object?>),
        _filter(c['filter']! as Map<String, Object?>),
      );
      final codes = {for (final i in report.issues) i.code.name};
      expect(
        codes,
        (c['expect']! as List<Object?>).cast<String>().toSet(),
        reason: report.toString(),
      );
    });
  }

  group('parsing', () {
    Map<String, Object?> good() =>
        Map.of(_cases.first['recipe']! as Map<String, Object?>);

    test('round-trips', () {
      final r = GeneratedRecipe.fromJson(good());
      expect(GeneratedRecipe.fromJson(r.toJson()).toJson(), r.toJson());
    });

    test('rejects the wrong schema version, category and shapes', () {
      expect(
        () => GeneratedRecipe.fromJson({...good(), 'schema_version': 2}),
        throwsFormatException,
      );
      expect(
        () => GeneratedRecipe.fromJson({...good(), 'category': 'brunch'}),
        throwsFormatException,
      );
      expect(
        () => GeneratedRecipe.fromJson({...good(), 'minutes': '30'}),
        throwsFormatException,
      );
      expect(
        () => GeneratedRecipe.fromJson({...good(), 'steps': 'Do it'}),
        throwsFormatException,
      );
    });

    test('becomes a normal Recipe with a "why" built from the choices', () {
      final c = _cases.first;
      final recipe = GeneratedRecipe.fromJson(
        c['recipe']! as Map<String, Object?>,
      );
      final request = _request(c['request']! as Map<String, Object?>);
      final built = recipe.toRecipe(
        id: 'u-1',
        request: request,
        catalogue: testCatalogue,
      );
      expect(built.id, 'u-1');
      expect(built.phase, Phase.menstrual);
      expect(
        built.whyThisPhase,
        'Made from the foods you chose: lentils, farro, spinach and carrot.',
      );
      expect(
        built.ingredients.firstWhere((l) => l.foodId == 'spinach').aisleId,
        testCatalogue.food('spinach')!.aisleId,
      );
      expect(built.ingredients.last.aisleId, 'pantry');
    });
  });

  group('fingerprint', () {
    GenerationRequest r(List<String> plants, {String key = 'a'}) =>
        GenerationRequest(
          idempotencyKey: key,
          phase: Phase.luteal,
          proteinId: 'tofu',
          baseId: 'farro',
          plantIds: plants,
        );

    test('ignores plant order and the idempotency key', () {
      expect(
        r(['spinach', 'carrot']).fingerprint,
        r(['carrot', 'spinach'], key: 'b').fingerprint,
      );
    });

    test('differs when a food or the phase differs', () {
      expect(
        r(['spinach', 'carrot']).fingerprint,
        isNot(r(['spinach', 'broccoli']).fingerprint),
      );
    });

    test('the request sends food ids only', () {
      expect(r(['spinach', 'carrot']).toJson().keys, {
        'idempotency_key',
        'phase',
        'protein_id',
        'base_id',
        'plant_ids',
      });
    });
  });
}
