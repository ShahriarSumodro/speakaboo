/// Speakaboo App Configuration
///
/// Centralized configuration constants and runtime settings.
library;

import 'package:shared_preferences/shared_preferences.dart';

enum AppFlavor {
  /// Google Play distribution (only policy-compliant Google Play Billing allowed)
  play,

  /// Direct distribution outside Play (e.g. website, APK with bKash/Nagad)
  direct,
}

class AppConfig {
  AppConfig._();

  static const String _storageKey = 'custom_backend_url';

  /// Compile-time build flavor: 'play' (default) or 'direct'
  static AppFlavor flavor = () {
    const flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'play');
    return flavorStr.toLowerCase() == 'direct' ? AppFlavor.direct : AppFlavor.play;
  }();

  static bool get isPlayFlavor => flavor == AppFlavor.play;
  static bool get isDirectFlavor => flavor == AppFlavor.direct;

  /// Compile-time default backend URL - defaults to http://localhost:8000 for USB dev with adb reverse
  static const String defaultBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Emulator fallback URL
  static const String emulatorBackendUrl = 'http://10.0.2.2:8000';

  static String _activeBackendUrl = defaultBackendUrl;

  /// Current backend URL (either runtime-configured or default)
  static String get backendUrl => _activeBackendUrl;

  /// Whether custom URL is set
  static bool get isCustomBackendUrl => _activeBackendUrl != defaultBackendUrl;

  /// Initialize config from persistent storage
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _activeBackendUrl = saved.trim();
      }
    } catch (_) {
      // Fallback silently to defaultBackendUrl if SharedPreferences is not ready (e.g. in test env)
      _activeBackendUrl = defaultBackendUrl;
    }
  }

  /// Update backend URL at runtime (e.g. via Dev Server Dialog)
  static Future<void> setBackendUrl(String url) async {
    final cleaned = url.trim();
    if (cleaned.isEmpty) return;
    _activeBackendUrl = cleaned;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, cleaned);
    } catch (_) {}
  }

  /// Reset to compile-time default URL
  static Future<void> resetBackendUrl() async {
    _activeBackendUrl = defaultBackendUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// App name
  static const String appName = 'Speakaboo';

  /// App version
  static const String appVersion = '0.2.0';

  /// Audio recording settings
  static const int sampleRate = 16000;
  static const int maxRecordingSeconds = 30;

  /// Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration requestTimeout = Duration(seconds: 15);
}
