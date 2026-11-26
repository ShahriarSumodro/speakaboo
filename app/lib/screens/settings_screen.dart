/// Settings screen with Theme, Dev Server, Privacy Policy, and Data Deletion.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../theme/theme_controller.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/dev_server_dialog.dart';
import 'debug_gallery_screen.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeSelection = 'system';
  bool _remindersEnabled = true;
  String _reminderTime = '20:00';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.profile != null) {
      _themeSelection = auth.profile!.theme;
    }
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.isEnabled();
    final time = await NotificationService.getReminderTime();
    if (mounted) {
      setState(() {
        _remindersEnabled = enabled;
        _reminderTime = time;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final parts = _reminderTime.split(':');
    final initialHour = int.tryParse(parts.first) ?? 20;
    final initialMinute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await NotificationService.setReminderTime(formatted);
      if (mounted) {
        setState(() => _reminderTime = formatted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daily practice reminder set to $formatted')),
        );
      }
    }
  }

  void _showPrivacyPolicy() async {
    final api = context.read<ApiService>();
    try {
      final doc = await api.getPrivacyPolicy();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(doc['title'] ?? 'Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(doc['body'] ?? doc['text'] ?? 'Privacy policy details...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[settings_screen] ignored error: $e');
    }
  }

  void _confirmDeleteData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All My Data?'),
        content: const Text(
          'This will permanently erase your profile, conversations, vocabulary notebook, and speaking history from our servers. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final ok = await auth.deleteAccount();
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All personal data has been erased.')),
                  );
                  Navigator.pop(context); // Exit settings
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete data. Check connection.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Erase Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        children: [
          // Theme Section — Three-way pill switch (Light / Dark / System)
          Builder(
            builder: (context) {
              final themeCtrl = context.watch<ThemeController?>();
              final current = themeCtrl?.selection ?? _themeSelection;
              return Container(
                padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusCard),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: colors.primary),
                        const SizedBox(width: SpeakabooTheme.spacingSm),
                        Text(
                          'App Theme',
                          style: SpeakabooTheme.displayStyle(
                            color: colors.textPrimary,
                            size: SpeakabooTheme.subheadingSize,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpeakabooTheme.spacing12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceWarm,
                        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusFull),
                      ),
                      child: Row(
                        children: [
                          for (final option in const [
                            ('light', 'Light', Icons.wb_sunny_rounded),
                            ('dark', 'Dark', Icons.nightlight_round),
                            ('system', 'System', Icons.smartphone_rounded),
                          ])
                            Expanded(
                              child: GestureDetector(
                                key: Key('theme_option_${option.$1}'),
                                onTap: () {
                                  setState(() => _themeSelection = option.$1);
                                  themeCtrl?.setTheme(option.$1);
                                  auth.updateProfile({'theme': option.$1});
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: current == option.$1
                                        ? colors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      SpeakabooTheme.radiusFull,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        option.$3,
                                        size: 16,
                                        color: current == option.$1
                                            ? colors.onPrimary
                                            : colors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        option.$2,
                                        style: SpeakabooTheme.bodyStyle(
                                          color: current == option.$1
                                              ? colors.onPrimary
                                              : colors.textSecondary,
                                          size: SpeakabooTheme.captionSize,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Developer Server URL
          ListTile(
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: Icon(Icons.settings_ethernet, color: colors.accent),
            title: Text('Server Connection (Dev)', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text(AppConfig.backendUrl, style: TextStyle(color: colors.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () {
              DevServerDialog.show(context, onSaved: () {
                if (mounted) setState(() {});
              });
            },
          ),
          const SizedBox(height: 8),

          // Live Diagnostics (Phase 3)
          ListTile(
            key: const Key('settings_diagnostics_tile'),
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: Icon(Icons.health_and_safety_outlined, color: colors.accent),
            title: Text('Diagnostics', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text('Test server, auth, STT, AI reply, voice, topics & vocab', style: TextStyle(color: colors.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          // Teaching Engine Experiment Variant (CD-012)
          ListTile(
            key: const Key('experiment_variant_tile'),
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: Icon(Icons.science_outlined, color: colors.accent),
            title: Text('Teaching Engine Variant', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text('EXP001: Balanced Recast (Ellis 2005) • EXP003: Active', style: TextStyle(color: colors.textSecondary)),
            trailing: Chip(
              label: const Text('ACTIVE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: colors.accent,
              side: BorderSide(color: colors.accent),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 8),

          // Daily Practice Reminders
          SwitchListTile(
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            secondary: Icon(Icons.notifications_active_outlined, color: colors.accent),
            title: Text('Daily Practice Reminder', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text(_remindersEnabled ? 'Scheduled for $_reminderTime' : 'Disabled', style: TextStyle(color: colors.textSecondary)),
            value: _remindersEnabled,
            onChanged: (val) async {
              await NotificationService.setEnabled(val);
              setState(() => _remindersEnabled = val);
            },
          ),
          if (_remindersEnabled) ...[
            const SizedBox(height: 8),
            ListTile(
              tileColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
              leading: Icon(Icons.access_time, color: colors.accent),
              title: Text('Reminder Time', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Current time: $_reminderTime (Asia/Dhaka)', style: TextStyle(color: colors.textSecondary)),
              trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
              onTap: _selectReminderTime,
            ),
          ],
          const SizedBox(height: 8),

          // Privacy Policy
          ListTile(
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: Icon(Icons.privacy_tip_outlined, color: colors.accent),
            title: Text('Privacy Policy', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text('Kid safety, zero raw audio storage, data rights', style: TextStyle(color: colors.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: _showPrivacyPolicy,
          ),
          const SizedBox(height: 8),

          // Component Gallery (Design System)
          ListTile(
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: Icon(Icons.widgets_outlined, color: colors.accent),
            title: Text('Component Gallery', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text('Inspect playful buttons, cards, states & moods', style: TextStyle(color: colors.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugGalleryScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          // Delete Account / Right to be Forgotten
          ListTile(
            tileColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: Icon(Icons.delete_forever, color: colors.error),
            title: Text('Delete My Data', style: TextStyle(color: colors.error)),
            subtitle: Text('Permanently erase account and history', style: TextStyle(color: colors.textSecondary)),
            onTap: _confirmDeleteData,
          ),
        ],
      ),
    );
  }
}
