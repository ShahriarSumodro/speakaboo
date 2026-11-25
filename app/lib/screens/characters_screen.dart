/// Characters screen - browsing and selecting speaking companions from the backend.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/character.dart';
import '../providers/conversation_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : _characters.isEmpty
              ? Center(
                  child: Text(
                    'No companions found. Connect to backend.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCharacters,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                    itemCount: _characters.length,
                    itemBuilder: (context, index) {
                      final c = _characters[index];
                      final isCurrent = c.id == currentId;
                      final isLocked = !c.isFree;

                      return Container(
                        margin: const EdgeInsets.only(bottom: SpeakabooTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                          border: isCurrent
                              ? Border.all(color: colors.accent, width: 2)
                              : null,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CharacterDetailScreen(character: c),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colors.background,
                                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                                  ),
                                  child: Icon(
                                    isLocked ? Icons.lock_outline : Icons.face,
                                    color: isLocked ? colors.textSecondary : colors.accent,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: SpeakabooTheme.spacingMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: TextStyle(
                                          fontSize: SpeakabooTheme.baseFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.tagline,
                                        style: TextStyle(
                                          fontSize: SpeakabooTheme.captionSize,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Chip(
                                    label: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: colors.accent,
                                    side: BorderSide(color: colors.accent),
                                    visualDensity: VisualDensity.compact,
                                  )
                                else if (isLocked)
                                  Text(
                                    '${c.priceBdt} BDT',
                                    style: TextStyle(
                                      fontSize: SpeakabooTheme.captionSize,
                                      fontWeight: FontWeight.bold,
                                      color: colors.accent,
                                    ),
                                  ),
                              ],
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
