/// Offline caching service for rapid screen rendering.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final Map<String, dynamic> _memoryCache = {};

  /// Save a JSON encodable object or list to cache.
  static Future<void> set(String key, dynamic data) async {
    _memoryCache[key] = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_$key', jsonEncode(data));
    } catch (e) {
      debugPrint('[cache_service] ignored error: $e');
    }
  }

  /// Get cached data from memory first, then disk.
  static Future<dynamic> get(String key) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_$key');
      if (raw != null) {
        final decoded = jsonDecode(raw);
        _memoryCache[key] = decoded;
        return decoded;
      }
    } catch (e) {
      debugPrint('[cache_service] ignored error: $e');
    }
    return null;
  }

  /// Clear a specific cache entry.
  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (e) {
      debugPrint('[cache_service] ignored error: $e');
    }
  }

  /// Invalidate all caches.
  static Future<void> clear() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('[cache_service] ignored error: $e');
    }
  }
}
