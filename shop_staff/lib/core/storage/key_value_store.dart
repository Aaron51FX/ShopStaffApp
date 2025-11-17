import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class KeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<bool> contains(String key);
  Future<void> clearAll();
}

class SecureKeyValueStore implements KeyValueStore {
  final FlutterSecureStorage _storage;
  const SecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> contains(String key) async => (await read(key)) != null;

  @override
  Future<void> clearAll() => _storage.deleteAll();
}

final keyValueStoreProvider = Provider<KeyValueStore>((_) => const SecureKeyValueStore());

// Common keys
class AppStorageKeys {
  static const activationCode = 'activation_code';
  static const settingsBasic = 'settings_basic';
  static const settingsPosTerminal = 'settings_pos_terminal';
  static const settingsPrinter = 'settings_printer';
}
