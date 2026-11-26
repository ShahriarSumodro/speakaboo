/// Playful cards, 4-mode tiles, animated stat chips, and mission progress bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/speakaboo_theme.dart';

/// Rounded 24px card with soft shadow in light mode and elevated surface in dark mode.
class PlayfulCard extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Border? border;

  const PlayfulCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(SpeakabooTheme.spacingMd),
    this.onTap,
    this.border,
  });

  @override
  State<PlayfulCard> createState() => _PlayfulCardState();
}

class _PlayfulCardState extends State<PlayfulCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = context.isDarkMode;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final card = AnimatedScale(
      scale: _pressed && widget.onTap != null && !reduceMotion ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutBack,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? c.surface,
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusCard),
          border: widget.border ??
              Border.all(
                color: c.borderSubtle,
                width: isDark ? 1.0 : 0.8,
              ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: c.cardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: card,
    );
  }
}

/// Colourful scannable practice mode tile (icon badge + 2-line label).
class PlayfulModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color washColor;
  final Color iconColor;
  final VoidCallback onTap;

  const PlayfulModeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.washColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PlayfulCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SpeakabooTheme.spacing12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: washColor,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: SpeakabooTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SpeakabooTheme.displayStyle(
                    color: c.textPrimary,
                    size: SpeakabooTheme.baseFontSize,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SpeakabooTheme.bodyStyle(
                    color: c.textSecondary,
                    size: SpeakabooTheme.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated count-up stat chip for the learner's own Streak, XP, and Minutes.
class PlayfulStatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color washColor;
  final int value;
  final String suffix;
  final String label;

  const PlayfulStatChip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.washColor,
    required this.value,
    this.suffix = '',
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PlayfulCard(
      backgroundColor: washColor,
      padding: const EdgeInsets.symmetric(
        horizontal: SpeakabooTheme.spacing12,
        vertical: SpeakabooTheme.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: reduceMotion ? value.toDouble() : 0, end: value.toDouble()),
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      '${val.round()}$suffix',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SpeakabooTheme.displayStyle(
                        color: c.textPrimary,
                        size: SpeakabooTheme.headingSize,
                        weight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SpeakabooTheme.bodyStyle(
              color: c.textSecondary,
              size: SpeakabooTheme.captionSize,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily mission strip with reward pill and overshoot-animated progress bar.
class PlayfulMissionBar extends StatelessWidget {
  final String title;
  final String rewardLabel;
  final double progress; // 0.0 to 1.0
  final VoidCallback? onTap;

  const PlayfulMissionBar({
    super.key,
    required this.title,
    required this.rewardLabel,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final clamped = progress.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PlayfulCard(
      backgroundColor: c.pastelYellow,
      onTap: onTap,
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: c.sunnyEdge, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SpeakabooTheme.displayStyle(
                    color: c.textPrimary,
                    size: SpeakabooTheme.baseFontSize,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.sunny,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                ),
                child: Text(
                  rewardLabel,
                  style: SpeakabooTheme.bodyStyle(
                    color: c.accentText,
                    size: SpeakabooTheme.captionSize,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
            child: Container(
              height: 10,
              color: c.surface.withValues(alpha: 0.7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: reduceMotion ? clamped : 0, end: clamped),
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 700),
                  curve: Curves.easeOutBack,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      widthFactor: value.clamp(0.04, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
