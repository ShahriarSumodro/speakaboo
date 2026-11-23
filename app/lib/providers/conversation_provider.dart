/// Conversation provider - manages conversation state.
library;

import 'package:flutter/foundation.dart';
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
  String _level = 'beginner';
  String? _errorMessage;
  final List<ChatMessage> _messages = [];
  double _lastLatencyMs = 0;

  ConversationProvider({
    required this.api,
    required this.audio,
  });

  ConversationStatus get status => _status;
  String? get conversationId => _conversationId;
  String? get characterName => _characterName;
  String get level => _level;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  double get lastLatencyMs => _lastLatencyMs;
  bool get isRecording => _status == ConversationStatus.recording;
  bool get isProcessing => _status == ConversationStatus.processing;
  bool get isPlaying => _status == ConversationStatus.playing;

  /// Start a new conversation with a character.
  Future<void> startConversation({
    required String userId,
    required String characterId,
  }) async {
    try {
      _status = ConversationStatus.processing;
      _errorMessage = null;
      notifyListeners();

      final result = await api.startConversation(
        userId: userId,
        characterId: characterId,
      );

      _conversationId = result.conversationId;
      _characterName = result.characterName;
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

    await _processAudio(audioBytes);
  }

  /// Process audio through the full pipeline.
  Future<void> _processAudio(Uint8List audio) async {
    try {
      _status = ConversationStatus.processing;
      notifyListeners();

      final result = await api.sendTurn(
        conversationId: _conversationId!,
        audio: audio,
      );

      _lastLatencyMs = result.latencyMs;
      _level = result.level;

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

        await this.audio.playChunks(result.audioChunks);

        // After playback completes
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

  /// End the current conversation.
  void endConversation() {
    _conversationId = null;
    _characterName = null;
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
