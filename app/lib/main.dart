import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/conversation_provider.dart';
import 'services/api_service.dart';
import 'services/audio_service.dart';
import 'screens/main_shell.dart';

/// Speakaboo - English Speaking Companion
///
/// Main entry point.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const SpeakabooApp());
}

class SpeakabooApp extends StatelessWidget {
  const SpeakabooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProxyProvider<AudioService, ConversationProvider>(
          create: (context) => ConversationProvider(
            api: ApiService(),
            audio: context.read<AudioService>(),
          ),
          update: (context, audio, previous) =>
              previous ?? ConversationProvider(api: ApiService(), audio: audio),
        ),
      ],
      child: MaterialApp(
        title: 'Speakaboo',
        debugShowCheckedModeBanner: false,
        theme: SpeakabooTheme.theme,
        home: const MainShell(),
      ),
    );
  }
}
