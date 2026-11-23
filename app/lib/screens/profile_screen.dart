/// Profile screen - connected to real learner profile, progress, vocabulary, and parent portal.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../models/usage_info.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'parent_dashboard_screen.dart';
import 'scenarios_screen.dart';
import 'settings_screen.dart';
import 'shadowing_screen.dart';
import 'topics_screen.dart';
import 'vocabulary_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LearningProgress? _progress;
  UsageInfo? _usage;
  int _vocabCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    // Instant cached state
    final cachedProg = await CacheService.get('prog_${auth.userId}');
    if (cachedProg is Map<String, dynamic>) {
      setState(() {
        _progress = LearningProgress.fromJson(cachedProg);
        _isLoading = false;
      });
    }

    try {
      final prog = await api.getProgress(auth.userId);
      final usage = await api.getUsage(auth.userId);
      final cards = await api.getVocabulary(auth.userId);

      setState(() {
        _progress = prog;
        _usage = usage;
        _vocabCount = cards.length;
        _isLoading = false;
      });

      await CacheService.set('prog_${auth.userId}', {
        'user_id': prog.userId,
        'level': prog.level,
        'xp': prog.xp,
        'total_words_spoken': prog.totalWordsSpoken,
        'streak_days': prog.streakDays,
        'weekly_minutes': prog.weeklyMinutes,
        'accuracy_score': prog.accuracyScore,
      });
    } catch (_) {
      if (_progress == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProfileDialog() {
    final auth = context.read<AuthProvider>();
    final nameController = TextEditingController(text: auth.profile?.displayName ?? '');
    String ageBand = auth.profile?.ageBand ?? 'adult';
    int dailyMinutes = auth.profile?.dailyGoalMinutes ?? 10;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ageBand,
                decoration: const InputDecoration(labelText: 'Age Band'),
                items: const [
                  DropdownMenuItem(value: 'kid', child: Text('Kid (6-12)')),
                  DropdownMenuItem(value: 'teen', child: Text('Teen (13-17)')),
                  DropdownMenuItem(value: 'adult', child: Text('Adult (18+)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => ageBand = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Goal:'),
                  DropdownButton<int>(
                    value: dailyMinutes,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 min/day')),
                      DropdownMenuItem(value: 10, child: Text('10 min/day')),
                      DropdownMenuItem(value: 15, child: Text('15 min/day')),
                      DropdownMenuItem(value: 20, child: Text('20 min/day')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => dailyMinutes = val);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.updateProfile({
                  'display_name': nameController.text.trim(),
                  'age_band': ageBand,
                  'daily_goal_minutes': dailyMinutes,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    final displayName = profile?.displayName ?? 'Learner';
    final level = profile?.level.toUpperCase() ?? 'BEGINNER';
    final plan = _usage?.plan.toUpperCase() ?? 'FREE PLAN';
    final xp = _progress?.xp ?? 0;
    final streak = _progress?.streakDays ?? 0;
    final wordsSpoken = _progress?.totalWordsSpoken ?? 0;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: SpeakabooTheme.textPrimary),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
              decoration: BoxDecoration(
                color: SpeakabooTheme.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: SpeakabooTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'L',
                        style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: SpeakabooTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: SpeakabooTheme.baseFontSize + 2,
                            fontWeight: FontWeight.bold,
                            color: SpeakabooTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$plan • ${profile?.dailyGoalMinutes ?? 10} min/day goal',
                          style: const TextStyle(
                            fontSize: SpeakabooTheme.captionSize,
                            color: SpeakabooTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: SpeakabooTheme.accent),
                    tooltip: 'Edit Profile',
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),

            // Metrics Row
            Row(
              children: [
                Expanded(child: _buildMetricTile(level, 'Speaking Level', Icons.military_tech)),
                const SizedBox(width: SpeakabooTheme.spacingSm),
                Expanded(child: _buildMetricTile('$xp XP', 'Points Earned', Icons.stars)),
                const SizedBox(width: SpeakabooTheme.spacingSm),
                Expanded(child: _buildMetricTile('$streak Days', 'Daily Streak', Icons.local_fire_department)),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),

            // Practice Modes Quick Access
            const Text(
              'Practice Modes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SpeakabooTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    title: 'Scenarios',
                    icon: Icons.movie_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScenariosScreen())),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionTile(
                    title: 'Topics',
                    icon: Icons.chat_bubble_outline,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicsScreen())),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionTile(
                    title: 'Shadowing',
                    icon: Icons.record_voice_over_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShadowingScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),

            // Vocabulary Notebook Card
            InkWell(
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                decoration: BoxDecoration(
                  color: SpeakabooTheme.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: SpeakabooTheme.accent, size: 28),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vocabulary Notebook',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: SpeakabooTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '$_vocabCount saved word(s) with Leitner spaced repetition.',
                            style: const TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: SpeakabooTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: SpeakabooTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),

            // Parent Dashboard Card
            InkWell(
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDashboardScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                decoration: BoxDecoration(
                  color: SpeakabooTheme.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.family_restroom, color: SpeakabooTheme.accent, size: 28),
                    SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
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
                            'Review weekly speaking minutes, words, and safety filter alerts.',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: SpeakabooTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: SpeakabooTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          Icon(icon, color: SpeakabooTheme.accent, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: SpeakabooTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: SpeakabooTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: SpeakabooTheme.surface,
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, color: SpeakabooTheme.accent, size: 22),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
