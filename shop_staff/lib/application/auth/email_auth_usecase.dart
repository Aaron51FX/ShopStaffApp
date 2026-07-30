import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/repositories/auth_repository.dart';

final emailAuthUseCaseProvider = Provider<EmailAuthUseCase>((ref) {
  return EmailAuthUseCase(
    authRepository: ref.watch(authRepositoryProvider),
    store: ref.watch(keyValueStoreProvider),
  );
});

class EmailAuthUseCase {
  const EmailAuthUseCase({
    required AuthRepository authRepository,
    required KeyValueStore store,
  }) : _authRepository = authRepository,
       _store = store;

  final AuthRepository _authRepository;
  final KeyValueStore _store;

  Future<void> sendVerificationCode(String email) {
    return _authRepository.sendEmailVerificationCode(email);
  }

  Future<bool> login({
    required String email,
    required String verificationCode,
  }) async {
    await _authRepository.loginWithEmailCode(
      email: email,
      verificationCode: verificationCode,
    );
    return _store.contains(AppStorageKeys.activationCode);
  }
}
