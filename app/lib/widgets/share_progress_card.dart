/// Shareable progress card for social proof & viral referral habit loop.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class ShareProgressCard extends StatelessWidget {
  final int streakDays;
  final String level;
  final int xp;
  final double weeklyMinutes;
  final String referralCode;

  const ShareProgressCard({
    super.key,
    required this.streakDays,
    required this.level,
    required this.xp,
    required this.weeklyMinutes,
    required this.referralCode,
  });

  static Future<void> show(
    BuildContext context, {
    required int streakDays,
    required String level,
    required int xp,
    required double weeklyMinutes,
    required String referralCode,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ShareProgressCard(
          streakDays: streakDays,
          level: level,
          xp: xp,
          weeklyMinutes: weeklyMinutes,
          referralCode: referralCode,
        ),
      ),
    );
  }

  String get _shareText =>
      "I'm on a $streakDays-day spoken English streak on Speakaboo! 🗣️✨ "
      "Practicing speaking with AI companions every day. "
      "Join me and use code $referralCode for 50 bonus XP!";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share Your Progress',
                style: TextStyle(
                  fontSize: SpeakabooTheme.headingSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: SpeakabooTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Visual badge card
          Container(
            padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A221D), Color(0xFF1B1613)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.record_voice_over, color: SpeakabooTheme.accent, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'SPEAKABOO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$streakDays Days', 'Speaking Streak', Icons.local_fire_department, Colors.orange),
                    _buildStatItem('Level $level', '$xp XP', Icons.bolt, Colors.amber),
                    _buildStatItem('${weeklyMinutes.toStringAsFixed(0)}m', 'Spoken This Week', Icons.timer, Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                  ),
                  child: Text(
                    'Referral Code: $referralCode',
                    style: const TextStyle(
                      color: SpeakabooTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingLg),

          // Share buttons
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress and referral link copied to clipboard!')),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Copy & Share to WhatsApp / Facebook'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Friends who join get 50 bonus XP. You receive 100 XP and a Free Streak Freeze!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String main, String sub, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          main,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
