import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/app/config/build_info.dart';

void main() {
  test('the lines read clearly', () {
    final info = BuildInfo(
      version: '0.1.0',
      buildNumber: '1',
      commit: 'a3dd5e3',
      builtAt: DateTime.utc(2026, 10, 25, 20, 5),
      flavor: Flavor.dev,
    );
    expect(info.versionLine, '0.1.0 (1)');
    expect(info.builtLine, '25 Oct 2026, 20:05 UTC');
    expect(info.flavorLabel, 'Development');
    expect(
      const BuildInfo(
        version: '1.0.0',
        buildNumber: '',
        commit: 'x',
        builtAt: null,
        flavor: Flavor.prod,
      ).flavorLabel,
      'Production',
    );
  });

  test(
    'a build made without the values says unknown, never a made-up value',
    () {
      final info = BuildInfo.fromBuild(
        version: '0.1.0',
        buildNumber: '1',
        flavor: Flavor.dev,
      );
      // No --dart-define in tests.
      expect(info.commit, 'unknown');
      expect(info.builtAt, isNull);
      expect(info.builtLine, 'Unknown');
    },
  );

  test('the commit comes from the build script, not from the source', () {
    final script = File('tool/build_ios.sh').readAsStringSync();
    expect(script, contains('git rev-parse --short HEAD'));
    expect(script, contains('--dart-define=GIT_SHA='));
    expect(script, contains('--dart-define=BUILD_DATE='));
    expect(script, contains('dirty'));
    // No commit id is typed into the app code.
    final source = File('lib/app/config/build_info.dart').readAsStringSync();
    expect(RegExp(r"'[0-9a-f]{7,40}'").hasMatch(source), isFalse);
  });
}
