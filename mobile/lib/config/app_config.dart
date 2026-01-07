import 'package:flutter/foundation.dart';

class AppConfig {
  static String get backendBaseUrl {
    const override = String.fromEnvironment('BACKEND_BASE_URL');
    if (override.isNotEmpty) {
      final trimmed = override.trim();
      if (trimmed.startsWith('ttps://')) {
        return 'h$trimmed';
      }
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }
      return 'https://$trimmed';
    }

    if (kIsWeb) {
      return 'http://localhost:4000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:4000';
      default:
        return 'http://localhost:4000';
    }
  }
}
