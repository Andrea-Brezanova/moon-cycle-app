import 'package:moon_cycle/core/database/encryption_key_store.dart';

/// Secure storage stand-in: a value in memory.
class MemoryKeyStore extends EncryptionKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<String> create() async => value = EncryptionKeyStore.newKey();

  @override
  Future<void> delete() async => value = null;
}
