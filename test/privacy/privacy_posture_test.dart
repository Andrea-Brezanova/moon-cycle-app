import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the app's privacy posture. Each test fails when something changes
/// that would make the in-app statement "Your data lives on this phone ...
/// Nothing is sent to a server." untrue or widen what the app can access.
/// If one fails on purpose, update the privacy copy and the audit
/// (docs/privacy-and-data-audit.md) in the same change.
void main() {
  List<File> dartFiles(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

  test(
    'Android: no backups, and no network or other permission in release',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
      final permissions = RegExp(r'<uses-permission android:name="([^"]+)"')
          .allMatches(manifest)
          .map((m) => m.group(1))
          .toSet();
      expect(permissions, {'android.permission.RECEIVE_BOOT_COMPLETED'});
      expect(permissions, isNot(contains('android.permission.INTERNET')));
    },
  );

  test(
    'iOS: only the camera and photo-library prompts, each with a reason',
    () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final keys = RegExp(r'<key>(NS\w+UsageDescription)</key>')
          .allMatches(plist)
          .map((m) => m.group(1))
          .toSet();
      expect(keys, {
        'NSCameraUsageDescription',
        'NSPhotoLibraryUsageDescription',
      });
      expect(plist, isNot(contains('NSAllowsArbitraryLoads')));
    },
  );

  test('environment files with keys are never committed', () {
    final ignore = File('.gitignore').readAsStringSync();
    expect(ignore, contains('/env/*.json'));
    expect(ignore, contains('!/env/*.example.json'));
  });

  test('only the known network code can reach a server', () {
    // A new file that opens connections must be added here on purpose, after
    // checking what it sends and updating the privacy copy.
    const allowed = {
      'lib/features/discovery/data/providers/provider_http.dart',
      'lib/features/generation/data/cloud_generation_service.dart',
    };
    final found = <String>{
      for (final f in dartFiles('lib'))
        if (RegExp(
          r'HttpClient\(|package:http/|package:dio/|WebSocket\.connect',
        ).hasMatch(f.readAsStringSync()))
          f.path,
    };
    expect(found, allowed);
  });

  test('cloud recipe generation (which sends the cycle phase) is not wired into the UI', () {
    // It would make "Nothing is sent to a server" untrue. Wire it only with an
    // explicit consent step and updated copy.
    for (final f in dartFiles('lib')) {
      if (f.path.startsWith('lib/features/generation/data/')) continue;
      final text = f.readAsStringSync();
      expect(text, isNot(contains('CloudGenerationService(')), reason: f.path);
      expect(text, isNot(contains('CloudSubmissionService(')), reason: f.path);
    }
  });

  test(
    'external recipe lookups are limited to debug builds of the dev flavour',
    () {
      final text = File(
        'lib/features/discovery/application/discovery_providers.dart',
      ).readAsStringSync();
      expect(text, contains('enabled: dev'));
      expect(text, contains('debugPreviewAllowedProvider'));
    },
  );

  test('crash reports carry no personal data by configuration', () {
    final text = File('lib/core/crash/crash_reporting.dart').readAsStringSync();
    for (final setting in [
      'sendDefaultPii = false',
      'attachScreenshot = false',
      'tracesSampleRate = 0',
      'beforeBreadcrumb = dropBreadcrumb',
      'beforeSend = scrubEvent',
    ]) {
      expect(text, contains(setting));
    }
  });

  test('the exported files are deleted after sharing, even on failure', () {
    final text = File(
      'lib/features/privacy/application/data_export_service.dart',
    ).readAsStringSync();
    expect(text, contains('finally'));
    expect(text, contains('deleteSync()'));
  });

  test('nothing logs diary, cycle or recipe content', () {
    // The only prints in the app are for database recovery, reminders
    // scheduling and the time zone; none interpolates user content.
    final prints = <String>[
      for (final f in dartFiles('lib'))
        for (final m in RegExp(
          r'debugPrint\([^;]*;',
        ).allMatches(f.readAsStringSync()))
          '${f.path}: ${m.group(0)}',
    ];
    expect(prints, hasLength(3), reason: prints.join('\n'));
    for (final p in prints) {
      expect(
        p.toLowerCase(),
        isNot(
          anyOf(
            contains('diary'),
            contains('symptom'),
            contains('note'),
            contains('period'),
            contains('recipe'),
          ),
        ),
        reason: p,
      );
    }
  });
}
