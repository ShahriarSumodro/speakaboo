/// Characters screen - browsing and selecting speaking companions from the backend.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/character.dart';
import '../providers/conversation_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../widgets/playful/playful.dart';
import 'character_detail_screen.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  List<Character> _characters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final api = context.read<ApiService>();

    // Rapid cached rendering
    final cached = await CacheService.get('characters_list');
    if (cached is List) {
      setState(() {
        _characters = cached.map((c) => Character.fromJson(c as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }

    try {
      final remote = await api.getCharacters();
      setState(() {
        _characters = remote;
        _isLoading = false;
      });
      await CacheService.set('characters_list', remote.map((c) => c.toJson()).toList());
    } catch (_) {
      if (_characters.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = context.watch<ConversationProvider>();
    final currentId = conv.currentCharacterId ?? (conv.conversationId != null ? 'rule_farmer' : '');
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(
          'Speaking Companions',
          style: TextStyle(
            fontSize: SpeakabooTheme.headingSize,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const PlayfulLoadingState(message: 'Calling your companions...')
          : _characters.isEmpty
              ? PlayfulEmptyState(
                  title: 'Companions are on the way!',
                  message: 'Connect to the backend or pull down to refresh your speaking friends.',
                  actionLabel: 'Refresh',
                  onAction: _loadCharacters,
                )
              : RefreshIndicator(
                  onRefresh: _loadCharacters,
                  color: colors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                    itemCount: _characters.length,
                    itemBuilder: (context, index) {
                      final c = _characters[index];
                      final isCurrent = c.id == currentId;
                      final isLocked = !c.isFree;
                      final washes = [
                        colors.pastelMint,
                        colors.pastelSky,
                        colors.pastelLavender,
                        colors.pastelPink,
                      ];
                      final cardBg = washes[index % washes.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: SpeakabooTheme.spacingMd),
                        child: PlayfulCard(
                          backgroundColor: cardBg,
                          border: isCurrent
                              ? Border.all(color: colors.primary, width: 2.5)
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CharacterDetailScreen(character: c),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              PlayfulCharacter(
                                characterId: c.id,
                                mood: isCurrent ? CharacterMood.celebrating : CharacterMood.idle,
                                size: 64,
                              ),
                              const SizedBox(width: SpeakabooTheme.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: SpeakabooTheme.displayStyle(
                                        color: colors.textPrimary,
                                        size: SpeakabooTheme.subheadingSize,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.tagline,
                                      style: SpeakabooTheme.bodyStyle(
                                        color: colors.textSecondary,
                                        size: SpeakabooTheme.captionSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: SpeakabooTheme.spacingSm),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: SpeakabooTheme.bodyStyle(
                                      color: colors.onPrimary,
                                      size: 12,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              else if (isLocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                                    border: Border.all(color: colors.borderSubtle),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline_rounded, size: 14, color: colors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${c.priceBdt} BDT',
                                        style: SpeakabooTheme.bodyStyle(
                                          color: colors.textPrimary,
                                          size: 12,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
