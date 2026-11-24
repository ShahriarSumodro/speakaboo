/// Daily cap reached bottom sheet UX per DESIGN.md.
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/theme.dart';

class DailyCapSheet extends StatelessWidget {
  final VoidCallback? onUpgradePlay;
  final VoidCallback? onUpgradeBkash;
  final VoidCallback? onUpgradeNagad;
  final VoidCallback onRestore;
  final VoidCallback onDismiss;

  const DailyCapSheet({
    super.key,
    this.onUpgradePlay,
    this.onUpgradeBkash,
    this.onUpgradeNagad,
    required this.onRestore,
    required this.onDismiss,
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
            Container(
              key: const Key('streak_celebration_banner'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SpeakabooTheme.accent.withValues(alpha: 0.15),
                    SpeakabooTheme.warning.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                border: Border.all(
                  color: SpeakabooTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔥 Today\'s Speaking Streak Secured!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: SpeakabooTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Daily habit locked in. Consistency over intensity (Fogg 2009)',
                          style: TextStyle(
                            fontSize: 11,
                            color: SpeakabooTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            if (isPlay) ...[
              // Google Play In-App Purchase
              SizedBox(
                width: double.infinity,
                height: SpeakabooTheme.minTapTarget,
                child: ElevatedButton.icon(
                  onPressed: onUpgradePlay,
                  icon: const Icon(Icons.shop_outlined, color: Colors.white),
                  label: const Text(
                    'Upgrade Pro with Google Play (200 BDT/mo)',
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
            ],
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
