/// Conversation topics selection screen.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  List<TopicItem> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final api = context.read<ApiService>();

    final cached = await CacheService.get('topics_cache');
    if (cached is List) {
      setState(() {
        _topics = cached.map((t) => TopicItem.fromJson(t as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }

    try {
      final remote = await api.getTopics();
      setState(() {
        _topics = remote;
        _isLoading = false;
      });
      await CacheService.set('topics_cache', remote.map((t) => {
        'id': t.id,
        'title': t.title,
        'category': t.category,
        'difficulty': t.difficulty,
        'starters': t.starters,
      }).toList());
    } catch (_) {
      if (_topics.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTopic(TopicItem topic) {
    final auth = context.read<AuthProvider>();
    final conv = context.read<ConversationProvider>();

    conv.startConversation(
      userId: auth.userId,
      characterId: conv.currentCharacterId ?? 'rule_farmer',
      topicId: topic.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Topic set to: ${topic.title}')),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation Topics', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? Center(child: Text('No topics available.', style: TextStyle(color: colors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final t = _topics[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd)),
                      child: ExpansionTile(
                        title: Text(t.title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        subtitle: Text('${t.category} • ${t.difficulty.toUpperCase()}', style: TextStyle(color: colors.textSecondary)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Discussion Starters:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                                const SizedBox(height: 6),
                                ...t.starters.map((starter) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('• "$starter"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: colors.textSecondary)),
                                    )),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _startTopic(t),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.accent,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Practice This Topic'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
