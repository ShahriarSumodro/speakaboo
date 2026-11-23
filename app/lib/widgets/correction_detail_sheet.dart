/// Detailed correction bottom sheet.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class CorrectionDetailSheet extends StatelessWidget {
  final CorrectionData correction;

  const CorrectionDetailSheet({super.key, required this.correction});

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
                const Icon(Icons.lightbulb_outline, color: SpeakabooTheme.accent, size: 24),
                const SizedBox(width: SpeakabooTheme.spacingSm),
                const Text(
                  'Grammar & Speaking Tip',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.headingSize - 4,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            const Text(
              'What you said:',
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"${correction.original}"',
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.error,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            const Text(
              'Natural English:',
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"${correction.better}"',
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize + 1,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.success,
              ),
            ),
            if (correction.reasonShort.isNotEmpty) ...[
              const SizedBox(height: SpeakabooTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                decoration: BoxDecoration(
                  color: SpeakabooTheme.background,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
                child: Text(
                  correction.reasonShort,
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize - 1,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: SpeakabooTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              height: SpeakabooTheme.minTapTarget,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
