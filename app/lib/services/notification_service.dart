/// Local notification & habit reminder service for Speakaboo.
///
/// Implements gentle, frequency-capped daily practice triggers at the user's chosen time.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _prefEnabledKey = 'daily_reminders_enabled';
  static const String _prefTimeKey = 'daily_reminder_time';
  static const String _prefLastNotifDateKey = 'last_notif_date';

  static final List<Map<String, String>> _reminderTemplates = [
    {
      'character': 'rule_farmer',
      'title': 'Time for your 2-minute talk with Reggie! 🌾',
      'body': 'Keep your speaking streak alive! Reggie is waiting at the farmhouse.',
    },
    {
      'character': 'kabir_chowdhury',
      'title': 'Kabir found a new clue! 🔍',
      'body': 'A mystery is unfolding in Old Dhaka. Speak for 2 minutes to crack the case!',
    },
    {
      'character': 'professor_anika',
      'title': 'Word of the day is waiting 🎓',
      'body': 'Professor Anika has prepared a fresh conversation topic for you today.',
    },
  ];

  /// Check if daily reminders are enabled.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabledKey) ?? true;
  }

  /// Enable or disable daily practice reminders.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, enabled);
  }

  /// Get scheduled reminder time (HH:mm, default 20:00).
  static Future<String> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefTimeKey) ?? '20:00';
  }

  /// Set scheduled reminder time (HH:mm).
  static Future<void> setReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTimeKey, time);
  }

  /// Check if today's reminder should fire (frequency capped to 1 per day).
  static Future<bool> shouldNotifyToday() async {
    final enabled = await isEnabled();
    if (!enabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_prefLastNotifDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return lastDate != today;
  }

  /// Mark reminder as delivered today.
  static Future<void> markDeliveredToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefLastNotifDateKey, today);
  }

  /// Get companion-specific reminder message.
  static Map<String, String> getReminderCopy(String characterId) {
    for (final t in _reminderTemplates) {
      if (t['character'] == characterId) return t;
    }
    return _reminderTemplates.first;
  }
}
