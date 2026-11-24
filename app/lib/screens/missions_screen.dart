/// Missions screen - connected to real backend daily goals and XP claims.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'scenarios_screen.dart';
import 'shadowing_screen.dart';
import 'vocabulary_screen.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  MissionsResponse? _missionsData;
  WordOfTheDay? _wordOfTheDay;
  bool _isLoading = true;
  bool _isRepairing = false;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    // Instant cached state
    final cached = await CacheService.get('missions_${auth.userId}');
    if (cached is Map<String, dynamic>) {
      setState(() {
        _missionsData = MissionsResponse.fromJson(cached);
        _isLoading = false;
      });
    }

    try {
      final remote = await api.getMissions(auth.userId);
      WordOfTheDay? wotd;
      try {
        wotd = await api.getWordOfTheDay();
      } catch (_) {}

      setState(() {
        _missionsData = remote;
        _wordOfTheDay = wotd;
        _isLoading = false;
      });
      await CacheService.set('missions_${auth.userId}', {
        'date': remote.date,
        'streak': remote.streak,
        'freezes': remote.freezes,
        'missions': remote.missions.map((m) => {
          'id': m.id,
          'title': m.title,
          'description': m.description,
          'xp_reward': m.xpReward,
          'target': m.target,
          'progress': m.progress,
          'completed': m.completed,
          'claimed': m.claimed,
          'category': m.category,
        }).toList(),
      });
    } catch (_) {
      if (_missionsData == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _repairStreak() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    setState(() => _isRepairing = true);
    try {
      final res = await api.repairStreak(auth.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Streak repaired! Welcome back!'),
            backgroundColor: SpeakabooTheme.success,
          ),
        );
      }
      await _loadMissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Streak repair: $e'),
            backgroundColor: SpeakabooTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRepairing = false);
    }
  }

  Future<void> _claimMission(Mission m) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    try {
      final res = await api.claimMission(userId: auth.userId, missionId: m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claimed +${res['xp_awarded'] ?? m.xpReward} XP!'),
            backgroundColor: SpeakabooTheme.success,
          ),
        );
      }
      _loadMissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not claim reward: $e')),
        );
      }
    }
  }

  void _startActivity(Mission m) {
    if (m.category == 'scenario') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScenariosScreen()));
    } else if (m.category == 'shadowing') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShadowingScreen()));
    } else if (m.category == 'vocabulary') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen()));
    } else {
      // General speaking practice - switch to talk tab (or notify user)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Go to the Talk tab to start practicing!')),
      );
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _missionsData == null
              ? const Center(child: Text('Could not load missions. Check connection.'))
              : RefreshIndicator(
                  onRefresh: _loadMissions,
                  child: ListView(
                    padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                    children: [
                      // Streak Card
                      _buildStreakCard(_missionsData!.streak, _missionsData!.freezes),
                      if (_missionsData!.streak == 0) ...[
                        const SizedBox(height: SpeakabooTheme.spacingMd),
                        _buildStreakRecoveryBanner(),
                      ],
                      if (_wordOfTheDay != null) ...[
                        const SizedBox(height: SpeakabooTheme.spacingMd),
                        _buildWordOfTheDayCard(_wordOfTheDay!),
                      ],
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
                      if (_missionsData!.missions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('All missions completed for today!')),
                        )
                      else
                        ..._missionsData!.missions.map(_buildMissionCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStreakCard(int streakDays, int streakFreezes) {
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
                  '$streakDays Day Streak!',
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.headingSize - 4,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Practice today to keep it going (Asia/Dhaka)',
                  style: TextStyle(
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
                '$streakFreezes freeze',
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

  Widget _buildMissionCard(Mission m) {
    final double progress = (m.progress / (m.target > 0 ? m.target : 1)).clamp(0.0, 1.0);

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
                  m.title,
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
                  '+${m.xpReward} XP',
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
            m.description,
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
                '${m.progress} / ${m.target}',
                style: const TextStyle(
                  fontSize: SpeakabooTheme.smallSize,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              if (m.claimed)
                const Text(
                  'Claimed ✓',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.success,
                  ),
                )
              else if (m.completed)
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () => _claimMission(m),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Claim Reward'),
                  ),
                )
              else
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _startActivity(m),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Start'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRecoveryBanner() {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
        border: Border.all(color: SpeakabooTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.healing, color: SpeakabooTheme.accent, size: 28),
          const SizedBox(width: SpeakabooTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Restore Your Streak',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.baseFontSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Missed a day? No guilt! Tap below to repair your habit streak.',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    color: SpeakabooTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: _isRepairing ? null : _repairStreak,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: _isRepairing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Repair'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordOfTheDayCard(WordOfTheDay wotd) {
    return Container(
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
              const Icon(Icons.lightbulb_outline, color: SpeakabooTheme.accent, size: 20),
              const SizedBox(width: 6),
              const Text(
                'Word of the Day',
                style: TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.accent,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                wotd.level.toUpperCase(),
                style: const TextStyle(
                  fontSize: SpeakabooTheme.smallSize,
                  fontStyle: FontStyle.italic,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                wotd.word,
                style: const TextStyle(
                  fontSize: SpeakabooTheme.headingSize - 2,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20, color: SpeakabooTheme.accent),
                tooltip: 'Listen to pronunciation',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pronunciation: "${wotd.word}" [${wotd.pronunciation}]'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Text(
                wotd.pronunciation,
                style: const TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                wotd.bengaliMeaning,
                style: const TextStyle(
                  fontSize: SpeakabooTheme.baseFontSize,
                  fontWeight: FontWeight.w600,
                  color: SpeakabooTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            wotd.definition,
            style: const TextStyle(
              fontSize: SpeakabooTheme.captionSize,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SpeakabooTheme.background,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote, size: 16, color: SpeakabooTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    wotd.example,
                    style: const TextStyle(
                      fontSize: SpeakabooTheme.smallSize,
                      fontStyle: FontStyle.italic,
                      color: SpeakabooTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.mic, size: 16),
              label: Text('Practice Saying "${wotd.word}" with Reggie!'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting talk session with focus word: ${wotd.word}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: SpeakabooTheme.accent,
                side: BorderSide(color: SpeakabooTheme.accent.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
