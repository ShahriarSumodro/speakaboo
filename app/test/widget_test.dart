import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:speakaboo/config/theme.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/services/audio_service.dart';
import 'package:speakaboo/providers/conversation_provider.dart';
import 'package:speakaboo/widgets/character_face.dart';
import 'package:speakaboo/widgets/correction_chip.dart';
import 'package:speakaboo/screens/talk_screen.dart';

void main() {
  testWidgets('CharacterFace renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterFace(
            size: 200,
            isTalking: false,
            isListening: false,
            isThinking: false,
          ),
        ),
      ),
    );

    expect(find.byType(CharacterFace), findsOneWidget);
    // Unmount to cancel any timers
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('CorrectionChip displays original and corrected text',
      (WidgetTester tester) async {
    final correction = CorrectionData(
      original: 'I goes',
      better: 'I go',
      reasonShort: 'Present tense agreement',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CorrectionChip(correction: correction),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('"I goes"') &&
            w.text.toPlainText().contains('"I go"'),
      ),
      findsOneWidget,
    );
    expect(find.text('Present tense agreement'), findsOneWidget);
    expect(find.text('Correction'), findsOneWidget);
  });

  testWidgets('TalkScreen renders with mocked provider',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/health')) {
        return http.Response(
            jsonEncode({'status': 'ok', 'service': 'speakaboo'}), 200);
      }
      if (request.url.path.endsWith('/api/conversation/start')) {
        return http.Response(
            jsonEncode({
              'conversation_id': 'test-conv-123',
              'character_name': 'Farmer Reggie',
              'greeting': 'Welcome to my farm!',
            }),
            200);
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final audio = AudioService();
    final conversation = ConversationProvider(api: api, audio: audio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioService>.value(value: audio),
          ChangeNotifierProvider<ConversationProvider>.value(
              value: conversation),
        ],
        child: MaterialApp(
          theme: SpeakabooTheme.theme,
          home: const TalkScreen(),
        ),
      ),
    );

    // Let the post-frame callback run
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Farmer Reggie'), findsOneWidget);
    expect(find.text('Welcome to my farm!'), findsOneWidget);
    expect(find.byType(CharacterFace), findsOneWidget);

    // Unmount to cleanly cancel timers
    await tester.pumpWidget(const SizedBox());
  });

  test('Theme has correct colors', () {
    expect(SpeakabooTheme.background, const Color(0xFFFBF8F5));
    expect(SpeakabooTheme.surface, const Color(0xFFF1E9E1));
    expect(SpeakabooTheme.accent, const Color(0xFFF26B21));
    expect(SpeakabooTheme.textPrimary, const Color(0xFF2A211B));
  });

  test('ApiService creates without error', () {
    final api = ApiService(baseUrl: 'http://localhost:8000');
    expect(api.baseUrl, 'http://localhost:8000');
  });

  test('TurnResult parses from JSON', () {
    final json = {
      'conversation_id': 'conv-1',
      'turn_id': 'turn-1',
      'user_transcript': 'Hello',
      'reply': 'Hi there!',
      'correction': null,
      'new_words': ['hello'],
      'audio_base64': [],
      'level': 'beginner',
      'latency_ms': 150.0,
      'safety_blocked': false,
    };

    final result = TurnResult.fromJson(json);
    expect(result.conversationId, 'conv-1');
    expect(result.reply, 'Hi there!');
    expect(result.newWords, ['hello']);
    expect(result.level, 'beginner');
  });

  test('CorrectionData parses from JSON', () {
    final json = {
      'original': 'I goes',
      'better': 'I go',
      'reason_short': 'Subject-verb agreement',
    };

    final correction = CorrectionData.fromJson(json);
    expect(correction.original, 'I goes');
    expect(correction.better, 'I go');
  });
}
