/// Playful chrome: greeting header, bottom navigation, sheets, dialogs, and inputs.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/speakaboo_theme.dart';
import 'playful_buttons.dart';

/// Friendly greeting pill header ("👋 Hi, Learner!") with optional trailing widget.
class PlayfulGreetingHeader extends StatelessWidget {
  final String name;
  final String? badgeText;
  final Widget? trailing;

  const PlayfulGreetingHeader({
    super.key,
    required this.name,
    this.badgeText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceWarm,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👋', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    badgeText ?? 'Hi, $name!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SpeakabooTheme.displayStyle(
                      color: c.textPrimary,
                      size: SpeakabooTheme.baseFontSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: SpeakabooTheme.spacingSm),
          trailing!,
        ],
      ],
    );
  }
}

class PlayfulNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const PlayfulNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Playful bottom navigation bar with active pill highlight and haptic tap.
class PlayfulBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PlayfulNavItem> items;

  const PlayfulBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusCard),
          border: Border.all(color: c.borderSubtle),
          boxShadow: context.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: c.cardShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? c.primary.withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: selected ? 24 : 22,
                          color: selected ? c.primary : c.textSecondary,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            style: SpeakabooTheme.bodyStyle(
                              color: selected ? c.primary : c.textSecondary,
                              size: 11.5,
                              weight: selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Warm, rounded 24px bottom sheet container with drag handle.
class PlayfulBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const PlayfulBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayfulBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpeakabooTheme.spacingLg,
        SpeakabooTheme.spacing12,
        SpeakabooTheme.spacingLg,
        SpeakabooTheme.spacingLg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SpeakabooTheme.radiusCard),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: c.borderSubtle,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            Text(
              title,
              style: SpeakabooTheme.displayStyle(
                color: c.textPrimary,
                size: SpeakabooTheme.headingSize,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacing12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Playful dialog with rounded 24px corners and chunky action buttons.
class PlayfulDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const PlayfulDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: SpeakabooTheme.displayStyle(
                color: c.textPrimary,
                size: SpeakabooTheme.headingSize,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Text(
              message,
              style: SpeakabooTheme.bodyStyle(
                color: c.textSecondary,
                size: SpeakabooTheme.baseFontSize,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
            Row(
              children: [
                if (secondaryLabel != null) ...[
                  Expanded(
                    child: PlayfulButton(
                      label: secondaryLabel!,
                      variant: PlayfulButtonVariant.secondary,
                      onPressed: onSecondary ?? () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: SpeakabooTheme.spacing12),
                ],
                Expanded(
                  child: PlayfulButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Warm cream rounded text input inspired by the reference search & auth fields.
class PlayfulInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const PlayfulInput({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      style: SpeakabooTheme.bodyStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: SpeakabooTheme.bodyStyle(color: c.textSecondary),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: c.textSecondary) : null,
        filled: true,
        fillColor: c.surfaceWarm,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
    );
  }
}
