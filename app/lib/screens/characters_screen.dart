/// Characters screen - browsing and switching speaking companions.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/conversation_provider.dart';
import '../widgets/character_sheet.dart';
import '../widgets/unlock_sheet.dart';

class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key});

  static const List<Map<String, dynamic>> _characters = [
    {
      'id': 'rule_farmer',
      'name': 'Farmer Reggie',
      'tagline': 'Rules & Farming Metaphors',
      'description': 'An intense, rule-obsessed farmer who takes spoken English very seriously! Pulls mistakes like weeds.',
      'greeting': 'Welcome to my farm! Every word you plant here will grow strong.',
      'locked': false,
      'price_bdt': 0,
      'voice_id': 'Arista-PlayAI',
    },
    {
      'id': 'dhaka_detective',
      'name': 'Detective Kabir',
      'tagline': 'Mystery & Logic Practice',
      'description': 'A sharp and witty private investigator in Old Dhaka who helps you solve English sentence clues.',
      'greeting': 'Aha! Let us examine the evidence of your spoken English together.',
      'locked': true,
      'price_bdt': 350,
      'voice_id': 'Kabir-Voice',
    },
    {
      'id': 'eco_scholar',
      'name': 'Professor Anika',
      'tagline': 'Nature & Science Conversations',
      'description': 'A warm and thoughtful researcher who loves discussing geography, wildlife, and technology.',
      'greeting': 'Hello learner! Every journey of discovery starts with a single spoken sentence.',
      'locked': true,
      'price_bdt': 350,
      'voice_id': 'Anika-Voice',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final conv = context.watch<ConversationProvider>();
    final currentId = conv.conversationId != null ? 'rule_farmer' : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
        title: const Text(
          'Speaking Companions',
          style: TextStyle(
            fontSize: SpeakabooTheme.headingSize,
            fontWeight: FontWeight.bold,
            color: SpeakabooTheme.textPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final c = _characters[index];
          final isCurrent = c['id'] == currentId;
          final isLocked = c['locked'] as bool;

          return Container(
            margin: const EdgeInsets.only(bottom: SpeakabooTheme.spacingMd),
            decoration: BoxDecoration(
              color: SpeakabooTheme.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              border: isCurrent
                  ? Border.all(color: SpeakabooTheme.accent, width: 2)
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => CharacterSheet(
                    id: c['id'],
                    name: c['name'],
                    description: c['description'],
                    greeting: c['greeting'],
                    isLocked: isLocked,
                    priceBdt: c['price_bdt'],
                    isCurrent: isCurrent,
                    onSelect: () {
                      Navigator.pop(ctx);
                      conv.startConversation(
                        userId: 'device-user',
                        characterId: c['id'],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to ${c['name']}')),
                      );
                    },
                    onUnlock: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => UnlockSheet(
                          title: c['name'],
                          priceText: '${c['price_bdt']} BDT',
                          onPayWithBkash: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mock bKash payment initiated')),
                            );
                          },
                          onPayWithNagad: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mock Nagad payment initiated')),
                            );
                          },
                        ),
                      );
                    },
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
                        color: SpeakabooTheme.background,
                        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline : Icons.face,
                        color: isLocked ? SpeakabooTheme.textSecondary : SpeakabooTheme.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['name'],
                            style: const TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: SpeakabooTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c['tagline'],
                            style: const TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: SpeakabooTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      const Chip(
                        label: Text('Active', style: TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: SpeakabooTheme.accent,
                        visualDensity: VisualDensity.compact,
                      )
                    else if (isLocked)
                      Text(
                        '${c['price_bdt']} BDT',
                        style: const TextStyle(
                          fontSize: SpeakabooTheme.captionSize,
                          fontWeight: FontWeight.bold,
                          color: SpeakabooTheme.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
