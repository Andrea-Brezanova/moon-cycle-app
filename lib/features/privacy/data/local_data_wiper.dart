import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_opener.dart';
import '../../../core/database/encryption_key_store.dart';
import '../../reminders/application/reminder_providers.dart';

/// "Delete my data" without an account (plan §12): closes the database,
/// deletes its files and its encryption key, and runs [extraSteps] (for
/// example cancelling scheduled reminders).
class LocalDataWiper {
  LocalDataWiper({
    required AppDatabase database,
    required Directory directory,
    required EncryptionKeyStore keys,
    this.extraSteps = const [],
  }) : _db = database,
       _dir = directory,
       _keyStore = keys;

  final AppDatabase _db;
  final Directory _dir;
  final EncryptionKeyStore _keyStore;
  final List<Future<void> Function()> extraSteps;

  Future<void> wipe() async {
    for (final step in extraSteps) {
      await step();
    }
    await _db.close();
    if (_dir.existsSync()) {
      for (final entity in _dir.listSync()) {
        final name = entity.uri.pathSegments.last;
        // The database, its journal files, and any unreadable copy moved
        // aside by `openAppDatabase`.
        if (entity is File && name.startsWith(databaseFileName)) {
          entity.deleteSync();
        }
      }
    }
    await _keyStore.delete();
  }
}

/// The folder the database lives in. Set in `main()`.
final databaseDirectoryProvider = Provider<Directory>(
  (ref) =>
      throw UnimplementedError('databaseDirectoryProvider is set in main()'),
);

final encryptionKeyStoreProvider = Provider<EncryptionKeyStore>(
  (ref) => EncryptionKeyStore(),
);

/// Steps other features add to the wipe: cancelling scheduled reminders.
final wipeStepsProvider = Provider<List<Future<void> Function()>>(
  (ref) => [ref.watch(reminderSchedulerProvider).cancelAll],
);

final localDataWiperProvider = Provider<LocalDataWiper>(
  (ref) => LocalDataWiper(
    database: ref.watch(appDatabaseProvider),
    directory: ref.watch(databaseDirectoryProvider),
    keys: ref.watch(encryptionKeyStoreProvider),
    extraSteps: ref.watch(wipeStepsProvider),
  ),
);
