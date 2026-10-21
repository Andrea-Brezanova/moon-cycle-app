// Benchmarks the recipe sources on a fixed set of ingredient selections:
// the Moon Cycle library, TheMealDB (free *test key*, development use) and the
// two combined. Recipe API is included only if a probe capture exists.
//
//   dart run tool/provider_benchmark.dart            # live TheMealDB (≈100 requests)
//
// Makes no request to any paid service.
import 'dart:convert';
import 'dart:io';

import 'package:moon_cycle/features/content/data/catalogue_parser.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';
import 'package:moon_cycle/features/discovery/data/providers/themealdb_client.dart';
import 'package:moon_cycle/features/discovery/data/recipe_sources.dart';
import 'package:moon_cycle/features/discovery/domain/provider_policy.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_discovery.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_matcher.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_source.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';

Map<String, Object?> _json(String n) =>
    jsonDecode(File('assets/content/$n.json').readAsStringSync())
        as Map<String, Object?>;

Future<void> main() async {
  final catalogue = parseCatalogue(
    taxonomy: _json('taxonomy'),
    phases: _json('phases'),
    foods: _json('foods'),
    recipes: _json('recipes'),
  );
  final policy = TheMealDbClient.policyDefaults.copyWith(
    enabled: true,
    monthlyRequestBudget: 100000,
    maxRequestsPerMinute: 100000,
    cacheTtl: const Duration(hours: 1),
  );
  final client = TheMealDbClient(
    http: ProviderHttp(policy: policy, ledger: InMemoryUsageLedger()),
    catalogue: catalogue,
    policy: policy,
  );
  final internal = InternalRecipeSource(catalogue);
  final external = ExternalRecipeSource(client, catalogue, policy: policy);

  final selections = <String, List<String>>{
    'chicken': ['chicken'],
    'salmon': ['salmon'],
    'chickpea': ['chickpea'],
    'kale': ['kale'],
    'tofu': ['tofu'],
    'quinoa': ['quinoa'],
    'chicken+broccoli': ['chicken', 'broccoli'],
    'lentils+spinach': ['green-lentil', 'spinach'],
    'salmon+sweet-potato': ['salmon', 'sweet-potato'],
    'eggs+spinach+feta': ['eggs', 'spinach', 'feta'],
    'chickpea+spinach+tomato+onion': ['chickpea', 'spinach', 'tomato', 'onion'],
    'tofu+broccoli+rice+carrot': ['tofu', 'broccoli', 'brown-rice', 'carrot'],
  };
  final filters = <String, FoodFilter>{
    'no restrictions': FoodFilter.none,
    'vegetarian': const FoodFilter(diet: Diet.vegetarian),
  };

  String pct(num a, num b) => b == 0 ? '-' : '${(100 * a / b).round()}%';
  final rows = StringBuffer();
  rows.writeln(
    '| Selection | Filter | Library | TheMealDB (shown) | Combined (unique) | '
    'Complete | Partial | MealDB time |',
  );
  rows.writeln('|---|---|---|---|---|---|---|---|');
  var totalExternalShown = 0;
  var withPhoto = 0;
  for (final f in filters.entries) {
    for (final s in selections.entries) {
      final choice = MealChoice(s.value);
      final lib = await internal.find(choice, f.value);
      final sw = Stopwatch()..start();
      List<dynamic> ext = const [];
      try {
        ext = await external.find(choice, f.value);
      } on Object catch (e) {
        stderr.writeln('${s.key}: $e');
      }
      sw.stop();
      final combined = await RecipeDiscovery([internal, external])
          .discover(choice, f.value);
      final complete = combined.results.where((c) => c.isComplete).length;
      totalExternalShown += ext.length;
      withPhoto += combined.results
          .where(
            (c) =>
                c.source == RecipeSource.externalApi &&
                c.recipe.imageUrl != null,
          )
          .length;
      rows.writeln(
        '| ${s.key} | ${f.key} | ${lib.length} | ${ext.length} | '
        '${combined.results.length} | $complete | '
        '${combined.results.length - complete} | ${sw.elapsedMilliseconds} ms |',
      );
    }
  }
  stdout.write(rows);
  stdout.writeln(
    '\nTheMealDB recipes shown in total: $totalExternalShown; with a photo URL: $withPhoto (${pct(withPhoto, totalExternalShown)})',
  );
}
