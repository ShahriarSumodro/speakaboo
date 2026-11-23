/// Learning models: Missions, Streak, Progress, Scenarios, Topics, Shadowing, Vocabulary.
library;

class Mission {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int target;
  final int progress;
  final bool completed;
  final bool claimed;
  final String category;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.target,
    required this.progress,
    required this.completed,
    required this.claimed,
    required this.category,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      xpReward: json['xp_reward'] ?? 0,
      target: json['target'] ?? 1,
      progress: json['progress'] ?? 0,
      completed: json['completed'] ?? false,
      claimed: json['claimed'] ?? false,
      category: json['category'] ?? 'practice',
    );
  }

  Mission copyWith({
    int? progress,
    bool? completed,
    bool? claimed,
  }) {
    return Mission(
      id: id,
      title: title,
      description: description,
      xpReward: xpReward,
      target: target,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
      category: category,
    );
  }
}

class MissionsResponse {
  final String date;
  final List<Mission> missions;
  final int streak;
  final int freezes;

  MissionsResponse({
    required this.date,
    required this.missions,
    required this.streak,
    required this.freezes,
  });

  factory MissionsResponse.fromJson(Map<String, dynamic> json) {
    return MissionsResponse(
      date: json['date'] ?? '',
      missions: (json['missions'] as List<dynamic>?)
              ?.map((m) => Mission.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      streak: json['streak'] ?? 0,
      freezes: json['freezes'] ?? 0,
    );
  }
}

class LearningProgress {
  final String userId;
  final String level;
  final int xp;
  final int totalWordsSpoken;
  final int streakDays;
  final double weeklyMinutes;
  final double accuracyScore;

  LearningProgress({
    required this.userId,
    required this.level,
    required this.xp,
    required this.totalWordsSpoken,
    required this.streakDays,
    required this.weeklyMinutes,
    required this.accuracyScore,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      userId: json['user_id'] ?? '',
      level: json['level'] ?? 'beginner',
      xp: json['xp'] ?? 0,
      totalWordsSpoken: json['total_words_spoken'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      weeklyMinutes: (json['weekly_minutes'] ?? 0).toDouble(),
      accuracyScore: (json['accuracy_score'] ?? 0).toDouble(),
    );
  }
}

class ScenarioItem {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String description;
  final List<String> roles;
  final List<String> goals;

  ScenarioItem({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.roles,
    required this.goals,
  });

  factory ScenarioItem.fromJson(Map<String, dynamic> json) {
    return ScenarioItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      description: json['description'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      goals: List<String>.from(json['goals'] ?? []),
    );
  }
}

class TopicItem {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final List<String> starters;

  TopicItem({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.starters,
  });

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    return TopicItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      starters: List<String>.from(json['starters'] ?? []),
    );
  }
}

class ShadowingItem {
  final String id;
  final String title;
  final String difficulty;
  final String targetText;
  final String referenceAudioUrl;
  final List<double> speedOptions;

  ShadowingItem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.targetText,
    required this.referenceAudioUrl,
    required this.speedOptions,
  });

  factory ShadowingItem.fromJson(Map<String, dynamic> json) {
    return ShadowingItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      targetText: json['target_text'] ?? '',
      referenceAudioUrl: json['reference_audio_url'] ?? '',
      speedOptions: (json['speed_options'] as List<dynamic>?)
              ?.map((s) => (s as num).toDouble())
              .toList() ??
          [0.8, 1.0, 1.2],
    );
  }
}

class VocabCard {
  final String id;
  final String word;
  final String definition;
  final String example;
  final int box;
  final String nextReview;
  final bool mastered;
  final double easeFactor;
  final int repetitions;

  VocabCard({
    required this.id,
    required this.word,
    required this.definition,
    required this.example,
    required this.box,
    required this.nextReview,
    required this.mastered,
    required this.easeFactor,
    required this.repetitions,
  });

  factory VocabCard.fromJson(Map<String, dynamic> json) {
    return VocabCard(
      id: json['id'] ?? '',
      word: json['word'] ?? '',
      definition: json['definition'] ?? '',
      example: json['example'] ?? '',
      box: json['box'] ?? 1,
      nextReview: json['next_review'] ?? '',
      mastered: json['mastered'] ?? false,
      easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
      repetitions: json['repetitions'] ?? 0,
    );
  }
}
