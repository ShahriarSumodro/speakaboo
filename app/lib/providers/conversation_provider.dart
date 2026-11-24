/// Conversation provider - manages conversation state with streaming audio support.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/learning_models.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

/// Chat message in the conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  final CorrectionData? correction;
  final List<String> newWords;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.correction,
    this.newWords = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// States of the conversation.
enum ConversationStatus {
  idle,       // Not started
  ready,      // Conversation started, waiting for user
  recording,  // User is speaking
  processing, // Waiting for AI response
  playing,    // AI is speaking
  error,      // Error state
  busy,       // Rate limited / server busy
}

/// Manages conversation state between user and AI character.
class ConversationProvider extends ChangeNotifier {
  final ApiService api;
  final AudioService audio;

  ConversationStatus _status = ConversationStatus.idle;
  String? _conversationId;
  String? _characterName;
  String? _currentCharacterId;
  String _level = 'beginner';
  String? _errorMessage;
  final List<ChatMessage> _messages = [];
  double _lastLatencyMs = 0;
  String? _scenarioId;
  String? _topicId;
  String _practiceMode = 'accuracy'; // 'accuracy' or 'fluency'
  String _coachMode = 'balanced';   // 'gentle', 'balanced', 'strict'
  bool _useStreaming = true;
  bool _isTrial = false;
  int? _trialSecondsRemaining;

  ConversationProvider({
    required this.api,
    required this.audio,
  });

  ConversationStatus get status => _status;
  String? get conversationId => _conversationId;
  String? get characterName => _characterName;
  String? get currentCharacterId => _currentCharacterId;
  String get level => _level;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  double get lastLatencyMs => _lastLatencyMs;
  bool get isRecording => _status == ConversationStatus.recording;
  bool get isProcessing => _status == ConversationStatus.processing;
  bool get isPlaying => _status == ConversationStatus.playing;
  String? get scenarioId => _scenarioId;
  String? get topicId => _topicId;
  String get practiceMode => _practiceMode;
  String get coachMode => _coachMode;
  bool get isTrial => _isTrial;
  int? get trialSecondsRemaining => _trialSecondsRemaining;

  void setTrial({required bool isTrial, int? secondsRemaining}) {
    _isTrial = isTrial;
    _trialSecondsRemaining = secondsRemaining;
    notifyListeners();
  }

  void setPracticeMode(String mode) {
    _practiceMode = mode;
    notifyListeners();
  }

  void setCoachMode(String mode) {
    _coachMode = mode;
    notifyListeners();
  }

  void setStreamingEnabled(bool enabled) {
    _useStreaming = enabled;
  }

  /// Start a new conversation with a character.
  Future<void> startConversation({
    required String userId,
    required String characterId,
    String? scenarioId,
    String? topicId,
    String? practiceMode,
    String? coachMode,
  }) async {
    try {
      _status = ConversationStatus.processing;
      _errorMessage = null;
      _currentCharacterId = characterId;
      _scenarioId = scenarioId;
      _topicId = topicId;
      if (practiceMode != null) _practiceMode = practiceMode;
      if (coachMode != null) _coachMode = coachMode;
      notifyListeners();

      final result = await api.startConversation(
        userId: userId,
        characterId: characterId,
        scenarioId: scenarioId,
        topicId: topicId,
        practiceMode: _practiceMode,
        coachMode: _coachMode,
      );

      _conversationId = result.conversationId;
      _characterName = result.characterName;
      _isTrial = result.isTrial;
      _trialSecondsRemaining = result.trialSecondsRemaining;
      _messages.clear();

      // Add greeting as first message
      _messages.add(ChatMessage(
        text: result.greeting,
        isUser: false,
      ));

      _status = ConversationStatus.ready;
      notifyListeners();
    } on ApiException catch (e) {
      _handleError(e.message, retryable: e.retryable);
    } catch (e) {
      _handleError('Could not connect to server. Check your internet.');
    }
  }

  /// Start recording user audio.
  Future<void> startRecording() async {
    if (_conversationId == null) return;

    final started = await audio.startRecording();
    if (started) {
      _status = ConversationStatus.recording;
      _errorMessage = null;
      notifyListeners();
    } else {
      _handleError(audio.errorMessage ?? 'Could not start microphone');
    }
  }

  /// Stop recording and send to backend.
  Future<void> stopRecordingAndSend() async {
    if (_conversationId == null) return;

    final audioBytes = await audio.stopRecording();
    if (audioBytes == null || audioBytes.isEmpty) {
      _handleError('No audio recorded. Try again.');
      return;
    }

    if (_useStreaming) {
      await _processAudioStreaming(audioBytes);
    } else {
      await _processAudioBlocking(audioBytes);
    }
  }

