import 'dart:convert';
import 'dart:io';

import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';

Object readFixture(String name) =>
    jsonDecode(File('test/fixtures/external/$name').readAsStringSync())
        as Object;

/// A fake network: [route] answers each URL (status and body), and every URL
/// asked is recorded.
class FakeNetwork {
  FakeNetwork(this.route);

  final ({int status, String body}) Function(Uri url) route;
  final calls = <Uri>[];

  HttpGet get get => (url, headers) async {
    calls.add(url);
    return route(url);
  };

  static ({int status, String body}) ok(Object json) =>
      (status: 200, body: jsonEncode(json));
}

/// TheMealDB's fixtures behind its real URL shapes.
FakeNetwork mealDbNetwork({
  Map<String, Object> filters = const {},
  Set<String> failIngredients = const {},
}) {
  final lookups =
      (readFixture('themealdb_lookups.json')) as Map<String, Object?>;
  final garlic = readFixture('themealdb_filter_garlic.json');
  final kale = readFixture('themealdb_filter_kale.json');
  return FakeNetwork((url) {
    final file = url.pathSegments.last;
    if (file == 'filter.php') {
      final i = url.queryParameters['i']!;
      if (failIngredients.contains(i)) return (status: 500, body: 'oops');
      if (filters.containsKey(i)) return FakeNetwork.ok(filters[i]!);
      return switch (i) {
        'garlic' => FakeNetwork.ok(garlic),
        'kale' => FakeNetwork.ok(kale),
        _ => FakeNetwork.ok({'meals': null}),
      };
    }
    final id = url.queryParameters['i']!;
    return FakeNetwork.ok(lookups[id] ?? {'meals': null});
  });
}
