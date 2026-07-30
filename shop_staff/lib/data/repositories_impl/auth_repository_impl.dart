import 'package:dio/dio.dart';
import 'package:shop_staff/core/auth/auth_token_store.dart';
import 'package:shop_staff/core/auth/authentication_change_notifier.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/domain/entities/auth_token.dart';
import 'package:shop_staff/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required DioClient client,
    required AuthTokenStore tokenStore,
  }) : _client = client,
       _tokenStore = tokenStore;

  static const _clientId = 'smartwe_pad';

  final DioClient _client;
  final AuthTokenStore _tokenStore;

  @override
  Future<void> sendEmailVerificationCode(String email) async {
    await _client.postJson<dynamic>(
      _client.endpoints.emailVerificationCode,
      body: <String, dynamic>{'email': email.trim()},
      options: Options(
        extra: const <String, dynamic>{
          DioClient.skipAuthenticationKey: true,
          DioClient.skipAuthenticationRefreshKey: true,
        },
      ),
    );
  }

  @override
  Future<void> loginWithEmailCode({
    required String email,
    required String verificationCode,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'scope': _clientId,
      'client_id': _clientId,
      'client_secret': _clientId,
      'auth_type': 'email',
      'grant_type': 'password',
      'username': email.trim(),
      'password': verificationCode.trim(),
    });
    final response = await _client.postJson<dynamic>(
      _client.endpoints.oauthToken,
      body: form,
      options: Options(
        extra: const <String, dynamic>{
          DioClient.skipAuthenticationKey: true,
          DioClient.skipAuthenticationRefreshKey: true,
        },
      ),
    );
    if (response is! Map) {
      throw StateError('AUTH_TOKEN_RESPONSE_INVALID');
    }
    final token = AuthToken.fromJson(Map<String, dynamic>.from(response));
    if (!token.isUsable) {
      throw StateError('AUTH_ACCESS_TOKEN_MISSING');
    }
    await Future.wait<void>([
      _tokenStore.save(token),
      _tokenStore.saveStaffEmail(email),
    ]);
    authenticationChangeNotifier.notifyAuthenticationChanged();
  }
}
