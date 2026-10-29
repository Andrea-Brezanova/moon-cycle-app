import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/privacy/application/data_export_service.dart';

void main() {
  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('moon_cycle_export_'));
  tearDown(() => temp.deleteSync(recursive: true));

  test(
    'an export left behind (the app was closed while sharing) is removed',
    () async {
      final folder = Directory('${temp.path}/$exportFolderName')..createSync();
      File('${folder.path}/moon-cycle-data-2026-10-29.json')
          .writeAsStringSync('{"a":1}');
      File('${folder.path}/moon-cycle-periods-2026-10-29.csv')
          .writeAsStringSync('start\n');
      await deleteStaleExports(temp);
      expect(folder.existsSync(), isFalse);
    },
  );

  test('nothing else in the temporary directory is touched', () async {
    Directory('${temp.path}/$exportFolderName').createSync();
    final other = File('${temp.path}/other.tmp')..writeAsStringSync('keep');
    final sibling = Directory('${temp.path}/export-like')..createSync();
    await deleteStaleExports(temp);
    expect(other.existsSync(), isTrue);
    expect(sibling.existsSync(), isTrue);
  });

  test('no export folder: nothing happens, no error', () async {
    await deleteStaleExports(temp);
    await deleteStaleExports(Directory('${temp.path}/missing'));
  });
}
