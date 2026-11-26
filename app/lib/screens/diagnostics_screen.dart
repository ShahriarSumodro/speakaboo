/// Live Diagnostics screen (Settings > Diagnostics) to test end-to-end phone->server->Groq health.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/auth_storage.dart';

enum DiagStatus { pending, running, pass, fail }

class _DiagCheck {
  final String id;
  final String title;
  DiagStatus status = DiagStatus.pending;
  int ms = 0;
  String detail = 'Not yet run';

  _DiagCheck(this.id, this.title);
}

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final List<_DiagCheck> _checks = [
    _DiagCheck('server', 'Server reachable (/health)'),
    _DiagCheck('auth', 'Device registered & token valid'),
    _DiagCheck('stt', 'Speech-to-text works'),
    _DiagCheck('llm', 'AI reply works'),
    _DiagCheck('tts', 'Text-to-speech works & plays sound'),
    _DiagCheck('topics', 'Topics list loads'),
    _DiagCheck('vocab', 'Vocabulary add and read works'),
  ];

  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  Future<void> _runCheck(_DiagCheck check, Future<(bool, String)> Function() fn) async {
    if (!mounted) return;
    setState(() {
      check.status = DiagStatus.running;
      check.detail = 'Checking...';
    });
    final sw = Stopwatch()..start();
    try {
      final (ok, detail) = await fn();
      sw.stop();
      if (!mounted) return;
      setState(() {
        check.status = ok ? DiagStatus.pass : DiagStatus.fail;
        check.ms = sw.elapsedMilliseconds;
        check.detail = detail;
      });
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        check.status = DiagStatus.fail;
        check.ms = sw.elapsedMilliseconds;
        check.detail = e.toString();
      });
    }
  }

  Future<void> _runAll() async {
    if (_running) return;
    setState(() => _running = true);

    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    final audio = context.read<AudioService>();

    // 1. Server reachable
    await _runCheck(_checks[0], () async {
      final res = await api.healthCheck();
      return (res['status'] == 'ok', 'status=${res['status']}, url=${AppConfig.backendUrl}');
    });

    // 2. Device auth & token validity
    String effectiveUserId = auth.userId;
    await _runCheck(_checks[1], () async {
      final deviceId = await AuthStorage.getDeviceId();
      final authRes = await api.deviceAuth(deviceId: deviceId);
      final uid = authRes['user_id'] as String?;
      final tok = (authRes['auth_token'] ?? authRes['token']) as String?;
      if (uid == null || tok == null || tok.isEmpty) {
        return (false, 'Missing user_id or token in /api/auth/device response');
      }
      await AuthStorage.saveAuth(userId: uid, authToken: tok);
      api.setAuthToken(tok);
      effectiveUserId = uid;
      final profile = await api.getProfile();
      return (true, 'user=${profile.userId} (token valid)');
    });

    // 3. STT probe
    await _runCheck(_checks[2], () async {
      final res = await api.runDiagnosticProbe('stt');
      final ok = res['ok'] == true;
      return (
        ok,
        ok
            ? '${res['model']} OK (${res['detail']})'
            : '${res['model']} failed (${res['status_code']}): ${res['error']}',
      );
    });

    // 4. LLM probe
    await _runCheck(_checks[3], () async {
      final res = await api.runDiagnosticProbe('llm');
      final ok = res['ok'] == true;
      return (
        ok,
        ok
            ? '${res['model']} OK (${res['detail']})'
            : '${res['model']} failed (${res['status_code']}): ${res['error']}',
      );
    });

    // 5. TTS probe + sound check
    await _runCheck(_checks[4], () async {
      final res = await api.runDiagnosticProbe('tts');
      final ok = res['ok'] == true;
      final text = res['text'] as String? ?? 'Hello! Voice test.';
      if (ok && res['audio_base64'] != null) {
        final bytes = base64Decode(res['audio_base64'] as String);
        await audio.playAudio(bytes);
        return (true, 'Groq ${res['voice']} played ${bytes.length} bytes');
      }
      final deviceSpoke = await audio.speakOnDevice(text);
      final reason = res['error'] ?? 'Server audio unavailable';
      return (
        false,
        'Server TTS unavailable ($reason). On-device voice fallback ${deviceSpoke ? "spoke OK" : "failed"}.',
      );
    });

    // 6. Topics list
    await _runCheck(_checks[5], () async {
      final topics = await api.getTopics();
      if (topics.isEmpty) {
        return (false, 'Topics endpoint returned empty list');
      }
      return (true, 'Loaded ${topics.length} topics (${topics.first.title})');
    });

    // 7. Vocabulary add & read
    await _runCheck(_checks[6], () async {
      final word = 'diagcheck_${DateTime.now().millisecondsSinceEpoch % 10000}';
      await api.addVocabulary(
        userId: effectiveUserId,
        word: word,
        definition: 'diagnostic check word',
        example: 'Running diagnostics.',
      );
      final cards = await api.getVocabulary(effectiveUserId);
      final found = cards.any((c) => c.word.toLowerCase() == word.toLowerCase());
      return (found, found ? 'Added & read back "$word" (${cards.length} total)' : 'Added "$word" but not found in list');
    });

    if (mounted) {
      setState(() => _running = false);
    }
  }

  Future<void> _copyReport() async {
    final buf = StringBuffer()
      ..writeln('Speakaboo Diagnostics Report (${DateTime.now().toIso8601String()})')
      ..writeln('Backend URL: ${AppConfig.backendUrl}')
      ..writeln('---');
    for (final c in _checks) {
      buf.writeln('[${c.status.name.toUpperCase()}] ${c.title} (${c.ms} ms) -> ${c.detail}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostics report copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnostics', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Copy report',
            icon: const Icon(Icons.copy),
            onPressed: _copyReport,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _runAll,
                    icon: _running
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(_running ? 'Running checks...' : 'Run All Checks'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _copyReport,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy report'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: SpeakabooTheme.spacingMd),
              itemCount: _checks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final c = _checks[idx];
                Color badgeColor;
                IconData icon;
                switch (c.status) {
                  case DiagStatus.pass:
                    badgeColor = colors.success;
                    icon = Icons.check_circle;
                  case DiagStatus.fail:
                    badgeColor = colors.error;
                    icon = Icons.cancel;
                  case DiagStatus.running:
                    badgeColor = colors.accent;
                    icon = Icons.hourglass_top;
                  case DiagStatus.pending:
                    badgeColor = colors.textSecondary;
                    icon = Icons.circle_outlined;
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: badgeColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                                  ),
                                ),
                                if (c.ms > 0)
                                  Text('${c.ms} ms', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.detail, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
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
