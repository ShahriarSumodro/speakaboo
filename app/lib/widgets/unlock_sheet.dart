/// Paywall and character unlock bottom sheet.
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/theme.dart';

class UnlockSheet extends StatelessWidget {
  final String title;
  final String priceText;
  final VoidCallback? onPayWithPlay;
  final VoidCallback? onPayWithBkash;
  final VoidCallback? onPayWithNagad;
  final VoidCallback? onRestore;

  const UnlockSheet({
    super.key,
    required this.title,
    required this.priceText,
    this.onPayWithPlay,
    this.onPayWithBkash,
    this.onPayWithNagad,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isPlay = AppConfig.isPlayFlavor;

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
            if (isPlay) ...[
              // Google Play In-App Billing Button
              SizedBox(
                width: double.infinity,
                height: SpeakabooTheme.minTapTarget,
                child: ElevatedButton.icon(
                  onPressed: onPayWithPlay,
                  icon: const Icon(Icons.shop_outlined, color: Colors.white),
                  label: const Text(
                    'Unlock with Google Play',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01875F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Direct Distribution: bKash & Nagad
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
            ],
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onRestore != null)
                  TextButton(
                    onPressed: onRestore,
                    child: const Text('Restore Purchases'),
                  )
                else
                  const SizedBox(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
