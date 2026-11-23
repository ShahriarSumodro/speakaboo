/// Usage and daily quota model.
library;

class UsageInfo {
  final String userId;
  final double dailyMinutesUsed;
  final double dailyMinutesLimit;
  final int turnsToday;
  final String plan;
  final bool isCapped;

  UsageInfo({
    required this.userId,
    required this.dailyMinutesUsed,
    required this.dailyMinutesLimit,
    required this.turnsToday,
    required this.plan,
    required this.isCapped,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      userId: json['user_id'] ?? '',
      dailyMinutesUsed: (json['daily_minutes_used'] ?? 0).toDouble(),
      dailyMinutesLimit: (json['daily_minutes_limit'] ?? 10).toDouble(),
      turnsToday: json['turns_today'] ?? 0,
      plan: json['plan'] ?? 'free',
      isCapped: json['is_capped'] ?? false,
    );
  }
}
