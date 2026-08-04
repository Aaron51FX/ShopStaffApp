import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/auth/email_auth_usecase.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/domain/repositories/auth_repository.dart';
import 'package:shop_staff/presentations/auth/viewmodels/email_login_viewmodel.dart';

void main() {
  test('prefills the last successful login email', () async {
    final storage = _MemoryKeyValueStore();
    await storage.write(AppStorageKeys.staffEmail, 'staff@example.com');
    final viewModel = EmailLoginViewModel(
      EmailAuthUseCase(authRepository: _UnusedAuthRepository(), store: storage),
    );

    await Future<void>.delayed(Duration.zero);

    expect(viewModel.emailController.text, 'staff@example.com');
    expect(viewModel.state.email, 'staff@example.com');
    viewModel.dispose();
  });
}

class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<void> loginWithEmailCode({
    required String email,
    required String verificationCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerificationCode(String email) {
    throw UnimplementedError();
  }
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
