/// Real-life role-play scenarios screen.
library;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaking Scenarios'),
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
              ? const Center(child: Text('No scenarios found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                  itemCount: _scenarios.length,
                  itemBuilder: (context, index) {
                    final s = _scenarios[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: SpeakabooTheme.surface,
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Chip(
                                  label: Text(s.difficulty.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: SpeakabooTheme.accent,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(s.description, style: const TextStyle(color: SpeakabooTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 10),
                            if (s.goals.isNotEmpty) ...[
                              const Text('Goals:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              const SizedBox(height: 4),
                              ...s.goals.map((g) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 14, color: SpeakabooTheme.accent),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(g, style: const TextStyle(fontSize: 12))),
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
                                onPressed: () => _startScenario(s),
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
