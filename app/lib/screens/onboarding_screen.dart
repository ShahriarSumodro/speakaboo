/// Onboarding screen with age band, goal, and spoken level placement.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedAgeBand = 'teen';
  String _selectedGoal = 'Daily Conversation';
  String _selectedLevel = 'beginner';

  final TextEditingController _diagnosticController = TextEditingController();

  @override
  void dispose() {
    _diagnosticController.dispose();
    super.dispose();
  }

  void _runDiagnosticPlacement() async {
    final text = _diagnosticController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or speak a sample English response.')),
      );
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final api = context.read<ApiService>();
      final result = await api.submitPlacementTest(
        userId: auth.userId,
        spokenText: text,
        durationSeconds: 25.0,
      );

      setState(() {
        _selectedLevel = result.level;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Placement Result: ${result.cefrLevel} (${result.level.toUpperCase()})'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.summary),
                const SizedBox(height: 8),
                Text('Cadence: ${result.wpm.toStringAsFixed(0)} WPM'),
                const SizedBox(height: 8),
                if (result.recommendations.isNotEmpty) ...[
                  const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.recommendations.map((r) => Text('• $r')),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Apply Placement Level'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Placement evaluation failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: SpeakabooTheme.spacingXl,
            vertical: SpeakabooTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SpeakabooTheme.spacingLg),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: SpeakabooTheme.surface,
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.record_voice_over,
                    size: 44,
                    color: SpeakabooTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),
              const Text(
                'Welcome to Speakaboo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: SpeakabooTheme.headingSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textPrimary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              const Text(
                'Personalize your coaching journey for maximum speaking confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              // Age band
              const Text(
                'Who is learning?',
                style: TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              _buildAgeBandSelector(),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              // Primary goal
              const Text(
                'Your primary goal:',
                style: TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              _buildGoalSelector(),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              // Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select English level:',
                    style: TextStyle(
                      fontSize: SpeakabooTheme.captionSize,
                      fontWeight: FontWeight.bold,
                      color: SpeakabooTheme.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDiagnosticDialog(),
                    icon: const Icon(Icons.mic, size: 16),
                    label: const Text('Spoken Diagnostic Test', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              _buildLevelSelector(),
              const SizedBox(height: SpeakabooTheme.spacingXl),

              FilledButton(
                onPressed: () {
                  try {
                    context.read<AuthProvider>().updateProfile({
                      'level': _selectedLevel,
                      'age_band': _selectedAgeBand,
                      'goal': _selectedGoal,
                    });
                  } catch (_) {}
                  widget.onFinish();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, SpeakabooTheme.minTapTarget),
                ),
                child: const Text('Start Speaking Practice'),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              TextButton(
                onPressed: widget.onFinish,
                child: const Text(
                  'Skip diagnostic, start speaking right away!',
                  style: TextStyle(color: SpeakabooTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeBandSelector() {
    final bands = [
      {'id': 'kid', 'label': 'Child (6-12)', 'icon': Icons.child_care},
      {'id': 'teen', 'label': 'Teen (13-17)', 'icon': Icons.school},
      {'id': 'adult', 'label': 'Adult (18+)', 'icon': Icons.work_outline},
    ];

    return Row(
      children: bands.map((band) {
        final isSelected = _selectedAgeBand == band['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedAgeBand = band['id'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? SpeakabooTheme.accent.withValues(alpha: 0.1) : SpeakabooTheme.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                border: Border.all(
                  color: isSelected ? SpeakabooTheme.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(band['icon'] as IconData, size: 22, color: isSelected ? SpeakabooTheme.accent : SpeakabooTheme.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    band['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? SpeakabooTheme.accent : SpeakabooTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalSelector() {
    final goals = [
      'Daily Conversation',
      'IELTS & Exams',
      'Job Interviews',
      'Child Confidence',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = _selectedGoal == goal;
        return ChoiceChip(
          label: Text(goal),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedGoal = goal),
          selectedColor: SpeakabooTheme.accent.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? SpeakabooTheme.accent : SpeakabooTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'id': 'beginner', 'label': 'Beginner (A1-A2)', 'desc': 'Simple words & short everyday phrases'},
      {'id': 'intermediate', 'label': 'Intermediate (B1)', 'desc': 'Conversational fluency & opinions'},
      {'id': 'advanced', 'label': 'Advanced (B2)', 'desc': 'Complex ideas, academic topics & IELTS'},
    ];

    return Column(
      children: levels.map((lvl) {
        final isSelected = _selectedLevel == lvl['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedLevel = lvl['id']!;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: SpeakabooTheme.spacingSm),
            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
            decoration: BoxDecoration(
              color: SpeakabooTheme.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              border: isSelected ? Border.all(color: SpeakabooTheme.accent, width: 2) : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? SpeakabooTheme.accent : SpeakabooTheme.textSecondary,
                ),
                const SizedBox(width: SpeakabooTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lvl['label']!,
                        style: const TextStyle(
                          fontSize: SpeakabooTheme.baseFontSize,
                          fontWeight: FontWeight.bold,
                          color: SpeakabooTheme.textPrimary,
                        ),
                      ),
                      Text(
                        lvl['desc']!,
                        style: const TextStyle(
                          fontSize: SpeakabooTheme.captionSize,
                          color: SpeakabooTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDiagnosticDialog() {
    bool isQuickIcebreaker = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Voice Check (Optional)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Quick Icebreaker (10s)'),
                    selected: isQuickIcebreaker,
                    onSelected: (val) {
                      setDialogState(() => isQuickIcebreaker = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Full Diagnostic'),
                    selected: !isQuickIcebreaker,
                    onSelected: (val) {
                      setDialogState(() => isQuickIcebreaker = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isQuickIcebreaker
                    ? 'Friendly Icebreaker Prompt:\n"Say hello to your coach and tell them your favorite food, animal, or hobby!"'
                    : 'Full Assessment Prompt:\n"Tell us about your hometown, what you enjoy doing in your free time, and why you want to learn English."',
                style: const TextStyle(fontSize: 13, color: SpeakabooTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diagnosticController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isQuickIcebreaker
                      ? 'e.g. "Hello! I love eating biryani and reading books."'
                      : 'Type or speak your English sample answer here...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Skip for Now'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _runDiagnosticPlacement();
              },
              child: const Text('Check Level'),
            ),
          ],
        ),
      ),
    );
  }
}
