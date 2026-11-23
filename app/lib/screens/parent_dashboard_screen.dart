/// Parent Dashboard screen with 4-digit PIN protection, analytics, and safety logs.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/parent_summary.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _isUnlocked = false;
  bool _isLoading = true;
  ParentSummary? _summary;
  List<SafetyFlag> _safetyFlags = [];
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinStatus();
    });
  }

  void _checkPinStatus() {
    final auth = context.read<AuthProvider>();
    if (!auth.profile!.hasParentPin) {
      // Prompt to create PIN
      _showSetPinDialog();
    } else {
      // Prompt for PIN to unlock
      _showEnterPinDialog();
    }
  }

  void _showSetPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit Parent PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Protect parental controls, safety logs, and payment settings from curious children.'),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter 4 Digits',
                errorText: _pinError,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Exit screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = _pinController.text.trim();
              if (pin.length != 4) {
                setState(() => _pinError = 'PIN must be exactly 4 digits');
                return;
              }
              final auth = context.read<AuthProvider>();
              final ok = await auth.setParentPin(pin);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.pop(ctx);
                if (mounted) {
                  setState(() => _isUnlocked = true);
                  _loadDashboardData();
                }
              } else {
                if (mounted) {
                  setState(() => _pinError = 'Could not set PIN');
                }
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showEnterPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Parent PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your 4-digit PIN to access the parent dashboard.'),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Parent PIN',
                errorText: _pinError,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Exit screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = _pinController.text.trim();
              final auth = context.read<AuthProvider>();
              final valid = await auth.verifyParentPin(pin);
              if (!ctx.mounted) return;
              if (valid) {
                Navigator.pop(ctx);
                if (mounted) {
                  setState(() => _isUnlocked = true);
                  _loadDashboardData();
                }
              } else {
                if (mounted) {
                  setState(() => _pinError = 'Incorrect PIN');
                }
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    try {
      final summary = await api.getParentSummary(auth.userId);
      final flags = await api.getSafetyFlags(auth.userId);

      setState(() {
        _summary = summary;
        _safetyFlags = flags;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
      ),
      body: !_isUnlocked
          ? const Center(child: Text('Parent PIN required.'))
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _summary == null
                  ? const Center(child: Text('Could not load summary.'))
                  : ListView(
                      padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                      children: [
                        // Weekly Overview Card
                        Container(
                          padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
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
                                  const Text('This Week\'s Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (_summary!.weeklyGoalMet)
                                    const Chip(
                                      label: Text('Goal Met! 🌟', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      backgroundColor: SpeakabooTheme.success,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildMetricTile('${_summary!.weeklyMinutes.toStringAsFixed(1)} min', 'Speaking Time')),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildMetricTile('${_summary!.totalWords}', 'Words Spoken')),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildMetricTile('${_summary!.currentStreak} days', 'Daily Streak')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Child Safety Overview
                        Container(
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
                                  Icon(
                                    _safetyFlags.isEmpty ? Icons.verified_user : Icons.warning_amber,
                                    color: _safetyFlags.isEmpty ? SpeakabooTheme.success : SpeakabooTheme.warning,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Safety & Moderation Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _safetyFlags.isEmpty
                                    ? 'No harmful topics or profanity detected. All conversations are safe and child-friendly.'
                                    : '${_safetyFlags.length} safety alert(s) logged for parental review.',
                                style: const TextStyle(fontSize: 13, color: SpeakabooTheme.textSecondary),
                              ),
                              if (_safetyFlags.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ..._safetyFlags.map((flag) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: SpeakabooTheme.background,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Alert [${flag.severity.toUpperCase()}]: ${flag.reason} - "${flag.utterancePreview}"',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Coach Tips for Parents
                        if (_summary!.tips.isNotEmpty) ...[
                          const Text('Speaking Coach Tips for Parents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 8),
                          ..._summary!.tips.map((tip) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: SpeakabooTheme.surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.lightbulb_outline, color: SpeakabooTheme.accent, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
    );
  }

  Widget _buildMetricTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SpeakabooTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SpeakabooTheme.accent)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: SpeakabooTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
