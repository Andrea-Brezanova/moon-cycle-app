import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Small interface settings kept on the phone, outside the encrypted database:
/// the order of the My Collections tiles and the choice of Me hero image. They
/// hold no health data and need no schema change. "Delete my data" removes
/// them (see [UiPrefsStore.deleteAll]).
final class UiPrefs {
  const UiPrefs({this.collectionOrder = const [], this.meHero});

  /// Keys of the My Collections tiles, in the user's order (may be partial).
  final List<String> collectionOrder;

  /// The Me hero: `bundled:<id>`, `custom`, or null for the default.
  final String? meHero;

  static const empty = UiPrefs();

  UiPrefs copyWith({
    List<String>? collectionOrder,
    String? meHero,
    bool clearMeHero = false,
  }) => UiPrefs(
    collectionOrder: collectionOrder ?? this.collectionOrder,
    meHero: clearMeHero ? null : (meHero ?? this.meHero),
  );

  Map<String, Object?> toJson() => {
    'collectionOrder': collectionOrder,
    'meHero': meHero,
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
    );
  }
}

/// Where [UiPrefs] live.
abstract interface class UiPrefsStore {
  Future<UiPrefs> load();
  Future<void> save(UiPrefs prefs);

  /// Removes the preferences and any personal image kept with them.
  Future<void> deleteAll();
}

/// The settings file and the personal hero image, in the app's own support
/// directory (private to the app, not in the photo library).
class FileUiPrefsStore implements UiPrefsStore {
  FileUiPrefsStore(this.directory);

  final Directory directory;

  static const fileName = 'ui_preferences.json';
  static const heroFileName = 'me_hero.jpg';

  File get _file => File('${directory.path}/$fileName');
  File get heroFile => File('${directory.path}/$heroFileName');

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
  Future<void> deleteAll() async {
    for (final f in [_file, File('${_file.path}.tmp'), heroFile]) {
      if (f.existsSync()) f.deleteSync();
    }
  }
}

/// Keeps everything in memory: the default in tests and previews.
class MemoryUiPrefsStore implements UiPrefsStore {
  MemoryUiPrefsStore([this.prefs = UiPrefs.empty]);

  UiPrefs prefs;
  int deletes = 0;

  @override
  Future<UiPrefs> load() async => prefs;

  @override
  Future<void> save(UiPrefs next) async => prefs = next;

  @override
  Future<void> deleteAll() async {
    prefs = UiPrefs.empty;
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
  UiPrefs build() => ref.read(initialUiPrefsProvider);

  Future<void> update(UiPrefs next) async {
    state = next;
    await ref.read(uiPrefsStoreProvider).save(next);
  }
}
