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
import '../widgets/share_progress_card.dart';
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
  ReferralInfo? _referral;
  int _vocabCount = 0;

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
      });
    }

    try {
      final prog = await api.getProgress(auth.userId);
      final usage = await api.getUsage(auth.userId);
      final cards = await api.getVocabulary(auth.userId);
      ReferralInfo? ref;
      try {
        ref = await api.getReferralInfo(auth.userId);
      } catch (_) {}

      setState(() {
        _progress = prog;
        _usage = usage;
        _referral = ref;
        _vocabCount = cards.length;
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
    }
  }

  void _showClaimReferralDialog() {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Referral Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a friend\'s Speakaboo referral code to claim 50 bonus XP and a streak freeze!',
              style: TextStyle(fontSize: SpeakabooTheme.captionSize),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Referral Code',
                hintText: 'e.g. SPK-ABC123',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final res = await api.claimReferral(
                  refereeUserId: auth.userId,
                  referralCode: code,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Referral reward claimed!'),
                      backgroundColor: context.colors.success,
                    ),
                  );
                }
                _loadStats();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to claim: $e'),
                      backgroundColor: context.colors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Claim Reward'),
          ),
        ],
      ),
    );
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
                initialValue: ageBand,
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
    final colors = context.colors;

    final displayName = profile?.displayName ?? 'Learner';
    final level = profile?.level.toUpperCase() ?? 'BEGINNER';
    final plan = _usage?.plan.toUpperCase() ?? 'FREE PLAN';
    final xp = _progress?.xp ?? 0;
    final streak = _progress?.streakDays ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(
          'Learner Profile',
          style: TextStyle(
            fontSize: SpeakabooTheme.headingSize,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colors.textPrimary),
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
                color: colors.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colors.accent,
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
                          style: TextStyle(
                            fontSize: SpeakabooTheme.baseFontSize + 2,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$plan • ${profile?.dailyGoalMinutes ?? 10} min/day goal',
                          style: TextStyle(
                            fontSize: SpeakabooTheme.captionSize,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: colors.accent),
                    tooltip: 'Edit Profile',
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),

            // Dual Identity & CEFR Milestone Progress Card (CD-009)
            _buildMilestoneCard(
              level: level,
              weeklyMinutes: _progress?.weeklyMinutes ?? 0.0,
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),

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
            Text(
              'Practice Modes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, color: colors.accent, size: 28),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vocabulary Notebook',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '$_vocabCount saved word(s) with Leitner spaced repetition.',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.textSecondary),
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.family_restroom, color: colors.accent, size: 28),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parent Dashboard',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Review weekly speaking minutes, words, and safety filter alerts.',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),

            // Share Progress Social Card
            InkWell(
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              onTap: () {
                ShareProgressCard.show(
                  context,
                  streakDays: _progress?.streakDays ?? 0,
                  level: _progress?.level ?? 'beginner',
                  xp: _progress?.xp ?? 0,
                  weeklyMinutes: _progress?.weeklyMinutes ?? 0.0,
                  referralCode: _referral?.referralCode ?? 'SPEAKABOO',
                );
              },
              child: Container(
                padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.isDarkMode
                        ? const [Color(0xFF2A221D), Color(0xFF1B1613)]
                        : const [Color(0xFF3E2723), Color(0xFF2E1C14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.share, color: colors.accent, size: 28),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Share My Progress Card',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Show friends on WhatsApp & Facebook your speaking streak!',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: Color(0xFFC4B8B0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: colors.accent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),

            // Referral & Rewards Tile
            Container(
              padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: colors.accent, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Refer Friends (+100 XP)',
                        style: TextStyle(
                          fontSize: SpeakabooTheme.baseFontSize,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Code: ${_referral?.referralCode ?? "..."}',
                        style: TextStyle(
                          fontSize: SpeakabooTheme.captionSize,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_referral?.referralCount ?? 0} friends joined. ${_referral?.xpEarned ?? 0} XP earned.',
                    style: TextStyle(
                      fontSize: SpeakabooTheme.captionSize,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showClaimReferralDialog,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Enter Code'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            ShareProgressCard.show(
                              context,
                              streakDays: _progress?.streakDays ?? 0,
                              level: _progress?.level ?? 'beginner',
                              xp: _progress?.xp ?? 0,
                              weeklyMinutes: _progress?.weeklyMinutes ?? 0.0,
                              referralCode: _referral?.referralCode ?? 'SPEAKABOO',
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Invite Friends'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard({required String level, required double weeklyMinutes}) {
    final colors = context.colors;
    final lvl = level.toLowerCase();
    String emotionalIdentity;
    String cefrMilestone;
    String nextMilestone;
    double targetMinutes;

    if (lvl.contains('inter')) {
      emotionalIdentity = 'Confident Everyday Speaker';
      cefrMilestone = 'CEFR B1-B2 Milestone';
      nextMilestone = 'Fluent Conversationalist (CEFR C1)';
      targetMinutes = 45.0;
    } else if (lvl.contains('adv')) {
      emotionalIdentity = 'Fluent Conversationalist';
      cefrMilestone = 'CEFR C1 Milestone';
      nextMilestone = 'Master Storyteller';
      targetMinutes = 60.0;
    } else {
      emotionalIdentity = 'Curious Daily Explorer';
      cefrMilestone = 'CEFR A1-A2 Milestone';
      nextMilestone = 'Confident Speaker (CEFR B1)';
      targetMinutes = 30.0;
    }

    final progressRatio = (weeklyMinutes / targetMinutes).clamp(0.0, 1.0);

    return Container(
      key: const Key('cefr_identity_card'),
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
        border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_outlined, size: 20, color: colors.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emotionalIdentity,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      cefrMilestone,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  '${(progressRatio * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: colors.accent,
                side: BorderSide(color: colors.accent),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 6,
              backgroundColor: colors.background,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${weeklyMinutes.toStringAsFixed(1)} / ${targetMinutes.toInt()} mins this week',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              Text(
                'Next: $nextMilestone',
                style: TextStyle(fontSize: 11, color: colors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String value, String label, IconData icon) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accent, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({required String title, required IconData icon, required VoidCallback onTap}) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.accent, size: 22),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
