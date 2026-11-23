/// Complete typed API service for Speakaboo backend communication.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/character.dart';
import '../models/learning_models.dart';
import '../models/parent_summary.dart';
import '../models/usage_info.dart';
import '../models/payment_models.dart';

/// Result of a conversation turn from the backend.
class TurnResult {
  final String conversationId;
  final String turnId;
  final String userTranscript;
  final String reply;
  final CorrectionData? correction;
  final List<String> newWords;
  final List<Uint8List> audioChunks;
  final String level;
  final double latencyMs;
  final bool safetyBlocked;

  TurnResult({
    required this.conversationId,
    required this.turnId,
    required this.userTranscript,
    required this.reply,
    this.correction,
    this.newWords = const [],
    this.audioChunks = const [],
    required this.level,
    required this.latencyMs,
    this.safetyBlocked = false,
  });

  factory TurnResult.fromJson(Map<String, dynamic> json) {
    return TurnResult(
      conversationId: json['conversation_id'] ?? '',
      turnId: json['turn_id'] ?? '',
      userTranscript: json['user_transcript'] ?? '',
      reply: json['reply'] ?? '',
      correction: json['correction'] != null
          ? CorrectionData.fromJson(json['correction'])
          : null,
      newWords: List<String>.from(json['new_words'] ?? []),
      audioChunks: (json['audio_base64'] as List<dynamic>?)
              ?.map((b64) => base64Decode(b64 as String))
              .toList() ??
          [],
      level: json['level'] ?? 'beginner',
      latencyMs: (json['latency_ms'] ?? 0).toDouble(),
      safetyBlocked: json['safety_blocked'] ?? false,
    );
  }
}

/// Correction data from the AI.
class CorrectionData {
  final String original;
  final String better;
  final String reasonShort;

  CorrectionData({
    required this.original,
    required this.better,
    required this.reasonShort,
  });

  factory CorrectionData.fromJson(Map<String, dynamic> json) {
    return CorrectionData(
      original: json['original'] ?? '',
      better: json['better'] ?? '',
      reasonShort: json['reason_short'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'better': better,
      'reason_short': reasonShort,
    };
  }
}

/// Start conversation response.
class StartConversationResult {
  final String conversationId;
  final String characterName;
  final String greeting;

  StartConversationResult({
    required this.conversationId,
    required this.characterName,
    required this.greeting,
  });

  factory StartConversationResult.fromJson(Map<String, dynamic> json) {
    return StartConversationResult(
      conversationId: json['conversation_id'] ?? '',
      characterName: json['character_name'] ?? '',
      greeting: json['greeting'] ?? '',
    );
  }
}

/// Complete API client for the Speakaboo backend.
class ApiService {
  final String? _customBaseUrl;
  final http.Client _client;
  String? _authToken;

  ApiService({String? baseUrl, http.Client? client, String? authToken})
      : _customBaseUrl = baseUrl,
        _client = client ?? http.Client(),
        _authToken = authToken;

