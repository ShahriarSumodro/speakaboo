/// Real-life role-play scenarios screen.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  List<ScenarioItem> _scenarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    final api = context.read<ApiService>();

    final cached = await CacheService.get('scenarios_cache');
    if (cached is List) {
      setState(() {
        _scenarios = cached.map((s) => ScenarioItem.fromJson(s as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }

    try {
      final remote = await api.getScenarios();
      setState(() {
        _scenarios = remote;
        _isLoading = false;
      });
      await CacheService.set('scenarios_cache', remote.map((s) => {
        'id': s.id,
        'title': s.title,
        'category': s.category,
        'difficulty': s.difficulty,
        'description': s.description,
        'roles': s.roles,
        'goals': s.goals,
      }).toList());
    } catch (_) {
      if (_scenarios.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPreTaskSheet(ScenarioItem scenario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PreTaskScaffoldSheet(
        scenario: scenario,
        onStart: () {
          Navigator.pop(sheetContext);
          _startScenario(scenario);
        },
      ),
    );
  }

  void _startScenario(ScenarioItem scenario) {
    final auth = context.read<AuthProvider>();
    final conv = context.read<ConversationProvider>();

    conv.startConversation(
      userId: auth.userId,
      characterId: conv.currentCharacterId ?? 'rule_farmer',
      scenarioId: scenario.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting scenario: ${scenario.title}')),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text('Speaking Scenarios', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
              ? Center(child: Text('No scenarios found.', style: TextStyle(color: colors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                  itemCount: _scenarios.length,
                  itemBuilder: (context, index) {
                    final s = _scenarios[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd)),
                      child: Padding(
                        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                                  ),
                                ),
                                Chip(
                                  label: Text(s.difficulty.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: colors.accent,
                                  side: BorderSide(color: colors.accent),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(s.description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 10),
                            if (s.goals.isNotEmpty) ...[
                              Text('Goals:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textPrimary)),
                              const SizedBox(height: 4),
                              ...s.goals.map((g) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline, size: 14, color: colors.accent),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(g, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
                                      ],
                                    ),
                                  )),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Start Roleplay'),
                                onPressed: () => _showPreTaskSheet(s),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SpeakabooTheme.accent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _PreTaskScaffoldSheet extends StatefulWidget {
  final ScenarioItem scenario;
  final VoidCallback onStart;

  const _PreTaskScaffoldSheet({
    required this.scenario,
    required this.onStart,
  });

  @override
  State<_PreTaskScaffoldSheet> createState() => _PreTaskScaffoldSheetState();
}

class _PreTaskScaffoldSheetState extends State<_PreTaskScaffoldSheet> {
  int _secondsRemaining = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = widget.scenario;
    final primaryGoal = s.goals.isNotEmpty ? s.goals.first : 'Complete the task comfortably';
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SpeakabooTheme.radiusLg)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer_outlined, color: colors.accent, size: 24),
                ),
                const SizedBox(width: SpeakabooTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pre-Task Prep: ${s.title}',
                        style: TextStyle(
                          fontSize: SpeakabooTheme.headingSize,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Take 45s to plan your thoughts before speaking (Ellis 2005)',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SpeakabooTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_secondsRemaining}s',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SpeakabooTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingMd),
            _buildScaffoldCard(
              icon: Icons.flag_outlined,
              title: '1. What is your goal?',
              body: primaryGoal,
            ),
            const SizedBox(height: 8),
            _buildScaffoldCard(
              icon: Icons.chat_bubble_outline,
              title: '2. Starter phrases',
              body: '• "Hello, could you help me with..."\n• "I would like to..."\n• "Thank you very much."',
            ),
            const SizedBox(height: 8),
            _buildScaffoldCard(
              icon: Icons.hearing_outlined,
              title: '3. What to expect from partner',
              body: 'Listen to their greeting, pause for 1 second, and respond calmly.',
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),
            ElevatedButton.icon(
              key: const Key('ready_start_roleplay_btn'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Ready! Start Roleplay', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: widget.onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: SpeakabooTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffoldCard({required IconData icon, required String title, required String body}) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
        border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
