/// Correction chip widget - shows correction detail inline.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class CorrectionChip extends StatelessWidget {
  final CorrectionData correction;

  const CorrectionChip({super.key, required this.correction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: SpeakabooTheme.spacingSm),
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
        border: Border.all(
          color: SpeakabooTheme.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: SpeakabooTheme.accent,
              ),
              const SizedBox(width: 4),
              Text(
                'Correction',
                style: TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  fontWeight: FontWeight.w600,
                  color: SpeakabooTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '"${correction.original}"',
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize,
                    color: SpeakabooTheme.error,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const TextSpan(
                  text: '  →  ',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize,
                    color: SpeakabooTheme.textSecondary,
                  ),
                ),
                TextSpan(
                  text: '"${correction.better}"',
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize,
                    color: SpeakabooTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (correction.reasonShort.isNotEmpty) ...[
            const SizedBox(height: SpeakabooTheme.spacingXs),
            Text(
              correction.reasonShort,
              style: const TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: SpeakabooTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
