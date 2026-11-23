/// Parent summary & safety models.
library;

class SafetyFlag {
  final String timestamp;
  final String reason;
  final String severity; // 'low', 'medium', 'high'
  final String utterancePreview;

  SafetyFlag({
    required this.timestamp,
    required this.reason,
    required this.severity,
    required this.utterancePreview,
  });

  factory SafetyFlag.fromJson(Map<String, dynamic> json) {
    return SafetyFlag(
      timestamp: json['timestamp'] ?? '',
      reason: json['reason'] ?? 'Content warning',
      severity: json['severity'] ?? 'low',
      utterancePreview: json['utterance_preview'] ?? '',
    );
  }
}

class ParentSummary {
  final String userId;
  final double weeklyMinutes;
  final int totalWords;
  final int currentStreak;
  final List<double> accuracyTrend;
  final int safetyFlagsCount;
  final List<String> topicsPracticed;
  final bool weeklyGoalMet;
  final List<String> tips;

  ParentSummary({
    required this.userId,
    required this.weeklyMinutes,
    required this.totalWords,
    required this.currentStreak,
    required this.accuracyTrend,
    required this.safetyFlagsCount,
    required this.topicsPracticed,
    required this.weeklyGoalMet,
    required this.tips,
  });

  factory ParentSummary.fromJson(Map<String, dynamic> json) {
    return ParentSummary(
      userId: json['user_id'] ?? '',
      weeklyMinutes: (json['weekly_minutes'] ?? 0).toDouble(),
      totalWords: json['total_words'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      accuracyTrend: (json['accuracy_trend'] as List<dynamic>?)
              ?.map((a) => (a as num).toDouble())
              .toList() ??
          [],
      safetyFlagsCount: json['safety_flags_count'] ?? 0,
      topicsPracticed: List<String>.from(json['topics_practiced'] ?? []),
      weeklyGoalMet: json['weekly_goal_met'] ?? false,
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}
