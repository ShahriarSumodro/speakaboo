/// User profile model matching backend /api/auth/profile.
library;

class UserProfile {
  final String userId;
  final String displayName;
  final String ageBand; // 'kid', 'teen', 'adult'
  final String goal;
  final String level; // 'beginner', 'intermediate', 'advanced'
  final int dailyGoalMinutes;
  final String reminderTime; // 'HH:MM'
  final String theme; // 'system', 'light', 'dark'
  final bool hasParentPin;
  final String createdAt;
  final String updatedAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.ageBand,
    required this.goal,
    required this.level,
    required this.dailyGoalMinutes,
    required this.reminderTime,
    required this.theme,
    required this.hasParentPin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? 'Learner',
      ageBand: json['age_band'] ?? 'adult',
      goal: json['goal'] ?? 'Daily Speaking Practice',
      level: json['level'] ?? 'beginner',
      dailyGoalMinutes: json['daily_goal_minutes'] ?? 10,
      reminderTime: json['reminder_time'] ?? '20:00',
      theme: json['theme'] ?? 'system',
      hasParentPin: json['has_parent_pin'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'age_band': ageBand,
      'goal': goal,
      'level': level,
      'daily_goal_minutes': dailyGoalMinutes,
      'reminder_time': reminderTime,
      'theme': theme,
      'has_parent_pin': hasParentPin,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? ageBand,
    String? goal,
    String? level,
    int? dailyGoalMinutes,
    String? reminderTime,
    String? theme,
    bool? hasParentPin,
  }) {
    return UserProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      ageBand: ageBand ?? this.ageBand,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      theme: theme ?? this.theme,
      hasParentPin: hasParentPin ?? this.hasParentPin,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