  /// Streaming turn: receives early transcript, streaming reply text, and sentence audio chunks.
  Future<void> _processAudioStreaming(Uint8List audioBytes) async {
    try {
      _status = ConversationStatus.processing;
      notifyListeners();

      String transcript = '';
      String replyText = '';
      CorrectionData? correction;
      List<String> newWords = [];
      final List<Uint8List> audioChunks = [];
      bool gotTranscript = false;

      final stream = api.streamTurn(
        conversationId: _conversationId!,
        audio: audioBytes,
      );

      await for (final event in stream) {
        final type = event['type'] as String?;

        if (type == 'transcript') {
          transcript = event['text'] ?? '';
          if (transcript.isNotEmpty && !gotTranscript) {
            gotTranscript = true;
            _messages.add(ChatMessage(text: transcript, isUser: true));
            notifyListeners();
          }
        } else if (type == 'reply_chunk') {
          replyText += event['text'] ?? '';
        } else if (type == 'audio_chunk') {
          final b64 = event['audio_base64'] as String?;
          if (b64 != null && b64.isNotEmpty) {
            audioChunks.add(base64Decode(b64));
          }
        } else if (type == 'turn_complete') {
          final turn = event['turn'] as Map<String, dynamic>? ?? {};
          if (turn['reply'] != null) {
            replyText = turn['reply'];
          }
          if (turn['correction'] != null) {
            correction = CorrectionData.fromJson(turn['correction']);
          }
          if (turn['new_words'] != null) {
            newWords = List<String>.from(turn['new_words']);
          }
          if (turn['level'] != null) {
            _level = turn['level'];
          }
          if (turn['latency_ms'] != null) {
            _lastLatencyMs = (turn['latency_ms'] as num).toDouble();
          }
        }
      }

      // If transcript was not yielded early
      if (!gotTranscript && transcript.isNotEmpty) {
        _messages.add(ChatMessage(text: transcript, isUser: true));
      }

      // Add completed AI response
      if (replyText.isNotEmpty) {
        _messages.add(ChatMessage(
          text: replyText,
          isUser: false,
          correction: correction,
          newWords: newWords,
        ));
      }

      notifyListeners();

      // Play audio response chunks
      if (audioChunks.isNotEmpty) {
        _status = ConversationStatus.playing;
        notifyListeners();

        await audio.playChunks(audioChunks);

        _status = ConversationStatus.ready;
        notifyListeners();
      } else {
        _status = ConversationStatus.ready;
        notifyListeners();
      }
    } catch (_) {
      // Fallback to blocking endpoint on any streaming failure
      await _processAudioBlocking(audioBytes);
    }
  }

  /// Process audio through blocking endpoint (fallback).
  Future<void> _processAudioBlocking(Uint8List audioBytes) async {
    try {
      _status = ConversationStatus.processing;
      notifyListeners();

      final result = await api.sendTurn(
        conversationId: _conversationId!,
        audio: audioBytes,
      );

      _lastLatencyMs = result.latencyMs;
      _level = result.level;
      if (result.isTrial) {
        _isTrial = true;
        _trialSecondsRemaining = result.trialSecondsRemaining;
      }

      // Add user message
      if (result.userTranscript.isNotEmpty) {
        _messages.add(ChatMessage(
          text: result.userTranscript,
          isUser: true,
        ));
      }

      // Add AI response
      _messages.add(ChatMessage(
        text: result.reply,
        isUser: false,
        correction: result.correction,
        newWords: result.newWords,
      ));

      notifyListeners();

      // Play audio response
      if (result.audioChunks.isNotEmpty) {
        _status = ConversationStatus.playing;
        notifyListeners();

        await audio.playChunks(result.audioChunks);

        _status = ConversationStatus.ready;
        notifyListeners();
      } else {
        _status = ConversationStatus.ready;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        _handleError(e.message, retryable: true, isBusy: true);
      } else {
        _handleError(e.message, retryable: e.retryable);
      }
    } catch (e) {
      _handleError('Something went wrong. Try again.');
    }
  }

  void _handleError(String message, {bool retryable = false, bool isBusy = false}) {
    _errorMessage = message;
    _status = isBusy ? ConversationStatus.busy : ConversationStatus.error;
    notifyListeners();
  }

  /// Clear error and return to ready state.
  void clearError() {
    if (_conversationId != null) {
      _status = ConversationStatus.ready;
    } else {
      _status = ConversationStatus.idle;
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch sentence starter and model answer hint.
  Future<ConversationHint?> fetchHint() async {
    if (_conversationId == null) return null;
    try {
      return await api.getConversationHint(_conversationId!);
    } catch (e) {
      debugPrint('Error fetching hint: $e');
      return null;
    }
  }

  /// Fetch end-of-session summary and retention metrics.
  Future<SessionSummary?> fetchSummary() async {
    if (_conversationId == null) return null;
    try {
      return await api.getConversationSummary(_conversationId!);
    } catch (e) {
      debugPrint('Error fetching session summary: $e');
      return null;
    }
  }

  /// End the current conversation.
  void endConversation() {
    _conversationId = null;
    _characterName = null;
    _currentCharacterId = null;
    _scenarioId = null;
    _topicId = null;
    _isTrial = false;
    _trialSecondsRemaining = null;
    _messages.clear();
    _status = ConversationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    audio.dispose();
    api.dispose();
    super.dispose();
  }
}
