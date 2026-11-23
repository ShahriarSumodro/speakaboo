/// Analytics and error reporting client service for Speakaboo mobile app.
library;

import 'dart:developer' as developer;

class AnalyticsEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  AnalyticsEvent({
    required this.name,
    required this.timestamp,
    this.properties = const {},
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final List<AnalyticsEvent> _events = [];
  final List<Map<String, dynamic>> _errorLog = [];

  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  List<Map<String, dynamic>> get errorLog => List.unmodifiable(_errorLog);

  /// Track product engagement event.
  void track(String eventName, [Map<String, dynamic>? properties]) {
    final event = AnalyticsEvent(
      name: eventName,
      timestamp: DateTime.now(),
      properties: properties ?? {},
    );
    _events.add(event);
    if (_events.length > 200) {
      _events.removeAt(0);
    }
    developer.log('📊 [Analytics] $eventName: $properties');
  }

  /// Record an unexpected error or crash.
  void recordError(Object error, StackTrace? stackTrace, {String? context}) {
    final report = {
      'error': error.toString(),
      'stack': stackTrace?.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _errorLog.add(report);
    if (_errorLog.length > 50) {
      _errorLog.removeAt(0);
    }
    developer.log('💥 [CrashReporter] $error (context=$context)');
  }

  /// Clear events (for testing).
  void clear() {
    _events.clear();
    _errorLog.clear();
  }
}
