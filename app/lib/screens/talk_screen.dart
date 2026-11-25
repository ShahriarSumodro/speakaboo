/// Talk screen - main conversation UI.
///
/// Phase 2: Simple talk screen with character face, record button,
/// captions, and correction display.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/character_face.dart';
import '../widgets/correction_chip.dart';
import '../widgets/dev_server_dialog.dart';
import '../widgets/hint_sheet.dart';
import '../widgets/session_summary_sheet.dart';

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
    final auth = context.read<AuthProvider>();
    await _conversation.startConversation(
      userId: auth.userId,
      characterId: _conversation.currentCharacterId ?? 'rule_farmer',
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
                      characterId: conv.currentCharacterId ?? 'rule_farmer',
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
    final colors = context.colors;
    final isFluency = conv.practiceMode == 'fluency';
    final isDark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpeakabooTheme.spacingMd,
        vertical: SpeakabooTheme.spacingSm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => DevServerDialog.show(context),
            child: Text(
              conv.characterName ?? 'Speakaboo',
              style: TextStyle(
                fontSize: SpeakabooTheme.headingSize,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          // Trial countdown badge (CD-008)
          if (conv.isTrial && conv.trialSecondsRemaining != null) ...[
            Container(
              key: const Key('trial_countdown_badge'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top, size: 14, color: colors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${(conv.trialSecondsRemaining! ~/ 60)}:${(conv.trialSecondsRemaining! % 60).toString().padLeft(2, '0')} trial',
                    style: TextStyle(
                      fontSize: SpeakabooTheme.smallSize,
                      fontWeight: FontWeight.bold,
                      color: colors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Mode chip
          InkWell(
            onTap: () {
              final newMode = isFluency ? 'accuracy' : 'fluency';
              conv.setPracticeMode(newMode);
            },
            borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? (isFluency ? Colors.teal.withValues(alpha: 0.25) : Colors.amber.withValues(alpha: 0.25))
                    : (isFluency ? Colors.teal.shade50 : Colors.amber.shade50),
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                border: Border.all(
                  color: isDark
                      ? (isFluency ? Colors.teal.shade400 : Colors.amber.shade400)
                      : (isFluency ? Colors.teal.shade300 : Colors.amber.shade300),
                ),
              ),
              child: Text(
                isFluency ? 'Fluency' : 'Accuracy',
                style: TextStyle(
                  fontSize: SpeakabooTheme.smallSize,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? (isFluency ? Colors.teal.shade200 : Colors.amber.shade200)
                      : (isFluency ? Colors.teal.shade800 : Colors.brown),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.flag_outlined, size: 20, color: colors.accent),
            tooltip: 'Finish & Summary',
            onPressed: () async {
              final summary = await conv.fetchSummary();
              if (summary != null && mounted) {
                SessionSummarySheet.show(
                  context,
                  summary: summary,
                  onRetellDrill: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Drill: Speak your previous answer in 45s! Hold mic to start.')),
                    );
                  },
                );
              }
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
            ),
            child: Text(
              conv.level.toUpperCase(),
              style: TextStyle(
                fontSize: SpeakabooTheme.smallSize,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(ConversationProvider conv) {
    final colors = context.colors;
    if (conv.messages.isEmpty) {
      return Center(
        child: Text(
          'Press and hold the button to speak',
          style: TextStyle(
            color: colors.textSecondary,
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
    final colors = context.colors;
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
                    ? colors.accent
                    : colors.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: isUser ? Colors.white : colors.textPrimary,
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
                        style: TextStyle(
                          fontSize: SpeakabooTheme.smallSize,
                          color: colors.textPrimary,
                        ),
                      ),
                      backgroundColor: colors.surface,
                      side: BorderSide(color: colors.surface),
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
    final colors = context.colors;
    final isBusy = conv.status == ConversationStatus.busy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      margin: const EdgeInsets.symmetric(
        horizontal: SpeakabooTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: isBusy
            ? colors.warning.withValues(alpha: 0.15)
            : colors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            isBusy ? Icons.hourglass_top : Icons.error_outline,
            color: isBusy ? colors.warning : colors.error,
            size: 20,
          ),
          const SizedBox(width: SpeakabooTheme.spacingSm),
          Expanded(
            child: Text(
              conv.errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: isBusy ? colors.warning : colors.error,
              ),
            ),
          ),
          TextButton(
            onPressed: conv.clearError,
            child: Text(
              isBusy ? 'OK' : 'Retry',
              style: TextStyle(
                color: isBusy ? colors.warning : colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordArea(ConversationProvider conv) {
    final colors = context.colors;
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
        // "Help me say it" button
        if (isReady && conv.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: () async {
                final hint = await conv.fetchHint();
                if (hint != null && mounted) {
                  HintSheet.show(context, hint);
                }
              },
              icon: Icon(Icons.lightbulb_outline, size: 18, color: colors.accent),
              label: Text(
                'Help me say it',
                style: TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                backgroundColor: colors.accent.withValues(alpha: context.isDarkMode ? 0.2 : 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
              ),
            ),
          ),
        if (statusText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: SpeakabooTheme.spacingSm),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: isRecording
                    ? colors.error
                    : colors.textSecondary,
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
                  ? colors.error
                  : (isReady
                      ? colors.accent
                      : colors.surface),
              shape: BoxShape.circle,
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: colors.error.withValues(alpha: 0.3),
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
                  : colors.textSecondary,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}
