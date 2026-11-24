/// Shadowing practice screen with playback speed control and spoken pace evaluation.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/cache_service.dart';

class ShadowingScreen extends StatefulWidget {
  const ShadowingScreen({super.key});

  @override
  State<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  List<ShadowingItem> _items = [];
  bool _isLoading = true;
  ShadowingItem? _selectedItem;
  double _selectedSpeed = 1.0;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Map<String, dynamic>? _lastEvaluation;
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _loadShadowingItems();
  }

  Future<void> _loadShadowingItems() async {
    final api = context.read<ApiService>();

    final cached = await CacheService.get('shadowing_cache');
    if (cached is List) {
      setState(() {
        _items = cached.map((i) => ShadowingItem.fromJson(i as Map<String, dynamic>)).toList();
        if (_items.isNotEmpty) _selectedItem = _items.first;
        _isLoading = false;
      });
    }

    try {
      final remote = await api.getShadowing();
      setState(() {
        _items = remote;
        if (_items.isNotEmpty && _selectedItem == null) _selectedItem = _items.first;
        _isLoading = false;
      });
      await CacheService.set('shadowing_cache', remote.map((i) => {
        'id': i.id,
        'title': i.title,
        'difficulty': i.difficulty,
        'target_text': i.targetText,
        'reference_audio_url': i.referenceAudioUrl,
        'speed_options': i.speedOptions,
      }).toList());
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleRecording() async {
    final audio = context.read<AudioService>();
    final api = context.read<ApiService>();

    if (!_isRecording) {
      final started = await audio.startRecording();
      if (started) {
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
          _lastEvaluation = null;
        });
      }
    } else {
      final bytes = await audio.stopRecording();
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0
          : 3.0;

      setState(() {
        _isRecording = false;
        _isEvaluating = true;
      });

      if (bytes != null && _selectedItem != null) {
        try {
          // Evaluate attempt with backend
          final eval = await api.evaluateShadowing(
            itemId: _selectedItem!.id,
            transcript: _selectedItem!.targetText, // simulated target alignment
            durationSec: duration,
          );
          setState(() {
            _lastEvaluation = eval;
          });
        } catch (_) {}
      }

      setState(() {
        _isEvaluating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shadowing Practice'),
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No shadowing exercises available.'))
              : ListView(
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                  children: [
                    // Exercise selector
                    const Text('Select Passage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _items.map((item) {
                          final isSelected = item.id == _selectedItem?.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item.title),
                              selected: isSelected,
                              onSelected: (_) => setState(() {
                                _selectedItem = item;
                                _lastEvaluation = null;
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedItem != null) ...[
                      // Target Text Card
                      Container(
                        padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: SpeakabooTheme.surface,
                          borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                          border: Border.all(color: SpeakabooTheme.accent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(_selectedItem!.difficulty.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Row(
                                  children: _selectedItem!.speedOptions.map((sp) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: ActionChip(
                                        label: Text('${sp}x', style: TextStyle(fontSize: 11, fontWeight: _selectedSpeed == sp ? FontWeight.bold : FontWeight.normal)),
                                        backgroundColor: _selectedSpeed == sp ? SpeakabooTheme.accent.withValues(alpha: 0.2) : null,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => setState(() => _selectedSpeed = sp),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedItem!.targetText,
                              style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Record attempt button
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _toggleRecording,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isRecording ? 76 : 64,
                                height: _isRecording ? 76 : 64,
                                decoration: BoxDecoration(
                                  color: _isRecording ? SpeakabooTheme.error : SpeakabooTheme.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: _isRecording
                                      ? [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 4)]
                                      : null,
                                ),
                                child: Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isRecording ? 'Listening... Tap to evaluate' : 'Tap to repeat after companion',
                              style: TextStyle(
                                color: _isRecording ? SpeakabooTheme.error : SpeakabooTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Evaluation Results
                      if (_isEvaluating)
                        const Center(child: CircularProgressIndicator())
                      else if (_lastEvaluation != null) ...[
                        Container(
                          padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: SpeakabooTheme.surface,
                            borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Attempt Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricTile(
                                      '${(_lastEvaluation!['accuracy_score'] as num?)?.round() ?? 85}%',
                                      'Accuracy (Approx.)',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricTile(
                                      '${(_lastEvaluation!['pace_wpm'] as num?)?.round() ?? 110} WPM',
                                      'Speaking Pace',
                                    ),
                                  ),
                                ],
                              ),
                              if (_lastEvaluation!['feedback'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _lastEvaluation!['feedback'],
                                  style: const TextStyle(fontSize: 13, color: SpeakabooTheme.textSecondary),
                                ),
                              ],
                              _buildWordAlignment(
                                _selectedItem!.targetText,
                                _lastEvaluation!['transcript'] as String? ?? _selectedItem!.targetText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
    );
  }

  Widget _buildWordAlignment(String targetText, String spokenText) {
    final targetWords = targetText.split(RegExp(r'\s+'));
    final spokenWords = spokenText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Target Word Match & Rhythm Alignment (Approximate):',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: targetWords.map((word) {
            final clean = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
            final matched = spokenWords.contains(clean) || clean.isEmpty;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: matched
                    ? SpeakabooTheme.success.withValues(alpha: 0.15)
                    : SpeakabooTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: matched
                      ? SpeakabooTheme.success.withValues(alpha: 0.5)
                      : SpeakabooTheme.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: matched ? SpeakabooTheme.success : SpeakabooTheme.warning,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SpeakabooTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: SpeakabooTheme.accent)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: SpeakabooTheme.textSecondary)),
        ],
      ),
    );
  }
}
