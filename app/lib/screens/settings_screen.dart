/// Settings screen with Theme, Dev Server, Privacy Policy, and Data Deletion.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/dev_server_dialog.dart';

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
    } catch (_) {}
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
            style: ElevatedButton.styleFrom(backgroundColor: SpeakabooTheme.error),
            child: const Text('Erase Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: SpeakabooTheme.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        children: [
          // Theme Section
          ListTile(
            tileColor: SpeakabooTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            title: const Text('App Theme'),
            subtitle: Text('Current: ${_themeSelection.toUpperCase()}'),
            trailing: DropdownButton<String>(
              value: _themeSelection,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _themeSelection = val);
                  auth.updateProfile({'theme': val});
                }
              },
            ),
          ),
          const SizedBox(height: 8),

          // Developer Server URL
          ListTile(
            tileColor: SpeakabooTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: const Icon(Icons.settings_ethernet, color: SpeakabooTheme.accent),
            title: const Text('Server Connection (Dev)'),
            subtitle: Text(AppConfig.backendUrl),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              DevServerDialog.show(context, onSaved: () {
                setState(() {});
                auth.initialize();
              });
            },
          ),
          const SizedBox(height: 8),

          // Daily Practice Reminders
          SwitchListTile(
            tileColor: SpeakabooTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            secondary: const Icon(Icons.notifications_active_outlined, color: SpeakabooTheme.accent),
            title: const Text('Daily Practice Reminder'),
            subtitle: Text(_remindersEnabled ? 'Scheduled for $_reminderTime' : 'Disabled'),
            value: _remindersEnabled,
            onChanged: (val) async {
              await NotificationService.setEnabled(val);
              setState(() => _remindersEnabled = val);
            },
          ),
          if (_remindersEnabled) ...[
            const SizedBox(height: 8),
            ListTile(
              tileColor: SpeakabooTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
              leading: const Icon(Icons.access_time, color: SpeakabooTheme.accent),
              title: const Text('Reminder Time'),
              subtitle: Text('Current time: $_reminderTime (Asia/Dhaka)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectReminderTime,
            ),
          ],
          const SizedBox(height: 8),

          // Privacy Policy
          ListTile(
            tileColor: SpeakabooTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: const Icon(Icons.privacy_tip_outlined, color: SpeakabooTheme.accent),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Kid safety, zero raw audio storage, data rights'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyPolicy,
          ),
          const SizedBox(height: 8),

          // Delete Account / Right to be Forgotten
          ListTile(
            tileColor: SpeakabooTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm)),
            leading: const Icon(Icons.delete_forever, color: SpeakabooTheme.error),
            title: const Text('Delete My Data', style: TextStyle(color: SpeakabooTheme.error)),
            subtitle: const Text('Permanently erase account and history'),
            onTap: _confirmDeleteData,
          ),
        ],
      ),
    );
  }
}
