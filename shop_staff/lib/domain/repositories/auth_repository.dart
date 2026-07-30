abstract class AuthRepository {
  Future<void> sendEmailVerificationCode(String email);

  Future<void> loginWithEmailCode({
    required String email,
    required String verificationCode,
  });
}
