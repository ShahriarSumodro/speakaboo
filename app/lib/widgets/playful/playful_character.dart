/// Expressive PlayfulCharacter wrapper around CharacterFace with 6 moods.
library;

import 'package:flutter/material.dart';
import '../../theme/speakaboo_theme.dart';
import '../character_face.dart';

enum CharacterMood {
  idle,
  listening,
  thinking,
  speaking,
  celebrating,
  encouraging,
}

/// Animated character presence supporting idle float, listening mic ripple,
/// thinking indicator, speaking mouth motion, celebrating bounce, and encouraging glow.
class PlayfulCharacter extends StatefulWidget {
  final String characterId;
  final CharacterMood mood;
  final double size;

  const PlayfulCharacter({
    super.key,
    this.characterId = 'rule_farmer',
    this.mood = CharacterMood.idle,
    this.size = 160,
  });

  @override
  State<PlayfulCharacter> createState() => _PlayfulCharacterState();
}

class _PlayfulCharacterState extends State<PlayfulCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Color _backdropColor(SpeakabooColors c) {
    switch (widget.characterId) {
      case 'rule_detective':
        return c.pastelSky;
      case 'rule_professor':
        return c.pastelLavender;
      default:
        return c.pastelMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isListening = widget.mood == CharacterMood.listening;
    final isThinking = widget.mood == CharacterMood.thinking;
    final isSpeaking = widget.mood == CharacterMood.speaking;
    final isCelebrating = widget.mood == CharacterMood.celebrating;
    final isEncouraging = widget.mood == CharacterMood.encouraging;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final t = reduceMotion ? 0.5 : _floatController.value;
        final dy = reduceMotion ? 0.0 : (t - 0.5) * 10.0; // ±5px gentle float
        final scale = isListening && !reduceMotion ? 1.04 : 1.0;

        return Transform.translate(
          offset: Offset(0, dy),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft pastel stage behind character
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: widget.size * 1.12,
            height: widget.size * 1.12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? c.coral.withValues(alpha: 0.22)
                  : isEncouraging
                      ? c.pastelYellow
                      : _backdropColor(c),
              border: Border.all(
                color: isListening ? c.coral : c.borderSubtle,
                width: isListening ? 3 : 1.5,
              ),
            ),
          ),
          CharacterFace(
            characterId: widget.characterId,
            size: widget.size,
            isTalking: isSpeaking,
            isListening: isListening,
            isThinking: isThinking,
            isCelebrating: isCelebrating,
          ),
          if (isEncouraging)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.sunny,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                ),
                child: Text(
                  'You got this!',
                  style: SpeakabooTheme.bodyStyle(
                    color: c.accentText,
                    size: 11,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
