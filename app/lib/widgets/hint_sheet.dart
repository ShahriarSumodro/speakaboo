/// Hint and rescue bottom sheet ("Help me say it").
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';

class HintSheet extends StatelessWidget {
  final ConversationHint hint;

  const HintSheet({super.key, required this.hint});

  static Future<void> show(BuildContext context, ConversationHint hint) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HintSheet(hint: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: const BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SpeakabooTheme.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SpeakabooTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb, color: SpeakabooTheme.accent, size: 24),
              ),
              const SizedBox(width: SpeakabooTheme.spacingMd),
              const Expanded(
                child: Text(
                  'Help Me Say It',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.headingSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: SpeakabooTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Sentence starter
          const Text(
            'Sentence Starter:',
            style: TextStyle(
              fontSize: SpeakabooTheme.captionSize,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              border: Border.all(color: SpeakabooTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              hint.sentenceStarter,
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Model answer
          const Text(
            'Example Answer:',
            style: TextStyle(
              fontSize: SpeakabooTheme.captionSize,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
            ),
            child: Text(
              hint.modelAnswer,
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Target vocabulary
          if (hint.vocabularyHints.isNotEmpty) ...[
            const Text(
              'Helpful Words:',
              style: TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: hint.vocabularyHints.map((word) {
                return Chip(
                  label: Text(
                    word,
                    style: const TextStyle(
                      fontSize: SpeakabooTheme.captionSize,
                      color: SpeakabooTheme.textPrimary,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
          ],

          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it! Hold mic to speak'),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
        ],
      ),
    );
  }
}
