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
  Uint8List? _previewAudioBytes;

  Future<void> _playVoicePreview() async {
    if (_isPlayingPreview) return;

    final api = context.read<ApiService>();
    final audio = context.read<AudioService>();

    setState(() {
      _isLoadingPreview = true;
    });

    try {
      _previewAudioBytes ??= await api.getPreviewAudio(widget.character.id);

      setState(() {
        _isLoadingPreview = false;
        _isPlayingPreview = true;
      });

      await audio.playChunks([_previewAudioBytes!]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play voice preview: $e')),
        );
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
        onPayWithBkash: () => _handlePayment('bkash'),
        onPayWithNagad: () => _handlePayment('nagad'),
      ),
    );
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

      final verify = await api.verifyPayment(
        paymentId: paymentId,
        gateway: gateway,
        verificationToken: 'sandbox_verified',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.character.name} unlocked successfully!'),
            backgroundColor: SpeakabooTheme.success,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        children: [
          // Avatar & Header
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: SpeakabooTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: SpeakabooTheme.accent, width: 3),
              ),
              child: const Icon(Icons.face, size: 64, color: SpeakabooTheme.accent),
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),
          Center(
            child: Text(
              c.name,
              style: const TextStyle(
                fontSize: SpeakabooTheme.headingSize,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.textPrimary,
              ),
            ),
          ),
          Center(
            child: Text(
              c.tagline,
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Hear their voice button
          Center(
            child: OutlinedButton.icon(
              onPressed: _isLoadingPreview ? null : _playVoicePreview,
              icon: _isLoadingPreview
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_isPlayingPreview ? Icons.volume_up : Icons.play_arrow),
              label: Text(_isPlayingPreview ? 'Playing Sample...' : 'Hear their voice'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SpeakabooTheme.accent,
                side: const BorderSide(color: SpeakabooTheme.accent),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),

          // Personality Traits
          const Text(
            'Personality & Teaching Style',
            style: TextStyle(
              fontSize: SpeakabooTheme.baseFontSize + 1,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textPrimary,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.personalityTraits.map((trait) {
              return Chip(
                label: Text(trait),
                backgroundColor: SpeakabooTheme.surface,
                labelStyle: const TextStyle(fontSize: 13, color: SpeakabooTheme.textPrimary),
              );
            }).toList(),
          ),

          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Speaking Style & Best For
          Container(
            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
            decoration: BoxDecoration(
              color: SpeakabooTheme.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best For: ${c.bestFor}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Speaking Style: ${c.speakingStyle}', style: const TextStyle(fontSize: 13, color: SpeakabooTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('Vocabulary Focus: ${c.vocabularyFocus}', style: const TextStyle(fontSize: 13, color: SpeakabooTheme.textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Sample Dialogue
          if (c.sampleLines.isNotEmpty) ...[
            const Text(
              'Sample Phrases',
              style: TextStyle(
                fontSize: SpeakabooTheme.baseFontSize + 1,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.textPrimary,
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
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: SpeakabooTheme.textSecondary,
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
                  backgroundColor: SpeakabooTheme.accent,
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
