import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../privacy/privacy_shield.dart';

/// Small interface settings kept on the phone, outside the encrypted database:
/// the order of the My Collections tiles and the choice of Me hero image. They
/// hold no health data and need no schema change. "Delete my data" removes
/// them (see [UiPrefsStore.deleteAll]).
final class UiPrefs {
  const UiPrefs({
    this.collectionOrder = const [],
    this.meHero,
    this.detailedReminders = false,
    this.privacyShield = false,
  });

  /// Keys of the My Collections tiles, in the user's order (may be partial).
  final List<String> collectionOrder;

  /// The Me hero: `bundled:<id>`, `custom:<file name>`, or null for the
  /// default.
  final String? meHero;

  /// Whether reminders may say what they are about (the phase, the period).
  /// Off by default: a reminder then only says that there is one, so nothing
  /// about the cycle shows on a lock screen. A missing or damaged settings
  /// file also means off.
  final bool detailedReminders;

  /// Whether the app hides its contents in the app switcher. Off by default;
  /// a missing or damaged settings file also means off.
  final bool privacyShield;

  static const empty = UiPrefs();

  UiPrefs copyWith({
    List<String>? collectionOrder,
    String? meHero,
    bool clearMeHero = false,
    bool? detailedReminders,
    bool? privacyShield,
  }) => UiPrefs(
    collectionOrder: collectionOrder ?? this.collectionOrder,
    meHero: clearMeHero ? null : (meHero ?? this.meHero),
    detailedReminders: detailedReminders ?? this.detailedReminders,
    privacyShield: privacyShield ?? this.privacyShield,
  );

  Map<String, Object?> toJson() => {
    'collectionOrder': collectionOrder,
    'meHero': meHero,
    'detailedReminders': detailedReminders,
    'privacyShield': privacyShield,
  };

  factory UiPrefs.fromJson(Object? json) {
    if (json is! Map) return empty;
    final order = json['collectionOrder'];
    final hero = json['meHero'];
    return UiPrefs(
      collectionOrder: [
        if (order is List)
          for (final k in order)
            if (k is String) k,
      ],
      meHero: hero is String ? hero : null,
      detailedReminders: json['detailedReminders'] == true,
      privacyShield: json['privacyShield'] == true,
    );
  }
}

/// Where [UiPrefs] live.
abstract interface class UiPrefsStore {
  Future<UiPrefs> load();
  Future<void> save(UiPrefs prefs);

  /// Keeps [bytes] (an already resized, re-encoded JPEG) as the personal Me
  /// image and returns its file name. Each call makes a new name, so a changed
  /// picture is never shown from a stale cache.
  Future<String> saveHeroImage(Uint8List bytes);

  /// The personal image saved under [name], or null if it is gone.
  ImageProvider? heroImage(String name);

  /// Removes one personal image.
  Future<void> deleteHeroImage(String name);

  /// Removes the preferences and every personal image kept with them.
  Future<void> deleteAll();
}

/// The settings file and the personal hero image, in the app's own support
/// directory (private to the app, not in the photo library).
class FileUiPrefsStore implements UiPrefsStore {
  FileUiPrefsStore(this.directory);

  final Directory directory;

  static const fileName = 'ui_preferences.json';
  static const heroPrefix = 'me_hero_';
  static final _heroName = RegExp(r'^me_hero_\d+\.jpg$');

  File get _file => File('${directory.path}/$fileName');

  Iterable<File> get _heroFiles => directory.existsSync()
      ? directory.listSync().whereType<File>().where(
          (f) => f.uri.pathSegments.last.startsWith(heroPrefix),
        )
      : const [];

  @override
  Future<UiPrefs> load() async {
    try {
      if (!_file.existsSync()) return UiPrefs.empty;
      return UiPrefs.fromJson(jsonDecode(await _file.readAsString()));
    } on Object {
      // A damaged file is just a missing one: start from the defaults.
      return UiPrefs.empty;
    }
  }

  @override
  Future<void> save(UiPrefs prefs) async {
    // Write to a temporary file first so a crash never leaves half a file.
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(prefs.toJson()), flush: true);
    await tmp.rename(_file.path);
  }

  @override
  Future<String> saveHeroImage(Uint8List bytes) async {
    final name = '$heroPrefix${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File('${directory.path}/$name').writeAsBytes(bytes, flush: true);
    return name;
  }

  @override
  ImageProvider? heroImage(String name) {
    // Only names this store made: never a path chosen from outside.
    if (!_heroName.hasMatch(name)) return null;
    final f = File('${directory.path}/$name');
    return f.existsSync() ? FileImage(f) : null;
  }

  @override
  Future<void> deleteHeroImage(String name) async {
    if (!_heroName.hasMatch(name)) return;
    final f = File('${directory.path}/$name');
    if (f.existsSync()) f.deleteSync();
  }

  @override
  Future<void> deleteAll() async {
    for (final f in [_file, File('${_file.path}.tmp'), ..._heroFiles]) {
      if (f.existsSync()) f.deleteSync();
    }
  }
}

/// Keeps everything in memory: the default in tests and previews.
class MemoryUiPrefsStore implements UiPrefsStore {
  MemoryUiPrefsStore([this.prefs = UiPrefs.empty]);

  UiPrefs prefs;
  int deletes = 0;

  /// The personal images kept, by name.
  final Map<String, Uint8List> images = {};

  @override
  Future<UiPrefs> load() async => prefs;

  @override
  Future<void> save(UiPrefs next) async => prefs = next;

  @override
  Future<String> saveHeroImage(Uint8List bytes) async {
    final name = 'me_hero_${images.length + 1}_${bytes.length}.jpg';
    images[name] = bytes;
    return name;
  }

  @override
  ImageProvider? heroImage(String name) =>
      images[name] == null ? null : MemoryImage(images[name]!);

  @override
  Future<void> deleteHeroImage(String name) async => images.remove(name);

  @override
  Future<void> deleteAll() async {
    prefs = UiPrefs.empty;
    images.clear();
    deletes++;
  }
}

final uiPrefsStoreProvider = Provider<UiPrefsStore>(
  (ref) => MemoryUiPrefsStore(),
);

/// The preferences read at start-up (set in `main()`).
final initialUiPrefsProvider = Provider<UiPrefs>((ref) => UiPrefs.empty);

final uiPrefsProvider = NotifierProvider<UiPrefsController, UiPrefs>(
  UiPrefsController.new,
);

class UiPrefsController extends Notifier<UiPrefs> {
  @override
  UiPrefs build() {
    final prefs = ref.read(initialUiPrefsProvider);
    // "Delete my data" starts a new scope with the defaults, which switches
    // the shield off again.
    ref.read(privacyShieldProvider).setEnabled(prefs.privacyShield);
    return prefs;
  }

  Future<void> update(UiPrefs next) async {
    final changed = next.privacyShield != state.privacyShield;
    state = next;
    if (changed) {
      await ref.read(privacyShieldProvider).setEnabled(next.privacyShield);
    }
    await ref.read(uiPrefsStoreProvider).save(next);
  }
}
