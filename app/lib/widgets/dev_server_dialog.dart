/// Hidden developer server settings dialog for runtime backend URL configuration.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class DevServerDialog extends StatefulWidget {
  final VoidCallback? onSaved;
  const DevServerDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog<void>(
      context: context,
      builder: (_) => DevServerDialog(onSaved: onSaved),
    );
  }

  @override
  State<DevServerDialog> createState() => _DevServerDialogState();
}

class _DevServerDialogState extends State<DevServerDialog> {
  late final TextEditingController _controller;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.backendUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String url) async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$cleanUrl/api/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _testSuccess = true;
          _testResult =
              'Connected! (${stopwatch.elapsedMilliseconds}ms) - Status: ${data["status"] ?? "ok"}';
        });
        if (mounted) {
          try {
            context.read<AuthProvider>().setServerConnected(true);
          } catch (_) {}
        }
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = 'HTTP ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _testSuccess = false;
        _testResult = 'Connection failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  Future<void> _save(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await AppConfig.setBackendUrl(cleanUrl);
    widget.onSaved?.call();
    if (mounted) {
      try {
        context.read<AuthProvider>().checkHealth();
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backend URL set to: $cleanUrl'),
        backgroundColor: SpeakabooTheme.accent,
      ),
    );
  }

  Future<void> _reset() async {
    await AppConfig.resetBackendUrl();
    widget.onSaved?.call();
    if (mounted) {
      try {
        context.read<AuthProvider>().checkHealth();
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backend URL reset to default: ${AppConfig.backendUrl}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.developer_mode, color: SpeakabooTheme.accent),
          const SizedBox(width: 8),
          const Text(
            'Developer Server URL',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change backend endpoint at runtime for physical phone USB or Wi-Fi debugging.',
              style: TextStyle(fontSize: 13, color: SpeakabooTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Server Base URL',
                hintText: 'http://localhost:8000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            const Text('Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('localhost:8000 (USB)'),
                  onPressed: () => _controller.text = AppConfig.defaultBackendUrl,
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8000 (Emulator)'),
                  onPressed: () => _controller.text = AppConfig.emulatorBackendUrl,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering, size: 16),
                label: Text(_testing ? 'Testing...' : 'Test Connection'),
                onPressed: _testing ? null : () => _testConnection(_controller.text),
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _testSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _testSuccess ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: const Text('Reset Default', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _save(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: SpeakabooTheme.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
