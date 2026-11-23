/// Talk screen - main conversation UI.
///
/// Phase 2: Simple talk screen with character face, record button,
/// captions, and correction display.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/conversation_provider.dart';
import '../widgets/character_face.dart';
import '../widgets/correction_chip.dart';

class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key});

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  late ConversationProvider _conversation;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _conversation = context.read<ConversationProvider>();
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startConversation();
        }
      });
    }
  }

  Future<void> _startConversation() async {
    await _conversation.startConversation(
      userId: 'device-user', // Will be replaced with real device ID
      characterId: 'rule_farmer',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ConversationProvider>(
          builder: (context, conv, _) {
            return Column(
              children: [
                // Header
                _buildHeader(conv),

                // Character face
                Expanded(
                  flex: 3,
                  child: Center(
                    child: CharacterFace(
                      isTalking: conv.status == ConversationStatus.playing,
                      isListening: conv.status == ConversationStatus.recording,
                      isThinking: conv.status == ConversationStatus.processing,
                      size: 200,
                    ),
                  ),
                ),

                // Chat messages area
                Expanded(
                  flex: 4,
                  child: _buildChatArea(conv),
                ),

                // Error/busy banner
                if (conv.status == ConversationStatus.error ||
                    conv.status == ConversationStatus.busy)
                  _buildErrorBanner(conv),

                // Record button area
                _buildRecordArea(conv),

                const SizedBox(height: SpeakabooTheme.spacingMd),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ConversationProvider conv) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpeakabooTheme.spacingMd,
        vertical: SpeakabooTheme.spacingSm,
      ),
      child: Row(
        children: [
          Text(
            conv.characterName ?? 'Speakaboo',
            style: const TextStyle(
              fontSize: SpeakabooTheme.headingSize,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SpeakabooTheme.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
            ),
            child: Text(
              conv.level.toUpperCase(),
              style: const TextStyle(
                fontSize: SpeakabooTheme.smallSize,
                fontWeight: FontWeight.w600,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(ConversationProvider conv) {
    if (conv.messages.isEmpty) {
      return const Center(
        child: Text(
          'Press and hold the button to speak',
          style: TextStyle(
            color: SpeakabooTheme.textSecondary,
            fontSize: SpeakabooTheme.baseFontSize,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: SpeakabooTheme.spacingMd,
      ),
      reverse: true,
      itemCount: conv.messages.length,
      itemBuilder: (context, index) {
        final message = conv.messages[conv.messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: SpeakabooTheme.spacingSm),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: SpeakabooTheme.spacingMd,
                vertical: SpeakabooTheme.spacingSm + 4,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? SpeakabooTheme.accent
                    : SpeakabooTheme.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: isUser ? Colors.white : SpeakabooTheme.textPrimary,
                ),
              ),
            ),
            // Correction chip
            if (!isUser && message.correction != null)
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: CorrectionChip(correction: message.correction!),
              ),
            // New words
            if (!isUser && message.newWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: message.newWords.map((word) {
                    return Chip(
                      label: Text(
                        word,
                        style: const TextStyle(
                          fontSize: SpeakabooTheme.smallSize,
                          color: SpeakabooTheme.textPrimary,
                        ),
                      ),
                      backgroundColor: SpeakabooTheme.surface,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ConversationProvider conv) {
    final isBusy = conv.status == ConversationStatus.busy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      margin: const EdgeInsets.symmetric(
        horizontal: SpeakabooTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: isBusy
            ? SpeakabooTheme.warning.withValues(alpha: 0.1)
            : SpeakabooTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            isBusy ? Icons.hourglass_top : Icons.error_outline,
            color: isBusy ? SpeakabooTheme.warning : SpeakabooTheme.error,
            size: 20,
          ),
          const SizedBox(width: SpeakabooTheme.spacingSm),
          Expanded(
            child: Text(
              conv.errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: isBusy ? SpeakabooTheme.warning : SpeakabooTheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: conv.clearError,
            child: Text(
              isBusy ? 'OK' : 'Retry',
              style: TextStyle(
                color: isBusy ? SpeakabooTheme.warning : SpeakabooTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordArea(ConversationProvider conv) {
    final isReady = conv.status == ConversationStatus.ready;
    final isRecording = conv.status == ConversationStatus.recording;
    final isProcessing = conv.status == ConversationStatus.processing;
    final isPlaying = conv.status == ConversationStatus.playing;

    String statusText;
    if (isRecording) {
      statusText = 'Listening...';
    } else if (isProcessing) {
      statusText = 'Thinking...';
    } else if (isPlaying) {
      statusText = 'Speaking...';
    } else if (isReady) {
      statusText = 'Hold to speak';
    } else {
      statusText = '';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statusText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: SpeakabooTheme.spacingSm),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: isRecording
                    ? SpeakabooTheme.error
                    : SpeakabooTheme.textSecondary,
                fontWeight:
                    isRecording ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        GestureDetector(
          onLongPressStart: isReady ? (_) => conv.startRecording() : null,
          onLongPressEnd: isRecording ? (_) => conv.stopRecordingAndSend() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 80 : 72,
            height: isRecording ? 80 : 72,
            decoration: BoxDecoration(
              color: isRecording
                  ? SpeakabooTheme.error
                  : (isReady
                      ? SpeakabooTheme.accent
                      : SpeakabooTheme.surface),
              shape: BoxShape.circle,
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: SpeakabooTheme.error.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isRecording
                  ? Icons.mic
                  : (isProcessing || isPlaying
                      ? Icons.hourglass_top
                      : Icons.mic_none),
              color: (isReady || isRecording)
                  ? Colors.white
                  : SpeakabooTheme.textSecondary,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}
