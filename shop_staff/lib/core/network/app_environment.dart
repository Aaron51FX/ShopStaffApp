enum AppEnvironment { production, staging }

extension AppEnvironmentX on AppEnvironment {
  String get wireValue {
    switch (this) {
      case AppEnvironment.production:
        return 'production';
      case AppEnvironment.staging:
        return 'staging';
    }
  }

  static AppEnvironment fromWireValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'dev':
      case 'development':
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
      default:
        return AppEnvironment.production;
    }
  }
}

AppEnvironment appEnvironmentFromDartDefine([String? raw]) {
  return AppEnvironmentX.fromWireValue(
    raw ?? const String.fromEnvironment('APP_ENV', defaultValue: 'production'),
  );
}

class AppConfig {
  final AppEnvironment env;
  final String apiBase;
  final String apiProfileBase;
  final String bookingBase;
  final String fileBase;
  final String faceBase;

  const AppConfig._({
    required this.env,
    required this.apiBase,
    required this.apiProfileBase,
    required this.bookingBase,
    required this.fileBase,
    required this.faceBase,
  });

  static AppConfig forEnv(AppEnvironment e) {
    switch (e) {
      case AppEnvironment.production:
        return const AppConfig._(
          env: AppEnvironment.production,
          apiProfileBase: 'https://api.smartwe.jp',
          apiBase: 'https://api.smartwe.jp',
          bookingBase: 'https://admin.gutingjun.com/api/booking',
          fileBase: 'https://app.smartwe.co.jp',
          faceBase: 'https://oa.gutingjun.com/api',
        );
      case AppEnvironment.staging:
        return const AppConfig._(
          env: AppEnvironment.staging,
          apiProfileBase: 'https://sit-api.smartwe.jp',
          apiBase: 'https://sit-api.smartwe.jp',
          bookingBase: 'https://sit-admin.gutingjun.com/api/booking',
          fileBase: 'https://app.smartwe.co.jp',
          faceBase: 'https://oa.gutingjun.com/api',
        );
    }
  }

  bool get isProd => env == AppEnvironment.production;
}
