import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_database.dart';
import 'encryption_key_store.dart';

const databaseFileName = 'moon_cycle.db';

/// Opens the encrypted database in [directory], creating it (and its key)
/// on first launch.
///
/// - No database file yet: a new key is made. On iOS the Keychain survives
///   an uninstall, so this also replaces a key left behind by an earlier
///   install.
/// - A file that can't be opened with the stored key (the key was lost, for
///   example after a restore without the Keychain) can never be read again.
///   It is moved aside and a fresh database is started, rather than leaving
///   the app unable to start.
Future<AppDatabase> openAppDatabase({
  required Directory directory,
  required EncryptionKeyStore keys,
}) async {
  final file = File('${directory.path}/$databaseFileName');
  String key;
  if (!file.existsSync()) {
    key = await keys.create();
  } else {
    final stored = await keys.read();
    if (stored != null && canOpenEncrypted(file, stored)) {
      key = stored;
    } else {
      final aside =
          '${file.path}.unreadable-${file.lastModifiedSync().millisecondsSinceEpoch}';
      debugPrint('Database could not be decrypted; moved to $aside');
      file.renameSync(aside);
      key = await keys.create();
    }
  }
  return AppDatabase(
    NativeDatabase.createBackgroundConnection(
      file,
      setup: (db) => applyEncryptionKey(db, key),
    ),
  );
}

/// Unlocks [db] with [key]. Throws if this build's SQLite has no encryption,
/// so data is never written unencrypted by mistake.
void applyEncryptionKey(Database db, String key) {
  _checkEncryptionAvailable();
  // The key is 64 hex characters, so it never needs escaping.
  assert(RegExp(r'^[0-9a-f]{64}$').hasMatch(key));
  db.execute("PRAGMA key = '$key'");
}

/// Plain SQLite ignores `PRAGMA key`, so check for the encrypting build
/// first. (On a separate in-memory database: any query on an encrypted file
/// fails until the key is set.)
void _checkEncryptionAvailable() {
  final probe = sqlite3.openInMemory();
  try {
    probe.select('SELECT sqlite3mc_version()');
  } on SqliteException {
    throw StateError(
      'SQLite was built without encryption. Check the sqlite3 hook options '
      'in pubspec.yaml.',
    );
  } finally {
    probe.close();
  }
}

/// Whether [file] opens with [key]. A wrong key fails on the first read.
bool canOpenEncrypted(File file, String key) {
  final db = sqlite3.open(file.path);
  try {
    applyEncryptionKey(db, key);
    db.select('SELECT count(*) FROM sqlite_master');
    return true;
  } on SqliteException {
    return false;
  } finally {
    db.close();
  }
}
