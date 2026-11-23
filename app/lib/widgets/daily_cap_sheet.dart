/// Daily cap reached bottom sheet UX per DESIGN.md.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class DailyCapSheet extends StatelessWidget {
  final VoidCallback onUpgradeBkash;
  final VoidCallback onUpgradeNagad;
  final VoidCallback onRestore;
  final VoidCallback onDismiss;

  const DailyCapSheet({
    super.key,
    required this.onUpgradeBkash,
    required this.onUpgradeNagad,
    required this.onRestore,
    required this.onDismiss,
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
                Container(
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: SpeakabooTheme.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: SpeakabooTheme.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: SpeakabooTheme.spacingSm),
                const Expanded(
                  child: Text(
                    'Daily Practice Completed! 🌟',
                    style: TextStyle(
                      fontSize: SpeakabooTheme.headingSize,
                      fontWeight: FontWeight.bold,
                      color: SpeakabooTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            const Text(
              'Awesome work practicing today! Your streak is saved. You can practice again tomorrow after midnight (Asia/Dhaka) or upgrade to Speakaboo Pro for unlimited learning.',
              style: TextStyle(
                fontSize: SpeakabooTheme.baseFontSize,
                color: SpeakabooTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
            // bKash Button
            SizedBox(
              width: double.infinity,
              height: SpeakabooTheme.minTapTarget,
              child: ElevatedButton(
                onPressed: onUpgradeBkash,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2136E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Upgrade Pro with bKash (200 BDT/mo)',
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
                onPressed: onUpgradeNagad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7921E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Upgrade Pro with Nagad (200 BDT/mo)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onRestore,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(color: SpeakabooTheme.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text(
                    'Come Back Tomorrow',
                    style: TextStyle(
                      color: SpeakabooTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
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
