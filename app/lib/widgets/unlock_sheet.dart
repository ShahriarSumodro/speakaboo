/// Paywall and character unlock bottom sheet.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class UnlockSheet extends StatelessWidget {
  final String title;
  final String priceText;
  final VoidCallback onPayWithBkash;
  final VoidCallback onPayWithNagad;

  const UnlockSheet({
    super.key,
    required this.title,
    required this.priceText,
    required this.onPayWithBkash,
    required this.onPayWithNagad,
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
            Text(
              'Unlock $title',
              style: const TextStyle(
                fontSize: SpeakabooTheme.headingSize,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.textPrimary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingXs),
            Text(
              'Practice unlimited spoken English ($priceText)',
              style: const TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.textSecondary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
            // bKash Button
            SizedBox(
              width: double.infinity,
              height: SpeakabooTheme.minTapTarget,
              child: ElevatedButton(
                onPressed: onPayWithBkash,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2136E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Pay with bKash',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            // Nagad Button
            SizedBox(
              width: double.infinity,
              height: SpeakabooTheme.minTapTarget,
              child: ElevatedButton(
                onPressed: onPayWithNagad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7921E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Pay with Nagad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
