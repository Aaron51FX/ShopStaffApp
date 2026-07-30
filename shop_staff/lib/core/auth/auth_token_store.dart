import 'dart:convert';

import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/domain/entities/auth_token.dart';

class AuthTokenStore {
  const AuthTokenStore(this._store);

  final KeyValueStore _store;

  Future<AuthToken?> read() async {
    final raw = await _store.read(AppStorageKeys.authToken);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final token = AuthToken.fromJson(Map<String, dynamic>.from(decoded));
      return token.isUsable ? token : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthToken token) {
    if (!token.isUsable) {
      throw ArgumentError('accessToken must not be empty');
    }
    return _store.write(AppStorageKeys.authToken, jsonEncode(token.toJson()));
  }

  Future<bool> hasToken() async => (await read()) != null;

  Future<void> clear() => _store.delete(AppStorageKeys.authToken);

  Future<void> saveStaffEmail(String email) {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('email must not be empty');
    }
    return _store.write(AppStorageKeys.staffEmail, normalized);
  }

  Future<String?> readStaffEmail() async {
    final email = (await _store.read(AppStorageKeys.staffEmail))?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  Future<void> clearStaffEmail() => _store.delete(AppStorageKeys.staffEmail);
}
