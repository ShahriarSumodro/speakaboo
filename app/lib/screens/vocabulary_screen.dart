/// Vocabulary notebook screen with Leitner box spaced repetition.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<VocabCard> _cards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedBoxFilter = 0; // 0 = all, 1-5 = specific box

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    // Instant cache retrieval
    final cached = await CacheService.get('vocab_${auth.userId}');
    if (cached is List) {
      setState(() {
        _cards = cached.map((c) => VocabCard.fromJson(c as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }

    try {
      final remoteCards = await api.getVocabulary(auth.userId);
      setState(() {
        _cards = remoteCards;
        _isLoading = false;
      });
      await CacheService.set('vocab_${auth.userId}', remoteCards.map((c) => {
        'id': c.id,
        'word': c.word,
        'definition': c.definition,
        'example': c.example,
        'box': c.box,
        'next_review': c.nextReview,
        'mastered': c.mastered,
        'ease_factor': c.easeFactor,
        'repetitions': c.repetitions,
      }).toList());
    } catch (_) {
      if (_cards.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddWordDialog() {
    final wordController = TextEditingController();
    final defController = TextEditingController();
    final exController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vocabulary Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: wordController, decoration: const InputDecoration(labelText: 'Word')),
            TextField(controller: defController, decoration: const InputDecoration(labelText: 'Definition')),
            TextField(controller: exController, decoration: const InputDecoration(labelText: 'Example Sentence')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (wordController.text.trim().isEmpty) return;
              final auth = context.read<AuthProvider>();
              final api = context.read<ApiService>();
              Navigator.pop(ctx);
              try {
                await api.addVocabulary(
                  userId: auth.userId,
                  word: wordController.text.trim(),
                  definition: defController.text.trim(),
                  example: exController.text.trim(),
                );
                _loadVocabulary();
              } catch (_) {}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(VocabCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Definition:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(card.definition),
            if (card.example.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Example:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('"${card.example}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Text('Box ${card.box} • Repetitions: ${card.repetitions}', style: const TextStyle(fontSize: 12, color: SpeakabooTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _submitReview(card.id, 'again'),
            child: const Text('Again', style: TextStyle(color: SpeakabooTheme.error)),
          ),
          TextButton(
            onPressed: () => _submitReview(card.id, 'hard'),
            child: const Text('Hard', style: TextStyle(color: SpeakabooTheme.warning)),
          ),
          TextButton(
            onPressed: () => _submitReview(card.id, 'good'),
            child: const Text('Good', style: TextStyle(color: SpeakabooTheme.accent)),
          ),
          ElevatedButton(
            onPressed: () => _submitReview(card.id, 'easy'),
            child: const Text('Easy'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(String cardId, String rating) async {
    Navigator.pop(context);
    final api = context.read<ApiService>();
    try {
      await api.reviewVocabulary(cardId: cardId, rating: rating);
      _loadVocabulary();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Card scheduled in Leitner box!')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _cards.where((c) {
      final matchesSearch = c.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.definition.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesBox = _selectedBoxFilter == 0 || c.box == _selectedBoxFilter;
      return matchesSearch && matchesBox;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Notebook'),
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddWordDialog, tooltip: 'Add Word'),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpeakabooTheme.spacingMd, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search saved words...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: SpeakabooTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Box Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpeakabooTheme.spacingMd),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedBoxFilter == 0,
                  onSelected: (_) => setState(() => _selectedBoxFilter = 0),
                ),
                const SizedBox(width: 6),
                for (int b = 1; b <= 5; b++) ...[
                  FilterChip(
                    label: Text('Box $b'),
                    selected: _selectedBoxFilter == b,
                    onSelected: (_) => setState(() => _selectedBoxFilter = b),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'No words matching search.' : 'No vocabulary words saved yet.\nTalk with a companion to discover words!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: SpeakabooTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final card = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: SpeakabooTheme.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
                            child: ListTile(
                              title: Text(card.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(card.definition),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text('Box ${card.box}'),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: SpeakabooTheme.background,
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.quiz, color: SpeakabooTheme.accent),
                                    tooltip: 'Review Flashcard',
                                    onPressed: () => _showReviewDialog(card),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
