
enum AppEnvironment { production, staging }

class AppConfig {
  final AppEnvironment env;
  final String apiBase;
  final String apiProfileBase;
  final String fileBase;
  final String faceBase;

  const AppConfig._({
    required this.env,
    required this.apiBase,
    required this.apiProfileBase,
    required this.fileBase,
    required this.faceBase,
  });

  static AppConfig forEnv(AppEnvironment e) {
    switch (e) {
      case AppEnvironment.production:
        return const AppConfig._(
          env: AppEnvironment.production,
          apiProfileBase: 'https://api.smartwe.jp/',
          apiBase: 'https://api.smartwe.jp/',
          fileBase: 'https://app.smartwe.co.jp/',
          faceBase: 'https://oa.gutingjun.com/api/',
        );
      case AppEnvironment.staging:
        return const AppConfig._(
          env: AppEnvironment.staging,
          apiProfileBase: 'https://sit-api.smartwe.jp/',
          apiBase: 'https://sit-api.smartwe.jp/',
          fileBase: 'https://app.smartwe.co.jp/',
          faceBase: 'https://oa.gutingjun.com/api/',
        );
    }
  }

  bool get isProd => env == AppEnvironment.production;
}
