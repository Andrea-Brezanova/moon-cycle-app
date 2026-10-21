import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';

void main() {
  test('every schema version has a snapshot for migration tests', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final snapshot = File(
      'drift_schemas/app_database/drift_schema_v${db.schemaVersion}.json',
    );
    expect(
      snapshot.existsSync(),
      isTrue,
      reason: 'Run `dart run drift_dev make-migrations` after a schema change.',
    );
  });
}
