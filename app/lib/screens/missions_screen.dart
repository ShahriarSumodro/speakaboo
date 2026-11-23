/// Missions screen - daily goals, streaks, and XP rewards.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  // Mock missions data for instant responsive UI
  final List<Map<String, dynamic>> _missions = [
    {
      'id': 'm_speak_3m',
      'title': 'Daily Speaker',
      'description': 'Speak for at least 3 minutes today',
      'target': 3.0,
      'current': 1.8,
      'reward': 50,
      'completed': false,
      'claimed': false,
    },
    {
      'id': 'm_new_words_3',
      'title': 'Word Explorer',
      'description': 'Learn or use 3 new vocabulary words',
      'target': 3.0,
      'current': 3.0,
      'reward': 40,
      'completed': true,
      'claimed': false,
    },
    {
      'id': 'm_complete_scene',
      'title': 'Scenario Master',
      'description': 'Complete 1 real-life speaking scenario',
      'target': 1.0,
      'current': 0.0,
      'reward': 60,
      'completed': false,
      'claimed': false,
    },
    {
      'id': 'm_shadowing_1',
      'title': 'Echo Speaker',
      'description': 'Complete 1 shadowing practice session',
      'target': 1.0,
      'current': 1.0,
      'reward': 50,
      'completed': true,
      'claimed': true,
    },
  ];

  final int _streakDays = 3;
  final int _streakFreezes = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
        title: const Text(
          'Daily Missions',
          style: TextStyle(
            fontSize: SpeakabooTheme.headingSize,
            fontWeight: FontWeight.bold,
            color: SpeakabooTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        children: [
          // Streak Card
          _buildStreakCard(),
          const SizedBox(height: SpeakabooTheme.spacingLg),
          const Text(
            "Today's Goals",
            style: TextStyle(
              fontSize: SpeakabooTheme.headingSize - 4,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textPrimary,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          ..._missions.map(_buildMissionCard),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SpeakabooTheme.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: SpeakabooTheme.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: SpeakabooTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streakDays Day Streak!',
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.headingSize - 4,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Practice today to keep it going (Asia/Dhaka)',
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    color: SpeakabooTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.ac_unit, color: Colors.blueAccent, size: 22),
              const SizedBox(height: 2),
              Text(
                '$_streakFreezes freeze',
                style: const TextStyle(
                  fontSize: SpeakabooTheme.smallSize,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> m) {
    final double progress = ((m['current'] as double) / (m['target'] as double)).clamp(0.0, 1.0);
    final bool completed = m['completed'] as bool;
    final bool claimed = m['claimed'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: SpeakabooTheme.spacingMd),
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m['title'],
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SpeakabooTheme.background,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                ),
                child: Text(
                  '+${m['reward']} XP',
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            m['description'],
            style: const TextStyle(
              fontSize: SpeakabooTheme.captionSize,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: SpeakabooTheme.background,
              valueColor: const AlwaysStoppedAnimation<Color>(SpeakabooTheme.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${m['current']} / ${m['target']}',
                style: const TextStyle(
                  fontSize: SpeakabooTheme.smallSize,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              if (claimed)
                const Text(
                  'Claimed ✓',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.success,
                  ),
                )
              else if (completed)
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        m['claimed'] = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Claimed +${m['reward']} XP!')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Claim Reward'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
