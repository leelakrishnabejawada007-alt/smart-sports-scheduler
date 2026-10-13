import 'package:flutter/foundation.dart';

/// Backend settings.
///   Default:   talks to the Python/SQLite server in /backend
///   Offline:   flutter run --dart-define=USE_MOCK=true
///   Other URL: flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // The Android emulator reaches the host machine at 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }
}
