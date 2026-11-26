/// Character detail screen with voice preview and trial.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/character.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../widgets/playful/playful.dart';
import '../widgets/unlock_sheet.dart';

class CharacterDetailScreen extends StatefulWidget {
  final Character character;

  const CharacterDetailScreen({super.key, required this.character});

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  bool _isPlayingPreview = false;
  bool _isLoadingPreview = false;
  bool _previewFailed = false;
  Uint8List? _previewAudioBytes;

  Future<void> _playVoicePreview() async {
    if (_isPlayingPreview) return;

    final api = context.read<ApiService>();
    final audio = context.read<AudioService>();

    setState(() {
      _isLoadingPreview = true;
      _previewFailed = false;
    });

    try {
      _previewAudioBytes ??= await api.getPreviewAudio(widget.character.id);

      setState(() {
        _isLoadingPreview = false;
        _isPlayingPreview = true;
      });

      await audio.playChunks([_previewAudioBytes!]);
    } catch (e) {
      debugPrint('[CharacterDetail] server preview unavailable: $e');
      final sampleText = widget.character.sampleLines.isNotEmpty
          ? widget.character.sampleLines.first
          : 'Hello! Let us practice English with ${widget.character.name}.';
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _isPlayingPreview = true;
        });
      }
      final spokeFallback = await audio.speakOnDevice(sampleText);
      if (mounted) {
        if (spokeFallback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using device voice preview (accept Groq Orpheus terms for studio voice).'),
            ),
          );
        } else {
          setState(() {
            _previewFailed = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Voice preview temporarily unavailable. Please try again.'),
              action: SnackBarAction(
                label: 'Retry',
                textColor: context.colors.warning,
                onPressed: _playVoicePreview,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _isPlayingPreview = false;
        });
      }
    }
  }

  void _startSpeaking(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final conv = context.read<ConversationProvider>();

    conv.startConversation(
      userId: auth.userId,
      characterId: widget.character.id,
    );

    Navigator.pop(context, true); // Pop back to characters/talk screen
  }

  void _showUnlockDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UnlockSheet(
        title: widget.character.name,
        priceText: '${widget.character.priceBdt} BDT',
        onPayWithPlay: () => _handlePayment('google_play'),
        onPayWithBkash: () => _handlePayment('bkash'),
        onPayWithNagad: () => _handlePayment('nagad'),
        onRestore: () => _handleRestore(),
      ),
    );
  }

  Future<void> _handleRestore() async {
    Navigator.pop(context);
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    try {
      final restored = await api.restorePurchases(auth.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored: ${restored.length} item(s) found.'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore error: $e')),
        );
      }
    }
  }

  Future<void> _handlePayment(String gateway) async {
    Navigator.pop(context); // Close bottom sheet
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();

    try {
      final checkout = await api.createCheckout(
        userId: auth.userId,
        gateway: gateway,
        purpose: 'character_unlock',
        targetId: widget.character.id,
      );

      final paymentId = checkout['payment_id'] as String? ?? 'sandbox_pmt_${DateTime.now().millisecondsSinceEpoch}';

      await api.verifyPayment(
        paymentId: paymentId,
        gateway: gateway,
        verificationToken: 'sandbox_verified',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.character.name} unlocked successfully!'),
            backgroundColor: context.colors.success,
          ),
        );
        _startSpeaking(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final conv = context.watch<ConversationProvider>();
    final isCurrent = conv.currentCharacterId == c.id;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        children: [
          // Avatar & Header
          Center(
            child: PlayfulCharacter(
              characterId: c.id,
              mood: _isPlayingPreview
                  ? CharacterMood.speaking
                  : (_isLoadingPreview ? CharacterMood.thinking : CharacterMood.idle),
              size: 124,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),
          Center(
            child: Text(
              c.name,
              style: SpeakabooTheme.displayStyle(
                color: colors.textPrimary,
                size: SpeakabooTheme.headingSize,
              ),
            ),
          ),
          Center(
            child: Text(
              c.tagline,
              textAlign: TextAlign.center,
              style: SpeakabooTheme.bodyStyle(
                color: colors.textSecondary,
                size: SpeakabooTheme.baseFontSize,
              ),
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Hear their voice button
          Center(
            child: Column(
              children: [
                PlayfulButton(
                  label: _isPlayingPreview
                      ? 'Playing Sample...'
                      : (_isLoadingPreview ? 'Loading Voice...' : 'Hear their voice'),
                  icon: _isPlayingPreview ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                  variant: PlayfulButtonVariant.sunny,
                  onPressed: _isLoadingPreview ? null : _playVoicePreview,
                ),
                if (_previewFailed) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voice preview temporarily unavailable.',
                        style: TextStyle(fontSize: 12, color: colors.error),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        key: const Key('retry_preview_btn'),
                        icon: Icon(Icons.refresh, size: 14, color: colors.accent),
                        label: Text('Retry', style: TextStyle(color: colors.accent)),
                        onPressed: _playVoicePreview,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),

          // Personality Traits
          Text(
            'Personality & Teaching Style',
            style: TextStyle(
              fontSize: SpeakabooTheme.baseFontSize + 1,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.personalityTraits.map((trait) {
              return Chip(
                label: Text(trait),
                backgroundColor: colors.surface,
                side: BorderSide(color: colors.surface),
                labelStyle: TextStyle(fontSize: 13, color: colors.textPrimary),
              );
            }).toList(),
          ),

          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Speaking Style & Best For
          Container(
            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    children: [
                      const TextSpan(
                        text: 'Best For: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: c.bestFor,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    children: [
                      const TextSpan(
                        text: 'Speaking Style: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: c.speakingStyle,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (c.vocabularyFocus.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      children: [
                        const TextSpan(
                          text: 'Vocabulary Focus: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: c.vocabularyFocus,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Sample Dialogue
          if (c.sampleLines.isNotEmpty) ...[
            Text(
              'Sample Phrases',
              style: TextStyle(
                fontSize: SpeakabooTheme.baseFontSize + 1,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            ...c.sampleLines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💬 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          '"$line"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: SpeakabooTheme.spacingXl),

          // Action Button
          if (c.isFree || !isCurrent)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (c.isFree) {
                    _startSpeaking(context);
                  } else {
                    _showUnlockDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd)),
                ),
                child: Text(
                  c.isFree
                      ? (isCurrent ? 'Continue Practice' : 'Start Talking with ${c.name}')
                      : 'Unlock for ${c.priceBdt} BDT',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
