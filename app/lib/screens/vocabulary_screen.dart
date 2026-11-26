/// Vocabulary notebook screen with Leitner box spaced repetition.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../widgets/playful/playful.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<VocabCard> _cards = [];
  bool _isLoading = true;
  String? _errorMessage;
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
    if (mounted) {
      setState(() {
        if (_cards.isEmpty) _isLoading = true;
        _errorMessage = null;
      });
    }

    // Instant cache retrieval
    final cached = await CacheService.get('vocab_${auth.userId}');
    if (cached is List && _cards.isEmpty && mounted) {
      setState(() {
        _cards = cached.map((c) => VocabCard.fromJson(c as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }

    try {
      final remoteCards = await api.getVocabulary(auth.userId);
      if (!mounted) return;
      setState(() {
        _cards = remoteCards;
        _isLoading = false;
        _errorMessage = null;
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
    } catch (e) {
      debugPrint('[vocabulary_screen] load failed: $e');
      final msg = e is ApiException
          ? e.message
          : 'Could not load vocabulary. Check your connection.';
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
      if (_cards.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _showAddWordDialog() {
    final wordController = TextEditingController();
    final defController = TextEditingController();
    final exController = TextEditingController();
    bool saving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.colors;
          return AlertDialog(
            title: const Text('Add Vocabulary Word'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: wordController, enabled: !saving, decoration: const InputDecoration(labelText: 'Word')),
                TextField(controller: defController, enabled: !saving, decoration: const InputDecoration(labelText: 'Definition')),
                TextField(controller: exController, enabled: !saving, decoration: const InputDecoration(labelText: 'Example Sentence')),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(dialogError!, style: TextStyle(color: colors.error, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final word = wordController.text.trim();
                        if (word.isEmpty) {
                          setDialogState(() => dialogError = 'Please enter a word.');
                          return;
                        }
                        final auth = this.context.read<AuthProvider>();
                        final api = this.context.read<ApiService>();
                        setDialogState(() {
                          saving = true;
                          dialogError = null;
                        });
                        try {
                          if (auth.userId == 'anonymous' || auth.userId.isEmpty) {
                            await auth.initialize();
                          }
                          await api.addVocabulary(
                            userId: auth.userId,
                            word: word,
                            definition: defController.text.trim(),
                            example: exController.text.trim(),
                          );
                          await _loadVocabulary();
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Saved "$word" to your notebook.')),
                            );
                          }
                        } catch (e) {
                          debugPrint('[vocabulary_screen] add error: $e');
                          final msg = e is ApiException
                              ? e.message
                              : 'Failed to add word: $e';
                          if (ctx.mounted) {
                            setDialogState(() {
                              saving = false;
                              dialogError = msg;
                            });
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReviewDialog(VocabCard card) {
    bool isRecording = false;
    int secondsLeft = 10;
    Timer? countdownTimer;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.colors;
          return AlertDialog(
            title: Text(card.word, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: colors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Definition:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text(card.definition, style: TextStyle(color: colors.textPrimary)),
                if (card.example.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Example:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  Text('"${card.example}"', style: TextStyle(fontStyle: FontStyle.italic, color: colors.textSecondary)),
                ],
                const SizedBox(height: 12),
                // Spoken Recall Practice (CD-011)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                    border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('vocab_spoken_recall_btn'),
                        icon: Icon(
                          isRecording ? Icons.stop_circle : Icons.mic,
                          color: isRecording ? colors.error : colors.accent,
                          size: 26,
                        ),
                        tooltip: isRecording ? 'Stop & Check' : 'Speak to Test Recall',
                        onPressed: () {
                          if (isRecording) {
                            countdownTimer?.cancel();
                            setDialogState(() {
                              isRecording = false;
                            });
                          } else {
                            setDialogState(() {
                              isRecording = true;
                              secondsLeft = 10;
                            });
                            countdownTimer?.cancel();
                            countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                              if (secondsLeft > 1) {
                                setDialogState(() => secondsLeft--);
                              } else {
                                t.cancel();
                                setDialogState(() {
                                  isRecording = false;
                                });
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRecording ? 'Listening... (${secondsLeft}s max)' : 'Say "${card.word}" out loud',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isRecording ? colors.accent : colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Nation (2001) Spoken Recall Test',
                              style: TextStyle(fontSize: 10, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Box ${card.box} • Repetitions: ${card.repetitions}', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  _submitReview(card.id, 'again');
                },
                child: Text('Again', style: TextStyle(color: colors.error)),
              ),
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  _submitReview(card.id, 'hard');
                },
                child: Text('Hard', style: TextStyle(color: colors.warning)),
              ),
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  _submitReview(card.id, 'good');
                },
                child: Text('Good', style: TextStyle(color: colors.accent)),
              ),
              ElevatedButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  _submitReview(card.id, 'easy');
                },
                child: const Text('Easy'),
              ),
            ],
          );
        },
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
    } catch (e) {
      debugPrint('[vocabulary_screen] review error: $e');
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Could not save review.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _cards.where((c) {
      final matchesSearch = c.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.definition.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesBox = _selectedBoxFilter == 0 || c.box == _selectedBoxFilter;
      return matchesSearch && matchesBox;
    }).toList();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vocabulary Notebook', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh_rounded, color: colors.textPrimary), onPressed: _loadVocabulary, tooltip: 'Refresh'),
          IconButton(icon: Icon(Icons.add, color: colors.textPrimary), onPressed: _showAddWordDialog, tooltip: 'Add Word'),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpeakabooTheme.spacingMd, vertical: 8),
            child: TextField(
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search saved words...',
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
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
                  label: Text(
                    'All',
                    style: TextStyle(
                      color: _selectedBoxFilter == 0 ? colors.onPrimary : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: _selectedBoxFilter == 0,
                  selectedColor: colors.primary,
                  checkmarkColor: colors.onPrimary,
                  backgroundColor: colors.surfaceWarm,
                  onSelected: (_) => setState(() => _selectedBoxFilter = 0),
                ),
                const SizedBox(width: 6),
                for (int b = 1; b <= 5; b++) ...[
                  FilterChip(
                    label: Text(
                      'Box $b',
                      style: TextStyle(
                        color: _selectedBoxFilter == b ? colors.onPrimary : colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: _selectedBoxFilter == b,
                    selectedColor: colors.primary,
                    checkmarkColor: colors.onPrimary,
                    backgroundColor: colors.surfaceWarm,
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
                ? const PlayfulLoadingState(message: 'Opening your notebook...')
                : filtered.isEmpty
                    ? PlayfulEmptyState(
                        title: _searchQuery.isNotEmpty
                            ? 'No matching words'
                            : (_cards.isEmpty && _errorMessage != null)
                                ? 'Could not load vocabulary'
                                : 'Your word jar is ready!',
                        message: _searchQuery.isNotEmpty
                            ? 'Try a different search or clear your filter.'
                            : (_cards.isEmpty && _errorMessage != null)
                                ? _errorMessage!
                                : 'No vocabulary words saved yet.\nTalk with a companion to discover words!',
                        actionLabel: _searchQuery.isNotEmpty
                            ? 'Clear Search'
                            : (_cards.isEmpty && _errorMessage != null)
                                ? 'Retry'
                                : 'Add a Word',
                        onAction: _searchQuery.isNotEmpty
                            ? () => setState(() => _searchQuery = '')
                            : (_cards.isEmpty && _errorMessage != null)
                                ? _loadVocabulary
                                : _showAddWordDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVocabulary,
                        child: ListView.builder(
                        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final card = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: colors.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
                            child: ListTile(
                              title: Text(card.word, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                              subtitle: Text(card.definition, style: TextStyle(color: colors.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text('Box ${card.box}', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: colors.background,
                                    side: BorderSide(color: colors.background),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.quiz, color: colors.accent),
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
          ),
        ],
      ),
    );
  }
}
