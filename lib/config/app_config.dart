import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  static Environment environment = Environment.staging;
  
  // Custom API URL override via --dart-define=API_URL=http://...
  static const String _customApiUrl = String.fromEnvironment('API_URL', defaultValue: '');

  static String get baseUrl {
    // 1. If explicit API_URL is provided, prioritize it
    if (_customApiUrl.isNotEmpty) {
      return _customApiUrl;
    }

    // 2. Otherwise determine by environment
    switch (environment) {
      case Environment.development:
        if (kIsWeb) {
          return 'http://127.0.0.1:8000/api';
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          // Android Emulator routes 10.0.2.2 to host machine localhost:8000
          return 'http://10.0.2.2:8000/api';
        } else {
          return 'http://127.0.0.1:8000/api';
        }
      case Environment.staging:
        return 'https://test.intirasolusi.id/api';
      case Environment.production:
        return 'https://intirasolusi.id/api';
    }
  }

  static String get baseServerUrl {
    switch (environment) {
      case Environment.development:
        return 'http://127.0.0.1:8000';
      case Environment.staging:
        return 'https://test.intirasolusi.id';
      case Environment.production:
        return 'https://intirasolusi.id';
    }
  }

  static String get appName => 'GASPOL by INTIRA';

  static void setEnvironment(Environment env) {
    environment = env;
  }

  static void setFromString(String? env) {
    switch (env?.toLowerCase()) {
      case 'production':
      case 'prod':
        environment = Environment.production;
        break;
      case 'staging':
      case 'test':
      case 'testing':
        environment = Environment.staging;
        break;
      case 'development':
      case 'dev':
        environment = Environment.development;
        break;
      default:
        environment = Environment.staging;
    }
  }
}
