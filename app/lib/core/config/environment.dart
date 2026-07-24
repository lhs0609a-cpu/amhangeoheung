/// 앱 환경 설정
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get current => _environment;

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  /// API Base URL
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://localhost:3000/api',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://amhangeoheung-backend-staging.fly.dev/api',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://amhangeoheung-backend.fly.dev/api',
        );
    }
  }

  /// 앱 이름
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return '암행어흥 (Dev)';
      case Environment.staging:
        return '암행어흥 (Staging)';
      case Environment.production:
        return '암행어흥';
    }
  }

  /// 아임포트 가맹점 ID
  static String get iamportMerchantId {
    switch (_environment) {
      case Environment.development:
        return const String.fromEnvironment(
          'IAMPORT_MERCHANT_ID',
          defaultValue: 'imp00000000',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'IAMPORT_MERCHANT_ID',
          defaultValue: 'imp00000000',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'IAMPORT_MERCHANT_ID',
          defaultValue: 'imp_amhangeoheung',
        );
    }
  }

  /// Toss Payments 클라이언트 키 (위젯 SDK용).
  /// 운영 키는 --dart-define=TOSS_CLIENT_KEY=... 로 주입한다.
  /// 기본값은 Toss 공식 문서의 공용 테스트 키.
  static String get tossClientKey {
    switch (_environment) {
      case Environment.development:
      case Environment.staging:
        return const String.fromEnvironment(
          'TOSS_CLIENT_KEY',
          defaultValue: 'test_ck_docs_Ovk5rk1EwkEbP0W43n07xlzm',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'TOSS_CLIENT_KEY',
          defaultValue: '',
        );
    }
  }

  /// 디버그 모드 여부
  static bool get enableDebugMode {
    return _environment != Environment.production;
  }

  /// 로깅 활성화 여부
  static bool get enableLogging {
    return _environment != Environment.production;
  }
}
