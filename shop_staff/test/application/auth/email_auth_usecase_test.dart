import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/auth/email_auth_usecase.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/domain/repositories/auth_repository.dart';

void main() {
  test(
    'new login requires machine activation when no machine is saved',
    () async {
      final repository = _FakeAuthRepository();
      final useCase = EmailAuthUseCase(
        authRepository: repository,
        store: _MemoryKeyValueStore(),
      );

      final hasMachine = await useCase.login(
        email: 'staff@example.com',
        verificationCode: '123456',
      );

      expect(hasMachine, isFalse);
      expect(repository.loginCalls, 1);
    },
  );

  test('re-login skips machine input when activation is preserved', () async {
    final repository = _FakeAuthRepository();
    final storage = _MemoryKeyValueStore();
    await storage.write(AppStorageKeys.activationCode, 'MACHINE-1');
    final useCase = EmailAuthUseCase(
      authRepository: repository,
      store: storage,
    );

    final hasMachine = await useCase.login(
      email: 'staff@example.com',
      verificationCode: '123456',
    );

    expect(hasMachine, isTrue);
  });
}

class _FakeAuthRepository implements AuthRepository {
  int loginCalls = 0;

  @override
  Future<void> loginWithEmailCode({
    required String email,
    required String verificationCode,
  }) async {
    loginCalls += 1;
  }

  @override
  Future<void> sendEmailVerificationCode(String email) async {}
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
