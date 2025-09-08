enum AppEnvironment { production, test }

class EnvironmentConfig {
  EnvironmentConfig._();
  static AppEnvironment current = AppEnvironment.production;

  static String get baseProfile => 'https://api.smartwe.jp/';
  static String get baseTest => 'https://sit-api.smartwe.jp/';
  static String get fileBase => 'https://app.smartwe.co.jp/';
  static String get oaBase => 'https://oa.gutingjun.com/api/';

  static String get baseUrl => current == AppEnvironment.production ? baseProfile : baseTest;

  static bool get isProduction => current == AppEnvironment.production;
}
