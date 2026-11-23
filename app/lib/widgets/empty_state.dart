/// Empty state widget conforming to DESIGN.md.
///
/// Handles:
/// - First-time clean full-screen empty state pointing to primary action
/// - "No results" state with friendly imagery, suggestion, and exit action
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isFirstTime;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isFirstTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: SpeakabooTheme.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusLg),
              ),
              child: Icon(
                icon,
                size: 44,
                color: SpeakabooTheme.accent,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: SpeakabooTheme.headingSize,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.textPrimary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: SpeakabooTheme.spacingLg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, SpeakabooTheme.minTapTarget),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
