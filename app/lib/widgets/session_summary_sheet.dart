/// Session coaching summary bottom sheet.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/learning_models.dart';

class SessionSummarySheet extends StatelessWidget {
  final SessionSummary summary;
  final VoidCallback? onRetellDrill;
  final VoidCallback? onFinish;

  const SessionSummarySheet({
    super.key,
    required this.summary,
    this.onRetellDrill,
    this.onFinish,
  });

  static Future<void> show(
    BuildContext context, {
    required SessionSummary summary,
    VoidCallback? onRetellDrill,
    VoidCallback? onFinish,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionSummarySheet(
        summary: summary,
        onRetellDrill: onRetellDrill,
        onFinish: onFinish,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SpeakabooTheme.radiusLg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: SpeakabooTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SpeakabooTheme.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars, color: SpeakabooTheme.success, size: 28),
                  ),
                  const SizedBox(width: SpeakabooTheme.spacingMd),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speaking Session Summary',
                          style: TextStyle(
                            fontSize: SpeakabooTheme.headingSize,
                            fontWeight: FontWeight.bold,
                            color: SpeakabooTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Coaching metrics from your conversation',
                          style: TextStyle(
                            fontSize: SpeakabooTheme.captionSize,
                            color: SpeakabooTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: SpeakabooTheme.textSecondary),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onFinish?.call();
                    },
                  ),
                ],
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              // Talk time balance card
              _buildTalkTimeCard(),
              const SizedBox(height: SpeakabooTheme.spacingMd),

              // Cadence & approximate clarity
              _buildClarityAndCadenceCard(),
              const SizedBox(height: SpeakabooTheme.spacingMd),

              // Strengths
              if (summary.strengths.isNotEmpty) ...[
                _buildSectionHeader('Strengths', Icons.thumb_up_alt_outlined),
                const SizedBox(height: 6),
                ...summary.strengths.map((s) => _buildCheckItem(s, SpeakabooTheme.success)),
                const SizedBox(height: SpeakabooTheme.spacingMd),
              ],

              // Areas to improve
              if (summary.patternsToWorkOn.isNotEmpty) ...[
                _buildSectionHeader('Things to Work On', Icons.lightbulb_outline),
                const SizedBox(height: 6),
                ...summary.patternsToWorkOn.map((p) => _buildCheckItem(p, SpeakabooTheme.accent)),
                const SizedBox(height: SpeakabooTheme.spacingMd),
              ],

              // Repeat the Task Drill
              _buildRetellCard(context),
              const SizedBox(height: SpeakabooTheme.spacingMd),

              // Tomorrow's hook
              if (summary.tomorrowHook.isNotEmpty) _buildTomorrowHookCard(),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onFinish?.call();
                },
                child: const Text('Complete & Save Progress'),
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTalkTimeCard() {
    final learnerPercent = (summary.talkTimeRatio * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learner Talk Time Ratio',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: SpeakabooTheme.textPrimary,
                ),
              ),
              Text(
                '$learnerPercent%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: SpeakabooTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.talkTimeRatio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(SpeakabooTheme.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You spoke: ${summary.learnerTalkTimeSeconds.toStringAsFixed(0)}s',
                style: const TextStyle(fontSize: SpeakabooTheme.captionSize, color: SpeakabooTheme.textSecondary),
              ),
              Text(
                'Character spoke: ${summary.botTalkTimeSeconds.toStringAsFixed(0)}s',
                style: const TextStyle(fontSize: SpeakabooTheme.captionSize, color: SpeakabooTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClarityAndCadenceCard() {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.surface,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Speaking Pace',
                      style: TextStyle(fontSize: SpeakabooTheme.captionSize, color: SpeakabooTheme.textSecondary),
                    ),
                    Text(
                      '${summary.wpm.toStringAsFixed(0)} WPM',
                      style: const TextStyle(
                        fontSize: SpeakabooTheme.headingSize,
                        fontWeight: FontWeight.bold,
                        color: SpeakabooTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              const SizedBox(width: SpeakabooTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.clarityLabel,
                      style: const TextStyle(fontSize: SpeakabooTheme.captionSize, color: SpeakabooTheme.textSecondary),
                    ),
                    Text(
                      '${summary.clarityScore}%',
                      style: const TextStyle(
                        fontSize: SpeakabooTheme.headingSize,
                        fontWeight: FontWeight.bold,
                        color: SpeakabooTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary.clarityNote,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SpeakabooTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: SpeakabooTheme.baseFontSize,
            fontWeight: FontWeight.bold,
            color: SpeakabooTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: SpeakabooTheme.captionSize,
                color: SpeakabooTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetellCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: SpeakabooTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
        border: Border.all(color: SpeakabooTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.replay, color: SpeakabooTheme.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Repeat-the-Task Fluency Drill',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: SpeakabooTheme.baseFontSize,
                  color: SpeakabooTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Fluency secret: Retelling the exact same response 3 times (shorter & faster) builds automaticity and eliminates translation pauses.',
            style: TextStyle(
              fontSize: SpeakabooTheme.captionSize,
              color: SpeakabooTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetellDrill?.call();
            },
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: const Text('Try 45-Second Retell Drill'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowHookCard() {
    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
          const SizedBox(width: SpeakabooTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tomorrow's Storyline",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: SpeakabooTheme.captionSize,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary.tomorrowHook,
                  style: const TextStyle(
                    fontSize: SpeakabooTheme.captionSize,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
