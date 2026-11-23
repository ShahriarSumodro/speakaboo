import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Speakaboo - English Speaking Companion
///
/// Main entry point. Phase 0: connects to backend health endpoint.

void main() {
  runApp(const SpeakabooApp());
}

class SpeakabooApp extends StatelessWidget {
  const SpeakabooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speakaboo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFFBF8F5), // 60% warm off-white
          surfaceContainerHighest: Color(0xFFF1E9E1), // 30% surfaces
          primary: Color(0xFFF26B21), // 10% accent orange
          onSurface: Color(0xFF2A211B), // text color
        ),
        scaffoldBackgroundColor: const Color(0xFFFBF8F5),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 17,
            color: Color(0xFF2A211B),
          ),
        ),
      ),
      home: const HealthCheckScreen(),
    );
  }
}

class HealthCheckScreen extends StatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  String _status = 'Checking...';
  bool _isConnected = false;
  bool _isLoading = true;

  // Backend URL - configurable for different environments
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator -> host
  );

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
      _status = 'Connecting to backend...';
    });

    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isConnected = true;
          _status =
              'Connected! Service: ${data['service']}, Version: ${data['version']}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isConnected = false;
          _status = 'Backend returned status ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _status = 'Cannot reach backend: ${e.toString().split(':').first}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.record_voice_over,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Speakaboo',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your English Speaking Companion',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 48),
              // Connection status
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error_outline,
                  size: 48,
                  color: _isConnected
                      ? Colors.green
                      : theme.colorScheme.error,
                ),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!_isLoading)
                FilledButton.icon(
                  onPressed: _checkHealth,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(160, 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
