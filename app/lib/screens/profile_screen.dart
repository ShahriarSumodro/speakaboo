/// Profile screen - learner stats, vocabulary notebook, parent dashboard.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
        title: const Text(
          'Learner Profile',
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
          // Header Card
          _buildUserCard(),
          const SizedBox(height: SpeakabooTheme.spacingLg),

          // Stats Grid
          _buildStatsRow(),
          const SizedBox(height: SpeakabooTheme.spacingLg),

          // Vocabulary Notebook preview
          _buildVocabularyCard(context),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Parent Dashboard link
          _buildParentDashboardCard(context),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: SpeakabooTheme.accent,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: SpeakabooTheme.spacingMd),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learner (Anonymous)',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Free Plan • 10 min/day',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    color: SpeakabooTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildMetricTile('Level 2', 'Learner Tier', Icons.military_tech)),
        const SizedBox(width: SpeakabooTheme.spacingSm),
        Expanded(child: _buildMetricTile('240 XP', 'Total Points', Icons.stars)),
        const SizedBox(width: SpeakabooTheme.spacingSm),
        Expanded(child: _buildMetricTile('3 Days', 'Streak', Icons.local_fire_department)),
      ],
    );
  }

  Widget _buildMetricTile(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: SpeakabooTheme.accent, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: SpeakabooTheme.baseFontSize,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: SpeakabooTheme.smallSize,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: SpeakabooTheme.accent, size: 22),
              SizedBox(width: SpeakabooTheme.spacingSm),
              Text(
                'Vocabulary Notebook',
                style: TextStyle(
                  fontSize: SpeakabooTheme.baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          const Text(
            '3 words saved with spaced repetition review.',
            style: TextStyle(
              fontSize: SpeakabooTheme.captionSize,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingSm),
          Wrap(
            spacing: 6,
            children: const [
              Chip(label: Text('harvest', style: TextStyle(fontSize: 12))),
              Chip(label: Text('monsoon', style: TextStyle(fontSize: 12))),
              Chip(label: Text('fertile', style: TextStyle(fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentDashboardCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom, color: SpeakabooTheme.accent, size: 28),
          const SizedBox(width: SpeakabooTheme.spacingMd),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parent Dashboard',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
                Text(
                  'Review weekly minutes, words, and safety filter alerts.',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    color: SpeakabooTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Parent summary: 12.5 mins spoken, 0 safety flags')),
              );
            },
          ),
        ],
      ),
    );
  }
}
