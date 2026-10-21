import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the database encryption key in the platform's secure storage:
/// the iOS Keychain and the Android Keystore.
class EncryptionKeyStore {
  EncryptionKeyStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Readable after the first unlock, so a reminder or a background
            // task can open the database. It moves to a new iPhone only
            // inside an encrypted backup, together with the database.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const _keyName = 'moon_cycle.db_key';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _keyName);

  /// Makes a new random 256-bit key, stores it and returns it. Replaces any
  /// key left over from an earlier install.
  Future<String> create() async {
    final key = newKey();
    await _storage.write(key: _keyName, value: key);
    return key;
  }

  Future<void> delete() => _storage.delete(key: _keyName);

  /// 32 random bytes as 64 hex characters.
  static String newKey() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 32; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
