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

class ConversationHint {
  final String conversationId;
  final String sentenceStarter;
  final String modelAnswer;
  final List<String> vocabularyHints;

  ConversationHint({
    required this.conversationId,
    required this.sentenceStarter,
    required this.modelAnswer,
    required this.vocabularyHints,
  });

  factory ConversationHint.fromJson(Map<String, dynamic> json) {
    return ConversationHint(
      conversationId: json['conversation_id'] ?? '',
      sentenceStarter: json['sentence_starter'] ?? '',
      modelAnswer: json['model_answer'] ?? '',
      vocabularyHints: List<String>.from(json['vocabulary_hints'] ?? []),
    );
  }
}

class SessionSummary {
  final String conversationId;
  final int turnCount;
  final double learnerTalkTimeSeconds;
  final double botTalkTimeSeconds;
  final double talkTimeRatio;
  final double wpm;
  final double averageTurnLengthWords;
  final int clarityScore;
  final String clarityLabel;
  final String clarityNote;
  final List<String> strengths;
  final List<String> patternsToWorkOn;
  final String concreteNextStep;
  final List<Map<String, dynamic>> sayThisBetter;
  final String tomorrowHook;

  SessionSummary({
    required this.conversationId,
    required this.turnCount,
    required this.learnerTalkTimeSeconds,
    required this.botTalkTimeSeconds,
    required this.talkTimeRatio,
    required this.wpm,
    required this.averageTurnLengthWords,
    required this.clarityScore,
    required this.clarityLabel,
    required this.clarityNote,
    required this.strengths,
    required this.patternsToWorkOn,
    required this.concreteNextStep,
    required this.sayThisBetter,
    required this.tomorrowHook,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    final clarity = json['clarity_indicator'] as Map<String, dynamic>? ?? {};
    return SessionSummary(
      conversationId: json['conversation_id'] ?? '',
      turnCount: json['turn_count'] ?? 0,
      learnerTalkTimeSeconds: (json['learner_talk_time_seconds'] ?? 0).toDouble(),
      botTalkTimeSeconds: (json['bot_talk_time_seconds'] ?? 0).toDouble(),
      talkTimeRatio: (json['talk_time_ratio'] ?? 0).toDouble(),
      wpm: (json['wpm'] ?? 0).toDouble(),
      averageTurnLengthWords: (json['average_turn_length_words'] ?? 0).toDouble(),
      clarityScore: clarity['score'] ?? 80,
      clarityLabel: clarity['label'] ?? 'Approximate Clarity',
      clarityNote: clarity['note'] ?? 'Approximate estimate based on speech-to-text confidence and phrasing cadence.',
      strengths: List<String>.from(json['strengths'] ?? []),
      patternsToWorkOn: List<String>.from(json['patterns_to_work_on'] ?? []),
      concreteNextStep: json['concrete_next_step'] ?? '',
      sayThisBetter: (json['say_this_better'] as List<dynamic>?)
              ?.map((c) => Map<String, dynamic>.from(c as Map))
              .toList() ??
          [],
      tomorrowHook: json['tomorrow_hook'] ?? '',
    );
  }
}

class PlacementResult {
  final String userId;
  final String level;
  final String cefrLevel;
  final double cefrScore;
  final double wpm;
  final double vocabularyVariety;
  final String summary;
  final List<String> strengths;
  final List<String> recommendations;

  PlacementResult({
    required this.userId,
    required this.level,
    required this.cefrLevel,
    required this.cefrScore,
    required this.wpm,
    required this.vocabularyVariety,
    required this.summary,
    required this.strengths,
    required this.recommendations,
  });

  factory PlacementResult.fromJson(Map<String, dynamic> json) {
    return PlacementResult(
      userId: json['user_id'] ?? '',
      level: json['level'] ?? 'beginner',
      cefrLevel: json['cefr_level'] ?? 'A1',
      cefrScore: (json['cefr_score'] ?? 1.0).toDouble(),
      wpm: (json['wpm'] ?? 0).toDouble(),
      vocabularyVariety: (json['vocabulary_variety'] ?? 0).toDouble(),
      summary: json['summary'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class MistakeLogItem {
  final String id;
  final String category;
  final String original;
  final String better;
  final int count;
  final double lastSeenAt;

  MistakeLogItem({
    required this.id,
    required this.category,
    required this.original,
    required this.better,
    required this.count,
    required this.lastSeenAt,
  });

  factory MistakeLogItem.fromJson(Map<String, dynamic> json) {
    return MistakeLogItem(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      original: json['original'] ?? '',
      better: json['better'] ?? '',
      count: json['count'] ?? 1,
      lastSeenAt: (json['last_seen_at'] ?? 0).toDouble(),
    );
  }
}
