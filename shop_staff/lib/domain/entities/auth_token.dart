class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.expiresIn,
    this.scope,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int? expiresIn;
  final String? scope;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      expiresIn: switch (json['expires_in']) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      },
      scope: json['scope']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
    if (expiresIn != null) 'expires_in': expiresIn,
    if (scope != null) 'scope': scope,
  };

  bool get isUsable => accessToken.trim().isNotEmpty;

  String get authorizationValue {
    final type = tokenType.trim().isEmpty ? 'Bearer' : tokenType.trim();
    return '$type ${accessToken.trim()}';
  }
}
