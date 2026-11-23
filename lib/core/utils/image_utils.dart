import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';

class ImageUtils {
  /// Resolves any relative, localhost, or misconfigured image URL to a fully-qualified valid URL.
  static String? resolveImageUrl(String? url) {
    if (url == null) return null;
    var trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    // 0. If already proxied via wsrv.nl, data URI, or blob, DO NOT wrap again!
    if (trimmed.contains('wsrv.nl') || trimmed.startsWith('data:image') || trimmed.startsWith('blob:')) {
      return trimmed;
    }

    // 1. Double slash protocol-relative URL
    if (trimmed.startsWith('//')) {
      trimmed = 'https:$trimmed';
    }

    // 2. Relative storage or assets path
    if (trimmed.startsWith('/')) {
      trimmed = '${AppConfig.baseServerUrl}$trimmed';
    } else if (trimmed.startsWith('storage/')) {
      trimmed = '${AppConfig.baseServerUrl}/$trimmed';
    }

    // 3. Normalize localhost / 127.0.0.1 to current baseServerUrl if not development
    if (AppConfig.environment != Environment.development) {
      if (trimmed.contains('127.0.0.1:8000')) {
        trimmed = trimmed.replaceFirst('http://127.0.0.1:8000', AppConfig.baseServerUrl);
      } else if (trimmed.contains('localhost:8000')) {
        trimmed = trimmed.replaceFirst('http://localhost:8000', AppConfig.baseServerUrl);
      } else if (trimmed.contains('127.0.0.1')) {
        trimmed = trimmed.replaceFirst('http://127.0.0.1', AppConfig.baseServerUrl);
      } else if (trimmed.contains('localhost')) {
        trimmed = trimmed.replaceFirst('http://localhost', AppConfig.baseServerUrl);
      }
    }

    // 4. Force HTTPS in staging / production
    if (AppConfig.environment != Environment.development && trimmed.startsWith('http://')) {
      trimmed = trimmed.replaceFirst('http://', 'https://');
    }

    // 5. If running on Flutter Web (kIsWeb) and accessing test.intirasolusi.id or external storage,
    // browser CanvasKit blocks cross-origin images without CORS headers.
    // Proxying through wsrv.nl provides instant Access-Control-Allow-Origin: * for seamless web testing.
    // On native Android/iOS (in APK), kIsWeb is false, so it loads directly from server.
    if (kIsWeb && (trimmed.startsWith('http://') || trimmed.startsWith('https://'))) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(trimmed)}';
    }

    return trimmed;
  }
}
