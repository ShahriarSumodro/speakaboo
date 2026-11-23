/// Character detail and switch bottom sheet.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class CharacterSheet extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final String greeting;
  final bool isLocked;
  final int priceBdt;
  final bool isCurrent;
  final VoidCallback onSelect;
  final VoidCallback? onUnlock;

  const CharacterSheet({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.greeting,
    this.isLocked = false,
    this.priceBdt = 0,
    this.isCurrent = false,
    required this.onSelect,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: const BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpeakabooTheme.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SpeakabooTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: SpeakabooTheme.headingSize,
                      fontWeight: FontWeight.bold,
                      color: SpeakabooTheme.textPrimary,
                    ),
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SpeakabooTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                    ),
                    child: Text(
                      '$priceBdt BDT',
                      style: const TextStyle(
                        fontSize: SpeakabooTheme.captionSize,
                        fontWeight: FontWeight.bold,
                        color: SpeakabooTheme.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Text(
              description,
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
              decoration: BoxDecoration(
                color: SpeakabooTheme.background,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 20, color: SpeakabooTheme.accent),
                  const SizedBox(width: SpeakabooTheme.spacingSm),
                  Expanded(
                    child: Text(
                      '"$greeting"',
                      style: const TextStyle(
                        fontSize: SpeakabooTheme.captionSize,
                        fontStyle: FontStyle.italic,
                        color: SpeakabooTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              height: SpeakabooTheme.minTapTarget,
              child: isLocked
                  ? FilledButton(
                      onPressed: onUnlock,
                      child: Text('Unlock for $priceBdt BDT'),
                    )
                  : FilledButton(
                      onPressed: isCurrent ? null : onSelect,
                      child: Text(isCurrent ? 'Current Companion' : 'Practice with $name'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
