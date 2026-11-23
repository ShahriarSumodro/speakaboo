/// Onboarding screen with level selector and goal setting.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedLevel = 'beginner';

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
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: SpeakabooTheme.surface,
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.record_voice_over,
                    size: 48,
                    color: SpeakabooTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),
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
                'Build spoken English confidence by conversing with friendly AI characters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingXl),
              const Text(
                'Select your English level:',
                style: TextStyle(
                  fontSize: SpeakabooTheme.captionSize,
                  fontWeight: FontWeight.bold,
                  color: SpeakabooTheme.textSecondary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingSm),
              _buildLevelSelector(),
              const SizedBox(height: SpeakabooTheme.spacingXl),
              FilledButton(
                onPressed: () {
                  try {
                    context.read<AuthProvider>().updateProfile({'level': _selectedLevel});
                  } catch (_) {}
                  widget.onFinish();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, SpeakabooTheme.minTapTarget),
                ),
                child: const Text('Start Speaking Practice'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'id': 'beginner', 'label': 'Beginner', 'desc': 'Simple words & short phrases'},
      {'id': 'intermediate', 'label': 'Intermediate', 'desc': 'Everyday conversational topics'},
      {'id': 'advanced', 'label': 'Advanced', 'desc': 'In-depth discussions & IELTS'},
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
}
