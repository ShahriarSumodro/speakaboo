/// Speakaboo App Configuration
///
/// Centralized configuration constants.
library;

class AppConfig {
  AppConfig._();

  /// Backend URL - uses compile-time env or defaults to Android emulator host
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// App name
  static const String appName = 'Speakaboo';

  /// App version
  static const String appVersion = '0.1.0';

  /// Audio recording settings
  static const int sampleRate = 16000;
  static const int maxRecordingSeconds = 30;

  /// Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration requestTimeout = Duration(seconds: 15);
}
