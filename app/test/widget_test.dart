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
import 'package:speakaboo/widgets/empty_state.dart';
import 'package:speakaboo/widgets/unlock_sheet.dart';
import 'package:speakaboo/widgets/daily_cap_sheet.dart';
import 'package:speakaboo/widgets/correction_detail_sheet.dart';
import 'package:speakaboo/screens/talk_screen.dart';
import 'package:speakaboo/screens/characters_screen.dart';
import 'package:speakaboo/screens/missions_screen.dart';
import 'package:speakaboo/screens/profile_screen.dart';
import 'package:speakaboo/screens/onboarding_screen.dart';
import 'package:speakaboo/screens/device_pairing_screen.dart';
import 'package:speakaboo/screens/main_shell.dart';

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

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MainShell renders bottom navigation and navigates between tabs',
      (WidgetTester tester) async {
    final api = ApiService(baseUrl: 'http://localhost:8000');
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
          home: const MainShell(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Bottom Navigation Bar items
    expect(find.text('Talk'), findsOneWidget);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Switch to Characters tab
    await tester.tap(find.text('Characters'));
    await tester.pump();
    expect(find.text('Speaking Companions'), findsOneWidget);

    // Switch to Missions tab
    await tester.tap(find.text('Missions'));
    await tester.pump();
    expect(find.text("Today's Goals"), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('Learner Profile'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('CharactersScreen lists companions', (WidgetTester tester) async {
    final api = ApiService();
    final audio = AudioService();
    final conv = ConversationProvider(api: api, audio: audio);

    await tester.pumpWidget(
      ChangeNotifierProvider<ConversationProvider>.value(
        value: conv,
        child: const MaterialApp(home: CharactersScreen()),
      ),
    );

    expect(find.text('Farmer Reggie'), findsOneWidget);
    expect(find.text('Detective Kabir'), findsOneWidget);
    expect(find.text('Professor Anika'), findsOneWidget);
  });

  testWidgets('MissionsScreen displays streak and missions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MissionsScreen()),
    );

    expect(find.text('3 Day Streak!'), findsOneWidget);
    expect(find.text('Daily Speaker'), findsOneWidget);
    expect(find.text('Word Explorer'), findsOneWidget);
  });

  testWidgets('ProfileScreen displays stats and vocabulary notebook',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen()),
    );

    expect(find.text('Learner (Anonymous)'), findsOneWidget);
    expect(find.text('Vocabulary Notebook'), findsOneWidget);
    expect(find.text('Parent Dashboard'), findsOneWidget);
  });

  testWidgets('OnboardingScreen displays level options and start button',
      (WidgetTester tester) async {
    bool finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(onFinish: () => finished = true),
      ),
    );

    expect(find.text('Welcome to Speakaboo!'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);

    await tester.ensureVisible(find.text('Start Speaking Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Speaking Practice'));
    expect(finished, isTrue);
  });

  testWidgets('EmptyStateWidget renders icon, text, and action button',
      (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.history,
            title: 'No Conversations Yet',
            message: 'Tap the button below to start your first session.',
            actionLabel: 'Start Practice',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No Conversations Yet'), findsOneWidget);
    expect(find.text('Start Practice'), findsOneWidget);
    await tester.tap(find.text('Start Practice'));
    expect(tapped, isTrue);
  });

  testWidgets('UnlockSheet renders bKash and Nagad buttons',
      (WidgetTester tester) async {
    bool bkashTapped = false;
    bool nagadTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnlockSheet(
            title: 'Detective Kabir',
            priceText: '350 BDT',
            onPayWithBkash: () => bkashTapped = true,
            onPayWithNagad: () => nagadTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Unlock Detective Kabir'), findsOneWidget);
    expect(find.text('Pay with bKash'), findsOneWidget);
    expect(find.text('Pay with Nagad'), findsOneWidget);

    await tester.tap(find.text('Pay with bKash'));
    expect(bkashTapped, isTrue);

    await tester.tap(find.text('Pay with Nagad'));
    expect(nagadTapped, isTrue);
  });

  testWidgets('DailyCapSheet renders friendly cap message and upgrade options',
      (WidgetTester tester) async {
    bool bkashTapped = false;
    bool nagadTapped = false;
    bool restoreTapped = false;
    bool dismissTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyCapSheet(
            onUpgradeBkash: () => bkashTapped = true,
            onUpgradeNagad: () => nagadTapped = true,
            onRestore: () => restoreTapped = true,
            onDismiss: () => dismissTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Daily Practice Completed! 🌟'), findsOneWidget);
    expect(find.text('Upgrade Pro with bKash (200 BDT/mo)'), findsOneWidget);
    expect(find.text('Upgrade Pro with Nagad (200 BDT/mo)'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
    expect(find.text('Come Back Tomorrow'), findsOneWidget);

    await tester.tap(find.text('Upgrade Pro with bKash (200 BDT/mo)'));
    expect(bkashTapped, isTrue);

    await tester.tap(find.text('Upgrade Pro with Nagad (200 BDT/mo)'));
    expect(nagadTapped, isTrue);

    await tester.tap(find.text('Restore Purchases'));
    expect(restoreTapped, isTrue);

    await tester.tap(find.text('Come Back Tomorrow'));
    expect(dismissTapped, isTrue);
  });

  testWidgets('CorrectionDetailSheet renders tip details',
      (WidgetTester tester) async {
    final correction = CorrectionData(
      original: 'I goes',
      better: 'I went',
      reasonShort: 'Use past tense when describing completed actions.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CorrectionDetailSheet(correction: correction),
        ),
      ),
    );

    expect(find.text('Grammar & Speaking Tip'), findsOneWidget);
    expect(find.text('"I goes"'), findsOneWidget);
    expect(find.text('"I went"'), findsOneWidget);
    expect(find.text('Use past tense when describing completed actions.'),
        findsOneWidget);
    expect(find.text('Got it!'), findsOneWidget);
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

  testWidgets('DevicePairingScreen renders toy list and switches',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DevicePairingScreen()),
    );

    expect(find.text('Companion Toy (BLE)'), findsOneWidget);
    expect(find.text('Nearby Companion Toys'), findsOneWidget);
    expect(find.text('Speakaboo Toy (Puff)'), findsOneWidget);
    expect(find.text('Relay Microphone Input'), findsOneWidget);
    expect(find.text('Relay Speaker Output'), findsOneWidget);

    // Tap scan toggle
    await tester.tap(find.text('Scan'));
    await tester.pump();
    expect(find.text('Stop'), findsOneWidget);

    // Tap connect on first toy
    await tester.tap(find.text('Connect').first);
    await tester.pump();
    expect(find.text('Connected to Toy'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });
}
