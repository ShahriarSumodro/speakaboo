/// Character model matching backend /api/characters.
library;

class Character {
  final String id;
  final String name;
  final String tagline;
  final String voiceId;
  final String personalityPrompt;
  final String speakingStyle;
  final String vocabularyFocus;
  final bool isFree;
  final int priceBdt;
  final String avatarUrl;
  final List<String> personalityTraits;
  final List<String> sampleLines;
  final String bestFor;

  Character({
    required this.id,
    required this.name,
    required this.tagline,
    required this.voiceId,
    required this.personalityPrompt,
    required this.speakingStyle,
    required this.vocabularyFocus,
    required this.isFree,
    required this.priceBdt,
    required this.avatarUrl,
    required this.personalityTraits,
    required this.sampleLines,
    required this.bestFor,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      tagline: json['tagline'] ?? '',
      voiceId: json['voice_id'] ?? '',
      personalityPrompt: json['personality_prompt'] ?? '',
      speakingStyle: json['speaking_style'] ?? '',
      vocabularyFocus: json['vocabulary_focus'] ?? '',
      isFree: json['is_free'] ?? false,
      priceBdt: json['price_bdt'] ?? 0,
      avatarUrl: json['avatar_url'] ?? '',
      personalityTraits: List<String>.from(json['personality_traits'] ?? []),
      sampleLines: List<String>.from(json['sample_lines'] ?? []),
      bestFor: json['best_for'] ?? 'All learners',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'voice_id': voiceId,
      'personality_prompt': personalityPrompt,
      'speaking_style': speakingStyle,
      'vocabulary_focus': vocabularyFocus,
      'is_free': isFree,
      'price_bdt': priceBdt,
      'avatar_url': avatarUrl,
      'personality_traits': personalityTraits,
      'sample_lines': sampleLines,
      'best_for': bestFor,
    };
  }
}
