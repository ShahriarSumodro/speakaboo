/// API service for communicating with the Speakaboo backend.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

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

/// API client for the Speakaboo backend.
class ApiService {
  final String? _customBaseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : _customBaseUrl = baseUrl,
        _client = client ?? http.Client();

  String get baseUrl => _customBaseUrl ?? AppConfig.backendUrl;

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

  /// Start a conversation with a character.
  Future<StartConversationResult> startConversation({
    required String userId,
    required String characterId,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/conversation/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'character_id': characterId,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to start conversation', response.statusCode);
    }
    return StartConversationResult.fromJson(jsonDecode(response.body));
  }

  /// Send an audio turn and get the AI response.
  Future<TurnResult> sendTurn({
    required String conversationId,
    required Uint8List audio,
    String audioFormat = 'wav',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/conversation/turn'),
    );

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

  /// Get subscription and character unlock pricing.
  Future<Map<String, dynamic>> getPricing() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/payment/plans'))
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
          headers: {'Content-Type': 'application/json'},
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
          headers: {'Content-Type': 'application/json'},
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
        .post(Uri.parse('$baseUrl/api/payment/restore/$userId'))
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Failed to restore purchases', response.statusCode);
    }
    return jsonDecode(response.body);
  }

  /// Get active entitlements for a user.
  Future<List<dynamic>> getEntitlements(String userId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/payment/entitlements/$userId'))
        .timeout(AppConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Failed to fetch entitlements', response.statusCode);
    }
    return jsonDecode(response.body);
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
