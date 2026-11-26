/// Playful empty, loading (shimmer + character), and kind error states.
library;

import 'package:flutter/material.dart';
import '../../theme/speakaboo_theme.dart';
import 'playful_buttons.dart';
import 'playful_cards.dart';
import 'playful_character.dart';

/// Friendly empty state featuring the character and a clear next-step button.
class PlayfulEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String characterId;

  const PlayfulEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.characterId = 'rule_farmer',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
        child: PlayfulCard(
          backgroundColor: c.surface,
          padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayfulCharacter(
                characterId: characterId,
                mood: CharacterMood.encouraging,
                size: 110,
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),
              Text(
                title,
                textAlign: TextAlign.center,
                style: SpeakabooTheme.displayStyle(
                  color: c.textPrimary,
                  size: SpeakabooTheme.headingSize,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: SpeakabooTheme.bodyStyle(
                  color: c.textSecondary,
                  size: SpeakabooTheme.baseFontSize,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: SpeakabooTheme.spacingLg),
                PlayfulButton(
                  label: actionLabel!,
                  icon: Icons.arrow_forward_rounded,
                  iconAfter: true,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kind, non-harsh error state with character encouragement and retry button.
class PlayfulErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const PlayfulErrorState({
    super.key,
    this.title = 'Oops, a tiny hiccup!',
    required this.message,
    this.retryLabel = 'Try Again',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
        child: PlayfulCard(
          backgroundColor: c.pastelPink,
          padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PlayfulCharacter(
                mood: CharacterMood.encouraging,
                size: 100,
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),
              Text(
                title,
                textAlign: TextAlign.center,
                style: SpeakabooTheme.displayStyle(
                  color: c.textPrimary,
                  size: SpeakabooTheme.headingSize,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: SpeakabooTheme.bodyStyle(
                  color: c.textSecondary,
                  size: SpeakabooTheme.baseFontSize,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),
              PlayfulButton(
                label: retryLabel,
                icon: Icons.refresh_rounded,
                variant: PlayfulButtonVariant.coral,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton shimmer + character loading state (never a bare spinner).
class PlayfulLoadingState extends StatefulWidget {
  final String message;

  const PlayfulLoadingState({
    super.key,
    this.message = 'Getting things ready...',
  });

  @override
  State<PlayfulLoadingState> createState() => _PlayfulLoadingStateState();
}

class _PlayfulLoadingStateState extends State<PlayfulLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlayfulCharacter(
              mood: CharacterMood.thinking,
              size: 96,
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            Text(
              widget.message,
              style: SpeakabooTheme.displayStyle(
                color: c.textPrimary,
                size: SpeakabooTheme.subheadingSize,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (context, _) {
                final alpha = reduceMotion ? 0.5 : 0.35 + _shimmerCtrl.value * 0.4;
                return Column(
                  children: [
                    _SkeletonBar(width: 240, height: 18, color: c.surfaceWarm.withValues(alpha: alpha)),
                    const SizedBox(height: 10),
                    _SkeletonBar(width: 180, height: 14, color: c.surfaceWarm.withValues(alpha: alpha)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonBar({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
      ),
    );
  }
}
