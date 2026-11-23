import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/conversation_provider.dart';
import 'services/api_service.dart';
import 'services/audio_service.dart';
import 'screens/main_shell.dart';
import 'widgets/dev_server_dialog.dart';

/// Speakaboo - English Speaking Companion
///
/// Main entry point.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const SpeakabooApp());
}

class SpeakabooApp extends StatefulWidget {
  const SpeakabooApp({super.key});

  @override
  State<SpeakabooApp> createState() => _SpeakabooAppState();
}

class _SpeakabooAppState extends State<SpeakabooApp> {
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(api: _apiService)..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProxyProvider<AudioService, ConversationProvider>(
          create: (context) => ConversationProvider(
            api: _apiService,
            audio: context.read<AudioService>(),
          ),
          update: (context, audio, previous) =>
              previous ?? ConversationProvider(api: _apiService, audio: audio),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          ThemeMode mode = ThemeMode.system;
          if (auth.profile?.theme == 'dark') {
            mode = ThemeMode.dark;
          } else if (auth.profile?.theme == 'light') {
            mode = ThemeMode.light;
          }

          return MaterialApp(
            title: 'Speakaboo',
            debugShowCheckedModeBanner: false,
            theme: SpeakabooTheme.theme,
            darkTheme: SpeakabooTheme.darkTheme,
            themeMode: mode,
            home: const _AppRoot(),
          );
        },
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Stack(
      children: [
        const MainShell(),
        if (!auth.isLoading && !auth.serverConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red.shade800,
              elevation: 4,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Server not ready. Connect USB or check backend.',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => DevServerDialog(
                              onSaved: () => auth.initialize(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Settings', style: TextStyle(decoration: TextDecoration.underline)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        tooltip: 'Retry connection',
                        onPressed: () => auth.initialize(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
