import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/storage/ui_prefs.dart';

void main() {
  group('detailed reminders preference', () {
    test('is off by default', () {
      expect(UiPrefs.empty.detailedReminders, isFalse);
      expect(const UiPrefs().detailedReminders, isFalse);
    });

    test('a missing, damaged or odd value means off', () {
      expect(UiPrefs.fromJson(null).detailedReminders, isFalse);
      expect(UiPrefs.fromJson('nonsense').detailedReminders, isFalse);
      expect(UiPrefs.fromJson(<String, Object?>{}).detailedReminders, isFalse);
      for (final odd in <Object?>['true', 1, null, 'yes', const []]) {
        expect(
          UiPrefs.fromJson({'detailedReminders': odd}).detailedReminders,
          isFalse,
          reason: '$odd',
        );
      }
    });

    test('only an explicit true opts in, and it round-trips', () {
      final on = UiPrefs.fromJson({'detailedReminders': true});
      expect(on.detailedReminders, isTrue);
      expect(UiPrefs.fromJson(on.toJson()).detailedReminders, isTrue);
    });

    test('older files without the setting keep the other choices', () {
      final p = UiPrefs.fromJson({
        'collectionOrder': ['recipes'],
        'meHero': 'bundled:x',
      });
      expect(p.detailedReminders, isFalse);
      expect(p.collectionOrder, ['recipes']);
      expect(p.meHero, 'bundled:x');
    });

    test('changing it leaves the other choices alone', () {
      const base = UiPrefs(collectionOrder: ['a'], meHero: 'custom:y');
      final next = base.copyWith(detailedReminders: true);
      expect(next.collectionOrder, ['a']);
      expect(next.meHero, 'custom:y');
      expect(next.copyWith(clearMeHero: true).detailedReminders, isTrue);
    });

    test('Delete my data returns it to off', () async {
      final store = MemoryUiPrefsStore(const UiPrefs(detailedReminders: true));
      await store.deleteAll();
      expect((await store.load()).detailedReminders, isFalse);
    });
  });
}
