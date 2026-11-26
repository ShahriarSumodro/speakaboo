/// Playful chunky 3D buttons and marker-highlighted text.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/speakaboo_theme.dart';

enum PlayfulButtonVariant { primary, sunny, coral, mint, sky, secondary }

/// Chunky tactile pill button with a 4px darker bottom edge that compresses on press.
class PlayfulButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool iconAfter;
  final PlayfulButtonVariant variant;
  final bool fullWidth;
  final double height;

  const PlayfulButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.variant = PlayfulButtonVariant.primary,
    this.fullWidth = false,
    this.height = SpeakabooTheme.buttonHeight,
  });

  @override
  State<PlayfulButton> createState() => _PlayfulButtonState();
}

class _PlayfulButtonState extends State<PlayfulButton> {
  bool _pressed = false;

  (Color bg, Color edge, Color fg) _resolveColors(SpeakabooColors c) {
    switch (widget.variant) {
      case PlayfulButtonVariant.primary:
        return (c.primary, c.primaryEdge, c.onPrimary);
      case PlayfulButtonVariant.sunny:
        return (c.sunny, c.sunnyEdge, c.accentText);
      case PlayfulButtonVariant.coral:
        return (c.coral, c.coralEdge, c.accentText);
      case PlayfulButtonVariant.mint:
        return (c.mint, c.mintEdge, c.accentText);
      case PlayfulButtonVariant.sky:
        return (c.sky, c.skyEdge, c.accentText);
      case PlayfulButtonVariant.secondary:
        return (c.surface, c.borderSubtle, c.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = widget.onPressed == null;
    final (bg, edge, fg) = _resolveColors(c);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final depth = SpeakabooTheme.buttonEdgeDepth;
    final pressedOffset = _pressed && !disabled ? depth : 0.0;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: disabled
            ? null
            : (_) {
                HapticFeedback.lightImpact();
                setState(() => _pressed = true);
              },
        onTapUp: disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && !disabled && !reduceMotion ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: widget.fullWidth ? double.infinity : null,
            height: widget.height + depth,
            child: Stack(
              children: [
                // 4px bottom 3D edge
                Positioned(
                  left: 0,
                  right: 0,
                  top: depth,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: disabled ? c.borderSubtle : edge,
                      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                    ),
                  ),
                ),
                // Main pill face
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  top: pressedOffset,
                  bottom: depth - pressedOffset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: SpeakabooTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: disabled ? c.surfaceWarm : bg,
                      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                      border: widget.variant == PlayfulButtonVariant.secondary
                          ? Border.all(color: c.borderSubtle, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null && !widget.iconAfter) ...[
                          Icon(
                            widget.icon,
                            size: 20,
                            color: disabled ? c.textSecondary : fg,
                          ),
                          const SizedBox(width: SpeakabooTheme.spacingSm),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SpeakabooTheme.displayStyle(
                              color: disabled ? c.textSecondary : fg,
                              size: SpeakabooTheme.baseFontSize,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (widget.icon != null && widget.iconAfter) ...[
                          const SizedBox(width: SpeakabooTheme.spacingSm),
                          Icon(
                            widget.icon,
                            size: 20,
                            color: disabled ? c.textSecondary : fg,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emotional headline with a warm sunny highlighter swath behind the key phrase.
class PlayfulMarkerText extends StatelessWidget {
  final String prefix;
  final String highlighted;
  final String suffix;
  final double fontSize;
  final TextAlign textAlign;

  const PlayfulMarkerText({
    super.key,
    required this.prefix,
    required this.highlighted,
    this.suffix = '',
    this.fontSize = SpeakabooTheme.displaySize,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = SpeakabooTheme.displayStyle(
      color: c.textPrimary,
      size: fontSize,
      weight: FontWeight.w700,
      height: 1.15,
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -4,
                  right: -4,
                  bottom: 2,
                  height: fontSize * 0.42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.sunny.withValues(alpha: context.isDarkMode ? 0.35 : 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Text(highlighted, style: style),
              ],
            ),
          ),
          if (suffix.isNotEmpty) TextSpan(text: suffix),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
