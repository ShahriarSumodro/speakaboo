/// Persistent authentication storage using shared_preferences.
library;

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _keyDeviceId = 'speakaboo_device_id';
  static const String _keyUserId = 'speakaboo_user_id';
  static const String _keyAuthToken = 'speakaboo_auth_token';
  static const String _keyDisplayName = 'speakaboo_display_name';

  static String? _cachedDeviceId;
  static String? _cachedUserId;
  static String? _cachedAuthToken;

  /// Get or create a unique persistent device ID.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      id = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_keyDeviceId, id);
    }
    _cachedDeviceId = id;
    return id;
  }

  /// Get stored user ID.
  static Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_keyUserId);
    return _cachedUserId;
  }

  /// Get stored auth token.
  static Future<String?> getAuthToken() async {
    if (_cachedAuthToken != null) return _cachedAuthToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedAuthToken = prefs.getString(_keyAuthToken);
    return _cachedAuthToken;
  }

  /// Save session credentials after device registration.
  static Future<void> saveAuth({
    required String userId,
    required String authToken,
    String? displayName,
  }) async {
    _cachedUserId = userId;
    _cachedAuthToken = authToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyAuthToken, authToken);
    if (displayName != null) {
      await prefs.setString(_keyDisplayName, displayName);
    }
  }

  /// Clear all stored credentials (for data wipe or account switch).
  static Future<void> clear() async {
    _cachedUserId = null;
    _cachedAuthToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyDisplayName);
  }
}
