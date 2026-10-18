import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/sync_backend_catalogue.dart';

void main() {
  test('the backend catalogue copy is in sync with the app\'s foods.json', () {
    final expected = buildBackendCatalogue(
      File('assets/content/foods.json').readAsStringSync(),
    );
    final committed = File(outputPath).readAsStringSync();
    expect(
      committed,
      expected,
      reason: 'Run `dart run tool/sync_backend_catalogue.dart`.',
    );
  });

  test('it holds only shippable foods and only validation fields', () {
    final text = File(outputPath).readAsStringSync();
    expect(text, isNot(contains('"why"')));
    expect(text, isNot(contains('shipReady')));
    expect(text, contains('"id": "tofu"'));
  });
}
