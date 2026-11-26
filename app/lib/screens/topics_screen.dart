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
import '../widgets/playful/playful.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  List<TopicItem> _topics = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final api = context.read<ApiService>();
    if (mounted) {
      setState(() {
        if (_topics.isEmpty) _isLoading = true;
        _errorMessage = null;
      });
    }

    final cached = await CacheService.get('topics_cache');
    if (cached is List && _topics.isEmpty && mounted) {
      setState(() {
        _topics = cached.map((t) => TopicItem.fromJson(t as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }

    try {
      final remote = await api.getTopics();
      if (!mounted) return;
      setState(() {
        _topics = remote;
        _isLoading = false;
        _errorMessage = null;
      });
      await CacheService.set('topics_cache', remote.map((t) => {
        'id': t.id,
        'title': t.title,
        'category': t.category,
        'difficulty': t.difficulty,
        'starters': t.starters,
      }).toList());
    } catch (e) {
      debugPrint('[topics_screen] load failed: $e');
      final msg = e is ApiException
          ? e.message
          : 'Could not load topics. Check your server connection.';
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
      if (_topics.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadTopics,
          ),
        ],
      ),
      body: _isLoading
          ? const PlayfulLoadingState(message: 'Gathering fun topics...')
          : _topics.isEmpty
              ? PlayfulEmptyState(
                  title: _errorMessage != null ? 'Could not load topics' : 'Topics are being stocked!',
                  message: _errorMessage ?? 'Connect to the backend or pull to refresh for fresh conversation ideas.',
                  actionLabel: 'Refresh',
                  onAction: _loadTopics,
                )
              : RefreshIndicator(
                  onRefresh: _loadTopics,
                  child: ListView.builder(
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final t = _topics[index];
                    final washes = [
                      colors.pastelMint,
                      colors.pastelYellow,
                      colors.pastelSky,
                      colors.pastelLavender,
                      colors.pastelPink,
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: SpeakabooTheme.spacing12),
                      child: PlayfulCard(
                        backgroundColor: washes[index % washes.length],
                        padding: EdgeInsets.zero,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: SpeakabooTheme.spacingMd,
                              vertical: 4,
                            ),
                            title: Text(
                              t.title,
                              style: SpeakabooTheme.displayStyle(
                                color: colors.textPrimary,
                                size: SpeakabooTheme.subheadingSize,
                              ),
                            ),
                            subtitle: Text(
                              '${t.category} • ${t.difficulty.toUpperCase()}',
                              style: SpeakabooTheme.bodyStyle(
                                color: colors.textSecondary,
                                size: SpeakabooTheme.captionSize,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Discussion Starters:',
                                      style: SpeakabooTheme.bodyStyle(
                                        color: colors.textPrimary,
                                        size: SpeakabooTheme.captionSize,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...t.starters.map((starter) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            '• "$starter"',
                                            style: SpeakabooTheme.bodyStyle(
                                              color: colors.textSecondary,
                                              size: SpeakabooTheme.captionSize,
                                            ),
                                          ),
                                        )),
                                    const SizedBox(height: 12),
                                    PlayfulButton(
                                      label: 'Practice This Topic',
                                      icon: Icons.mic_rounded,
                                      fullWidth: true,
                                      onPressed: () => _startTopic(t),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      ),
                    );
                  },
                ),
                ),
    );
  }
}
