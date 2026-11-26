/// Persistent three-way theme controller (Light / Dark / System).
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'speakaboo_theme_mode';

  String _selection = 'system';

  String get selection => _selection;

  ThemeMode get themeMode {
    switch (_selection) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'light' || saved == 'dark' || saved == 'system') {
        if (saved != _selection) {
          _selection = saved!;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[ThemeController] load error: $e');
    }
  }

  Future<void> setTheme(String mode) async {
    final normalized = (mode == 'light' || mode == 'dark') ? mode : 'system';
    if (_selection == normalized) return;
    _selection = normalized;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, normalized);
    } catch (e) {
      debugPrint('[ThemeController] save error: $e');
    }
  }

  void syncFromProfile(String? profileTheme) {
    if (profileTheme == 'light' || profileTheme == 'dark' || profileTheme == 'system') {
      if (profileTheme != _selection) {
        setTheme(profileTheme!);
      }
    }
  }
}
