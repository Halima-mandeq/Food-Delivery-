import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _webApiBaseUrl =
      'http://127.0.0.1/food%20delivery/backend/api';
  static const String _defaultDeviceApiBaseUrl =
      'http://10.0.2.2/food%20delivery/backend/api';

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(_apiBaseUrlOverride);
    }

    if (kIsWeb) {
      return _webApiBaseUrl;
    }

    return _defaultDeviceApiBaseUrl;
  }

  static String get backendBaseUrl => apiBaseUrl.replaceAll('/api', '');

  static String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }
}
