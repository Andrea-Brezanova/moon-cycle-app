import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/storage/ui_prefs.dart';

/// Guards the optional app-switcher privacy shield and the settings file that
/// holds it. If one of these fails on purpose, update
/// docs/privacy-and-data-audit.md (finding P5) in the same change.
void main() {
  const channel = 'app.mooncycle/privacy_shield';

  test('the shield and the detailed reminders are off by default', () {
    expect(UiPrefs.empty.privacyShield, isFalse);
    expect(UiPrefs.empty.detailedReminders, isFalse);
    expect(UiPrefs.fromJson('damaged').privacyShield, isFalse);
  });

  test('the settings file holds only these keys, none of them health data', () {
    expect(const UiPrefs().toJson().keys.toSet(), {
      'collectionOrder',
      'meHero',
      'detailedReminders',
      'privacyShield',
    });
  });

  test('the Dart side and both native shells use the same channel', () {
    expect(
      File('lib/core/privacy/privacy_shield.dart').readAsStringSync(),
      contains(channel),
    );
    expect(
      File('ios/Runner/AppDelegate.swift').readAsStringSync(),
      contains(channel),
    );
    expect(
      File('android/app/src/main/kotlin/app/mooncycle/mobile/MainActivity.kt')
          .readAsStringSync(),
      contains(channel),
    );
  });

  test('iOS covers the window when inactive and removes it when active', () {
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift, contains('willResignActiveNotification'));
    expect(swift, contains('didBecomeActiveNotification'));
    expect(swift, contains('guard enabled'));
    // The cover is opaque: a translucent or blurred one could leak content.
    expect(swift, contains('.systemBackground'));
    expect(swift, isNot(contains('UIBlurEffect')));
  });

  test('Android sets FLAG_SECURE only through the shield channel', () {
    final hits = <String>[
      for (final f
          in Directory('android/app/src')
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (f) =>
                    f.path.endsWith('.kt') ||
                    f.path.endsWith('.java') ||
                    f.path.endsWith('.xml'),
              ))
        if (f.readAsStringSync().contains('FLAG_SECURE')) f.path,
    ];
    expect(hits, hasLength(1));
    expect(hits.single, endsWith('MainActivity.kt'));
  });

  test(
    '"Delete my data" removes the settings file, so the shield resets',
    () async {
      final dir = Directory.systemTemp.createTempSync('shield_posture');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = FileUiPrefsStore(dir);
      await store.save(
        const UiPrefs(privacyShield: true, detailedReminders: true),
      );
      expect((await store.load()).privacyShield, isTrue);
      await store.deleteAll();
      final after = await store.load();
      expect(after.privacyShield, isFalse);
      expect(after.detailedReminders, isFalse);
      expect(
        File('${dir.path}/${FileUiPrefsStore.fileName}').existsSync(),
        isFalse,
      );
    },
  );

  test('turning the shield on adds no permission, SDK or network code', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(RegExp('UsageDescription').allMatches(plist), hasLength(2));
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, isNot(contains('INTERNET')));
    final src = File('lib/core/privacy/privacy_shield.dart').readAsStringSync();
    expect(src, isNot(contains('http')));
    expect(src, isNot(contains('dart:io')));
  });
}
