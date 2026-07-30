import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/auth/auth_token_store.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/domain/entities/auth_token.dart';

void main() {
  test('persists and clears OAuth token', () async {
    final storage = _MemoryKeyValueStore();
    final tokenStore = AuthTokenStore(storage);
    const token = AuthToken(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      tokenType: 'Bearer',
      expiresIn: 3600,
    );

    await tokenStore.save(token);
    await tokenStore.saveStaffEmail(' staff@example.com ');

    expect((await tokenStore.read())?.accessToken, 'access-1');
    expect((await tokenStore.read())?.refreshToken, 'refresh-1');
    expect(await tokenStore.readStaffEmail(), 'staff@example.com');
    expect(await tokenStore.hasToken(), isTrue);

    await tokenStore.clear();
    expect(await tokenStore.read(), isNull);
    expect(
      await tokenStore.readStaffEmail(),
      'staff@example.com',
      reason: 'automatic token clearing must preserve the current staff email',
    );

    await tokenStore.clearStaffEmail();
    expect(await tokenStore.readStaffEmail(), isNull);
  });

  test('treats corrupt token data as unauthenticated', () async {
    final storage = _MemoryKeyValueStore();
    await storage.write(AppStorageKeys.authToken, 'not-json');

    expect(await AuthTokenStore(storage).read(), isNull);
  });
}

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