  String get baseUrl => _customBaseUrl ?? AppConfig.backendUrl;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _headers([Map<String, String>? extra]) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) {
      map.addAll(extra);
    }
    return map;
  }

  // ================= HEALTH =================

  /// Check backend health.
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/health'))
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Health check failed', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  // ================= AUTH & PROFILE =================

  /// Authenticate device and obtain signed JWT/HMAC token.
  Future<Map<String, dynamic>> deviceAuth({
    required String deviceId,
    String? displayName,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/device'),
          headers: _headers(),
          body: jsonEncode({
            'device_id': deviceId,
            if (displayName != null) 'display_name': displayName,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Device authentication failed', response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['auth_token'] != null) {
      setAuthToken(data['auth_token']);
    }
    return data;
  }

  /// Get current user profile.
  Future<UserProfile> getProfile() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/auth/profile'),
          headers: _headers(),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load profile', response.statusCode);
    }
    return UserProfile.fromJson(jsonDecode(response.body));
  }

  /// Update current user profile.
  Future<UserProfile> updateProfile(Map<String, dynamic> updates) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/auth/profile'),
          headers: _headers(),
          body: jsonEncode(updates),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to update profile', response.statusCode);
    }
    return UserProfile.fromJson(jsonDecode(response.body));
  }

  /// Set 4-digit parent PIN.
  Future<bool> setParentPin(String pin) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/set-parent-pin'),
          headers: _headers(),
          body: jsonEncode({'pin': pin}),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to set parent PIN', response.statusCode);
    }
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  /// Verify 4-digit parent PIN.
  Future<bool> verifyParentPin(String pin) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/verify-parent-pin'),
          headers: _headers(),
          body: jsonEncode({'pin': pin}),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to verify parent PIN', response.statusCode);
    }
    final data = jsonDecode(response.body);
    return data['valid'] == true;
  }

  // ================= CHARACTERS =================

  /// Get all speaking characters.
  Future<List<Character>> getCharacters() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/characters/'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load characters', response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((item) => Character.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get single character details.
  Future<Character> getCharacter(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/characters/$id'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Character not found', response.statusCode);
    }
    return Character.fromJson(jsonDecode(response.body));
  }

  /// Get cached voice preview audio.
  Future<Uint8List> getPreviewAudio(String characterId) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/characters/$characterId/preview-audio'),
          headers: _headers({'Accept': 'audio/wav'}),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Preview audio not available', response.statusCode);
    }
    return response.bodyBytes;
  }

  // ================= CONVERSATION =================

  /// Start a conversation with a character.
  Future<StartConversationResult> startConversation({
    required String userId,
    required String characterId,
    String? scenarioId,
    String? topicId,
    String? practiceMode,
    String? coachMode,
    String? ageBand,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/conversation/start'),
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'character_id': characterId,
            if (scenarioId != null) 'scenario_id': scenarioId,
            if (topicId != null) 'topic_id': topicId,
            if (practiceMode != null) 'practice_mode': practiceMode,
            if (coachMode != null) 'coach_mode': coachMode,
            if (ageBand != null) 'age_band': ageBand,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to start conversation', response.statusCode);
    }
    return StartConversationResult.fromJson(jsonDecode(response.body));
  }

  /// Get sentence starter, model answer, and vocabulary hint for active conversation.
  Future<ConversationHint> getConversationHint(String conversationId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/conversation/hint'),
          headers: _headers(),
          body: jsonEncode({'conversation_id': conversationId}),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load hint', response.statusCode);
    }
    return ConversationHint.fromJson(jsonDecode(response.body));
  }

  /// Get end-of-session summary, talk-time ratio, clarity indicator, and tomorrow hook.
  Future<SessionSummary> getConversationSummary(String conversationId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/conversation/summary'),
          headers: _headers(),
          body: jsonEncode({'conversation_id': conversationId}),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load session summary', response.statusCode);
    }
    return SessionSummary.fromJson(jsonDecode(response.body));
  }

  /// Submit spoken placement test diagnostic and update user level.
  Future<PlacementResult> submitPlacementTest({
    required String userId,
    required String spokenText,
    double durationSeconds = 30.0,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/conversation/placement'),
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'spoken_text': spokenText,
            'duration_seconds': durationSeconds,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to submit placement test', response.statusCode);
    }
    return PlacementResult.fromJson(jsonDecode(response.body));
  }

  /// Get mistake logs and recurring error categories for learner.
  Future<List<MistakeLogItem>> getMistakeLogs(String userId) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/conversation/mistakes/$userId'),
          headers: _headers(),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load mistake logs', response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((m) => MistakeLogItem.fromJson(m as Map<String, dynamic>)).toList();
  }

  /// Send an audio turn and get the AI response (blocking fallback).
  Future<TurnResult> sendTurn({
    required String conversationId,
    required Uint8List audio,
    String audioFormat = 'wav',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/conversation/turn'),
    );

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.fields['conversation_id'] = conversationId;
    request.fields['audio_format'] = audioFormat;
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      audio,
      filename: 'recording.$audioFormat',
    ));

    final streamedResponse =
        await _client.send(request).timeout(AppConfig.requestTimeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 429) {
      throw ApiException(
        'Our AI is busy. Please try again in a moment.',
        429,
        retryable: true,
      );
    }

    if (response.statusCode != 200) {
      String detailMsg = 'Failed to process turn';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] != null) {
          detailMsg = body['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(
        detailMsg,
        response.statusCode,
      );
    }

    return TurnResult.fromJson(jsonDecode(response.body));
  }

  /// Stream a conversation turn with early transcript and sentence-by-sentence audio (SSE).
  Stream<Map<String, dynamic>> streamTurn({
    required String conversationId,
    required Uint8List audio,
    String audioFormat = 'wav',
  }) async* {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/conversation/stream-turn'),
    );

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.fields['conversation_id'] = conversationId;
    request.fields['audio_format'] = audioFormat;
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      audio,
      filename: 'recording.$audioFormat',
    ));

    final streamedResponse =
        await _client.send(request).timeout(AppConfig.requestTimeout);

    if (streamedResponse.statusCode != 200) {
      final res = await http.Response.fromStream(streamedResponse);
      throw ApiException('Stream turn failed: ${res.body}', streamedResponse.statusCode);
    }

    // Parse SSE lines
    final lineStream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isNotEmpty) {
          try {
            final data = jsonDecode(jsonStr);
            if (data is Map<String, dynamic>) {
              yield data;
            }
          } catch (_) {}
        }
      }
    }
  }

  // ================= LEARNING & GAMIFICATION =================

  /// Get streak status.
  Future<Map<String, dynamic>> getStreak(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/streak/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load streak', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Use streak freeze.
  Future<Map<String, dynamic>> freezeStreak() async {
    final response = await _client
        .post(Uri.parse('$baseUrl/api/learning/streak/freeze'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to freeze streak', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Repair broken streak after a recovery activity.
  Future<Map<String, dynamic>> repairStreak(String userId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/learning/streak/repair'),
          headers: _headers(),
          body: jsonEncode({'user_id': userId}),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to repair streak', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Get daily word of the day with pronunciation and Bengali meaning.
  Future<WordOfTheDay> getWordOfTheDay() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/word-of-the-day'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load word of the day', response.statusCode);
    }
    return WordOfTheDay.fromJson(jsonDecode(response.body));
  }

  /// Get 7-day speaking minutes, words learned, streak, and milestones.
  Future<WeeklyRecap> getWeeklyRecap(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/weekly-recap/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load weekly recap', response.statusCode);
    }
    return WeeklyRecap.fromJson(jsonDecode(response.body));
  }

  /// Get user referral code and reward stats.
  Future<ReferralInfo> getReferralInfo(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/referral/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load referral info', response.statusCode);
    }
    return ReferralInfo.fromJson(jsonDecode(response.body));
  }

  /// Claim a friend's referral code.
  Future<Map<String, dynamic>> claimReferral({
    required String refereeUserId,
    required String referralCode,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/learning/referral/claim'),
          headers: _headers(),
          body: jsonEncode({
            'referee_user_id': refereeUserId,
            'referral_code': referralCode,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to claim referral', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Get daily missions.
  Future<MissionsResponse> getMissions(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/missions/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load missions', response.statusCode);
    }
    return MissionsResponse.fromJson(jsonDecode(response.body));
  }

  /// Claim a completed mission reward.
  Future<Map<String, dynamic>> claimMission({
    required String userId,
    required String missionId,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/learning/missions/claim'),
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'mission_id': missionId,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to claim mission', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Get overall progress stats.
  Future<LearningProgress> getProgress(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/progress/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load progress', response.statusCode);
    }
    return LearningProgress.fromJson(jsonDecode(response.body));
  }

  /// Get roleplay scenarios.
  Future<List<ScenarioItem>> getScenarios() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/scenarios'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load scenarios', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final list = data['scenarios'] as List<dynamic>? ?? [];
    return list.map((item) => ScenarioItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get conversation topics.
  Future<List<TopicItem>> getTopics() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/topics'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load topics', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final list = data['topics'] as List<dynamic>? ?? [];
    return list.map((item) => TopicItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get shadowing scripts.
  Future<List<ShadowingItem>> getShadowing() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/shadowing'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load shadowing items', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final list = data['items'] as List<dynamic>? ?? [];
    return list.map((item) => ShadowingItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Evaluate a learner's shadowing attempt.
  Future<Map<String, dynamic>> evaluateShadowing({
    required String itemId,
    required String transcript,
    required double durationSec,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/learning/shadowing/evaluate'),
          headers: _headers(),
          body: jsonEncode({
            'item_id': itemId,
            'transcript': transcript,
            'duration_sec': durationSec,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to evaluate shadowing', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Get vocabulary notebook cards.
  Future<List<VocabCard>> getVocabulary(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/vocabulary/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load vocabulary', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final list = data['cards'] as List<dynamic>? ?? [];
    return list.map((c) => VocabCard.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Get due vocabulary cards for review.
  Future<List<VocabCard>> getDueVocabulary(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/learning/vocabulary/$userId/due'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load due vocabulary', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final list = data['cards'] as List<dynamic>? ?? [];
    return list.map((c) => VocabCard.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Add a word to vocabulary notebook.
  Future<Map<String, dynamic>> addVocabulary({
    required String userId,
    required String word,
    required String definition,
    String example = '',
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/learning/vocabulary/add'),
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'word': word,
            'definition': definition,
            'example': example,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to add word', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Submit review rating for a vocabulary card (again, hard, good, easy).
  Future<Map<String, dynamic>> reviewVocabulary({
    required String cardId,
    required String rating,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/learning/vocabulary/review'),
          headers: _headers(),
          body: jsonEncode({
            'card_id': cardId,
            'rating': rating,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to submit review', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  // ================= PARENT & SAFETY =================

  /// Get parent dashboard summary.
  Future<ParentSummary> getParentSummary(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/parent/summary/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load parent summary', response.statusCode);
    }
    return ParentSummary.fromJson(jsonDecode(response.body));
  }

  /// Get safety flags for parent review.
  Future<List<SafetyFlag>> getSafetyFlags(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/parent/safety-flags/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load safety flags', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final list = data['flags'] as List<dynamic>? ?? [];
    return list.map((f) => SafetyFlag.fromJson(f as Map<String, dynamic>)).toList();
  }

  // ================= USAGE =================

  /// Get daily usage stats and cap status.
  Future<UsageInfo> getUsage(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/usage/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load usage', response.statusCode);
    }
    return UsageInfo.fromJson(jsonDecode(response.body));
  }

  // ================= PRIVACY =================

  /// Get privacy policy.
  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/privacy/policy'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to load privacy policy', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Record parental consent.
  Future<Map<String, dynamic>> recordConsent({
    required String parentEmail,
    required bool accepted,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/privacy/consent'),
          headers: _headers(),
          body: jsonEncode({
            'parent_email': parentEmail,
            'accepted': accepted,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to record consent', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Delete all user data (Right to be forgotten).
  Future<bool> deleteUserData(String userId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/api/privacy/user/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to delete user data', response.statusCode);
    }
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  /// Export full user learning and privacy archive (GDPR/COPPA data portability).
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/privacy/export/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to export user data', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  // ================= PAYMENT =================

  /// Get subscription and character unlock pricing plans.
  Future<Map<String, dynamic>> getPricing() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/payment/plans'), headers: _headers())
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Failed to load pricing', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Create checkout session for bKash or Nagad.
  Future<Map<String, dynamic>> createCheckout({
    required String userId,
    required String gateway,
    required String purpose,
    String targetId = '',
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/payment/checkout'),
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'gateway': gateway,
            'purpose': purpose,
            'target_id': targetId,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Checkout failed', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Verify payment and activate entitlement.
  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String gateway,
    String verificationToken = '',
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/payment/verify'),
          headers: _headers(),
          body: jsonEncode({
            'payment_id': paymentId,
            'gateway': gateway,
            'verification_token': verificationToken,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Payment verification failed', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Restore purchases for a user.
  Future<List<dynamic>> restorePurchases(String userId) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/api/payment/restore/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Failed to restore purchases', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Get active entitlements for a user.
  Future<List<Entitlement>> getEntitlements(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/payment/entitlements/$userId'), headers: _headers())
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Failed to fetch entitlements', response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Entitlement.fromJson(e as Map<String, dynamic>)).toList();
  }

  void dispose() {
    _client.close();
  }
}

/// API error with status code and retry hint.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final bool retryable;

  ApiException(this.message, this.statusCode, {this.retryable = false});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
