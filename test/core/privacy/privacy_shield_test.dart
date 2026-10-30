import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/privacy/privacy_shield.dart';
import 'package:moon_cycle/core/storage/ui_prefs.dart';

class _Recorder implements PrivacyShield {
  final calls = <bool>[];
  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

void main() {
  group('the privacy shield setting', () {
    test('is off by default, when missing, or when damaged', () {
      expect(UiPrefs.empty.privacyShield, isFalse);
      expect(UiPrefs.fromJson(null).privacyShield, isFalse);
      expect(UiPrefs.fromJson({'privacyShield': 'yes'}).privacyShield, isFalse);
      expect(UiPrefs.fromJson({'privacyShield': 1}).privacyShield, isFalse);
    });

    test('survives a save and load, and leaves other settings alone', () {
      final on = const UiPrefs(
        collectionOrder: ['a'],
        detailedReminders: true,
      ).copyWith(privacyShield: true);
      final back = UiPrefs.fromJson(on.toJson());
      expect(back.privacyShield, isTrue);
      expect(back.detailedReminders, isTrue);
      expect(back.collectionOrder, ['a']);
    });
  });

  group('telling the native shell', () {
    test(
      'sends the stored value at start and each change, not repeats',
      () async {
        final shell = _Recorder();
        final container = ProviderContainer(
          overrides: [
            privacyShieldProvider.overrideWithValue(shell),
            initialUiPrefsProvider.overrideWithValue(
              const UiPrefs(privacyShield: true),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(uiPrefsProvider.notifier);
        expect(shell.calls, [true]); // the saved choice, applied at start
        await notifier.update(
          container.read(uiPrefsProvider).copyWith(meHero: 'x'),
        );
        expect(shell.calls, [true]); // an unrelated change sends nothing
        await notifier.update(
          container.read(uiPrefsProvider).copyWith(privacyShield: false),
        );
        expect(shell.calls, [true, false]);
      },
    );

    test('a fresh scope with default settings switches it off', () {
      final shell = _Recorder();
      final container = ProviderContainer(
        overrides: [privacyShieldProvider.overrideWithValue(shell)],
      );
      addTearDown(container.dispose);
      container.read(uiPrefsProvider);
      expect(shell.calls, [false]);
    });
  });
}
