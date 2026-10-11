// Checks one architecture rule: code in any `domain/` folder under lib/ is
// pure Dart. It must not import Flutter, Riverpod, Drift or Supabase, so the
// business logic (cycle maths, shopping merge) stays easy to test and reuse.
//
// Run: dart run tool/check_layers.dart   (CI runs it on every push)

import 'dart:io';

const forbidden = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod/',
  'package:drift/',
  'package:supabase',
  'dart:ui',
];

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run from the repository root (lib/ not found).');
    exit(2);
  }

  final domainFiles = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => f.uri.pathSegments.contains('domain'))
      .toList();

  final violations = <String>[];
  for (final file in domainFiles) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('import ') && !line.startsWith('export ')) continue;
      for (final prefix in forbidden) {
        if (line.contains("'$prefix") || line.contains('"$prefix')) {
          violations.add('${file.path}:${i + 1}  $line');
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'check_layers: OK (${domainFiles.length} domain files checked)',
    );
    return;
  }
  stderr.writeln('check_layers: domain code must be pure Dart:');
  violations.forEach(stderr.writeln);
  exit(1);
}
