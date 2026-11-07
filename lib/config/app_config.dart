enum Environment { development, staging, production }

class AppConfig {
  static Environment environment = Environment.staging;

  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://intira.test/api';
      case Environment.staging:
        return 'https://testing.intirasolusi.id/api';
      case Environment.production:
        return 'https://intirasolusi.id/api';
    }
  }

  static String get appName => 'Intira Mobile';

  static void setEnvironment(Environment env) {
    environment = env;
  }

  static void setFromString(String? env) {
    switch (env?.toLowerCase()) {
      case 'production':
        environment = Environment.production;
        break;
      case 'staging':
        environment = Environment.staging;
        break;
      default:
        environment = Environment.development;
    }
  }
}
