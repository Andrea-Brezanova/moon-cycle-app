// Writes the slim food catalogue the backend validates against, from the same
// `assets/content/foods.json` the app ships. A test fails if the committed copy
// is stale, so the app and the server always agree on what a food is.
//
//   dart run tool/sync_backend_catalogue.dart
import 'dart:convert';
import 'dart:io';

const outputPath = 'supabase/functions/_shared/data/catalogue.json';

/// The backend's view of the catalogue (shippable foods, validation fields).
String buildBackendCatalogue(String foodsJson) {
  final foods =
      ((jsonDecode(foodsJson) as Map<String, Object?>)['foods']!
              as List<Object?>)
          .cast<Map<String, Object?>>();
  final slim = [
    for (final f in foods)
      if (f['shipReady'] == true)
        {
          'id': f['id'],
          'name': f['name'],
          'category': f['category'],
          'animalSource': f['animalSource'],
          'allergens': f['allergens'],
          'mayContainAllergens': f['mayContainAllergens'] ?? const <Object?>[],
        },
  ];
  return '${const JsonEncoder.withIndent('  ').convert({'foods': slim})}\n';
}

void main() {
  final text = buildBackendCatalogue(
    File('assets/content/foods.json').readAsStringSync(),
  );
  File(outputPath).writeAsStringSync(text);
  stdout.writeln('Wrote $outputPath');
}
