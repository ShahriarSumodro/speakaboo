import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/config/theme.dart';
import 'package:speakaboo/config/app_config.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/services/audio_service.dart';
import 'package:speakaboo/services/analytics_service.dart';
import 'package:speakaboo/providers/auth_provider.dart';
import 'package:speakaboo/providers/conversation_provider.dart';
import 'package:speakaboo/widgets/character_face.dart';
import 'package:speakaboo/widgets/correction_chip.dart';
import 'package:speakaboo/widgets/empty_state.dart';
import 'package:speakaboo/widgets/unlock_sheet.dart';
import 'package:speakaboo/widgets/daily_cap_sheet.dart';
import 'package:speakaboo/widgets/correction_detail_sheet.dart';
import 'package:speakaboo/widgets/hint_sheet.dart';
import 'package:speakaboo/widgets/session_summary_sheet.dart';
import 'package:speakaboo/models/character.dart';
import 'package:speakaboo/models/learning_models.dart';
import 'package:speakaboo/screens/talk_screen.dart';
import 'package:speakaboo/screens/characters_screen.dart';
import 'package:speakaboo/screens/character_detail_screen.dart';
import 'package:speakaboo/screens/missions_screen.dart';
import 'package:speakaboo/screens/profile_screen.dart';
import 'package:speakaboo/screens/onboarding_screen.dart';
import 'package:speakaboo/screens/device_pairing_screen.dart';
import 'package:speakaboo/screens/main_shell.dart';
import 'package:speakaboo/screens/scenarios_screen.dart';
import 'package:speakaboo/screens/topics_screen.dart';
import 'package:speakaboo/screens/shadowing_screen.dart';
import 'package:speakaboo/screens/vocabulary_screen.dart';
import 'package:speakaboo/screens/settings_screen.dart';
import 'package:speakaboo/screens/parent_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    final auth = AuthProvider(api: api);
    final audio = AudioService();
    final conversation = ConversationProvider(api: api, audio: audio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
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
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/api/characters')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.contains('/api/learning/missions')) {
        return http.Response(jsonEncode({'date': '2026-11-24', 'missions': [], 'streak': 0, 'freezes': 0}), 200);
      }
      if (request.url.path.contains('/api/learning/word-of-the-day')) {
        return http.Response(jsonEncode({
          'word': 'Brave',
          'pronunciation': '/breɪv/',
          'bengali_meaning': 'সাহসী',
          'definition': 'Ready to face danger or pain.',
          'example': 'She was brave.',
          'level': 'beginner',
        }), 200);
      }
      if (request.url.path.contains('/api/learning/progress')) {
        return http.Response(jsonEncode({
          'user_id': 'u1',
          'level': 'beginner',
          'xp': 0,
          'total_words_spoken': 0,
          'streak_days': 0,
          'weekly_minutes': 0.0,
          'accuracy_score': 0.0,
        }), 200);
      }
      if (request.url.path.contains('/api/usage')) {
        return http.Response(jsonEncode({
          'user_id': 'u1',
          'daily_minutes_used': 0.0,
          'daily_minutes_limit': 10.0,
          'turns_today': 0,
          'plan': 'free',
          'is_capped': false,
        }), 200);
      }
      if (request.url.path.contains('/api/learning/vocabulary')) {
        return http.Response(jsonEncode({'cards': []}), 200);
      }
      if (request.url.path.contains('/api/auth/profile')) {
        return http.Response(jsonEncode({
          'user_id': 'u1',
          'display_name': 'Learner',
          'age_band': 'adult',
          'goal': 'Practice',
          'level': 'beginner',
          'daily_goal_minutes': 10,
          'reminder_time': '20:00',
          'theme': 'system',
          'has_parent_pin': false,
          'created_at': '',
          'updated_at': '',
        }), 200);
      }
      return http.Response(jsonEncode({'status': 'ok'}), 200);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);
    final audio = AudioService();
    final conversation = ConversationProvider(api: api, audio: audio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
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
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Speaking Companions'), findsOneWidget);

    // Switch to Missions tab
    await tester.tap(find.text('Missions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Today's Goals"), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Learner Profile'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('CharactersScreen lists companions', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/characters/')) {
        return http.Response(
          jsonEncode([
            {
              'id': 'rule_farmer',
              'name': 'Farmer Reggie',
              'tagline': 'Rules & Farming Metaphors',
              'voice_id': 'austin',
              'personality_prompt': 'Patient farmer',
              'speaking_style': 'Warm',
              'vocabulary_focus': 'Agriculture',
              'is_free': true,
              'price_bdt': 0,
              'avatar_url': '',
              'personality_traits': ['Patient', 'Warm'],
              'sample_lines': ['Welcome to the farm!'],
              'best_for': 'Beginners',
            },
            {
              'id': 'dhaka_detective',
              'name': 'Detective Kabir',
              'tagline': 'Mystery & Logic Practice',
              'voice_id': 'daniel',
              'personality_prompt': 'Clever detective',
              'speaking_style': 'Sharp',
              'vocabulary_focus': 'Logic',
              'is_free': false,
              'price_bdt': 350,
              'avatar_url': '',
              'personality_traits': ['Clever', 'Curious'],
              'sample_lines': ['Let us examine the clues.'],
              'best_for': 'Intermediate',
            },
            {
              'id': 'professor_anika',
              'name': 'Professor Anika',
              'tagline': 'Nature & Science Conversations',
              'voice_id': 'diana',
              'personality_prompt': 'Scholarly researcher',
              'speaking_style': 'Academic',
              'vocabulary_focus': 'Science',
              'is_free': false,
              'price_bdt': 350,
              'avatar_url': '',
              'personality_traits': ['Analytical', 'Encouraging'],
              'sample_lines': ['Every observation matters.'],
              'best_for': 'Advanced',
            },
          ]),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);
    final audio = AudioService();
    final conv = ConversationProvider(api: api, audio: audio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ConversationProvider>.value(value: conv),
        ],
        child: const MaterialApp(home: CharactersScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Farmer Reggie'), findsOneWidget);
    expect(find.text('Detective Kabir'), findsOneWidget);
    expect(find.text('Professor Anika'), findsOneWidget);
  });

  testWidgets('MissionsScreen displays streak and missions',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/api/learning/missions/')) {
        return http.Response(
          jsonEncode({
            'date': '2026-11-24',
            'streak': 3,
            'freezes': 1,
            'missions': [
              {
                'id': 'm_speak_3m',
                'title': 'Daily Speaker',
                'description': 'Speak for at least 3 minutes today',
                'xp_reward': 50,
                'target': 3,
                'progress': 1,
                'completed': false,
                'claimed': false,
                'category': 'speaking',
              },
              {
                'id': 'm_new_words_3',
                'title': 'Word Explorer',
                'description': 'Learn or use 3 new vocabulary words',
                'xp_reward': 40,
                'target': 3,
                'progress': 3,
                'completed': true,
                'claimed': false,
                'category': 'vocabulary',
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: MissionsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('3 Day Streak!'), findsOneWidget);
    expect(find.text('Daily Speaker'), findsOneWidget);
    expect(find.text('Word Explorer'), findsOneWidget);
  });

  testWidgets('ProfileScreen displays stats and vocabulary notebook',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/api/learning/progress/')) {
        return http.Response(
          jsonEncode({
            'user_id': 'u1',
            'level': 'intermediate',
            'xp': 240,
            'total_words_spoken': 450,
            'streak_days': 3,
            'weekly_minutes': 15.0,
            'accuracy_score': 85.0,
          }),
          200,
        );
      }
      if (request.url.path.contains('/api/usage/')) {
        return http.Response(
          jsonEncode({
            'user_id': 'u1',
            'daily_minutes_used': 3.5,
            'daily_minutes_limit': 10.0,
            'turns_today': 4,
            'plan': 'free',
            'is_capped': false,
          }),
          200,
        );
      }
      if (request.url.path.contains('/api/learning/vocabulary/')) {
        return http.Response(
          jsonEncode({
            'cards': [
              {
                'id': 'v1',
                'word': 'harvest',
                'definition': 'Gathering crops',
                'example': 'We harvest in autumn.',
                'box': 1,
                'next_review': '',
                'mastered': false,
                'ease_factor': 2.5,
                'repetitions': 0,
              }
            ]
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Learner'), findsOneWidget);
    expect(find.text('Vocabulary Notebook'), findsOneWidget);
    expect(find.text('Parent Dashboard'), findsOneWidget);
  });

  testWidgets('OnboardingScreen displays level options and start button',
      (WidgetTester tester) async {
    bool finished = false;
    final mockClient = MockClient((request) async => http.Response('{}', 200));
    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          home: OnboardingScreen(onFinish: () => finished = true),
        ),
      ),
    );

    expect(find.text('Welcome to Speakaboo!'), findsOneWidget);
    expect(find.text('Child (6-12)'), findsOneWidget);
    expect(find.text('Daily Conversation'), findsOneWidget);
    expect(find.textContaining('Beginner'), findsOneWidget);
    expect(find.textContaining('Intermediate'), findsOneWidget);
    expect(find.textContaining('Advanced'), findsOneWidget);

    await tester.ensureVisible(find.text('Start Speaking Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Speaking Practice'));
    expect(finished, isTrue);
  });

  testWidgets('HintSheet renders sentence starter, model answer, and vocabulary',
      (WidgetTester tester) async {
    final hint = ConversationHint(
      conversationId: 'c1',
      sentenceStarter: 'I really enjoy...',
      modelAnswer: 'I really enjoy reading books and learning English.',
      vocabularyHints: ['enjoy', 'favorite', 'relaxing'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HintSheet(hint: hint),
        ),
      ),
    );

    expect(find.text('Help Me Say It'), findsOneWidget);
    expect(find.text('I really enjoy...'), findsOneWidget);
    expect(find.text('I really enjoy reading books and learning English.'), findsOneWidget);
    expect(find.text('enjoy'), findsOneWidget);
    expect(find.text('favorite'), findsOneWidget);
    expect(find.text('relaxing'), findsOneWidget);
  });

  testWidgets('SessionSummarySheet renders talk time, pace, clarity, and tomorrow hook',
      (WidgetTester tester) async {
    final summary = SessionSummary(
      conversationId: 'c1',
      turnCount: 4,
      learnerTalkTimeSeconds: 42.0,
      botTalkTimeSeconds: 28.0,
      talkTimeRatio: 0.60,
      wpm: 84.0,
      averageTurnLengthWords: 8.5,
      clarityScore: 88,
      clarityLabel: 'Approximate Clarity',
      clarityNote: 'Approximate estimate based on speech-to-text confidence and phrasing cadence.',
      strengths: ['High learner talk time', 'Good conversational tempo'],
      patternsToWorkOn: ['Past tense consistency'],
      concreteNextStep: 'Repeat your best answer today in 30 seconds to lock in fluency.',
      sayThisBetter: [],
      tomorrowHook: 'Tomorrow Kabir has a special riddle prepared!',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionSummarySheet(summary: summary),
        ),
      ),
    );

    expect(find.text('Speaking Session Summary'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('84 WPM'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('Approximate Clarity'), findsOneWidget);
    expect(find.text('High learner talk time'), findsOneWidget);
    expect(find.text('Past tense consistency'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Repeat-the-Task Fluency Drill'), 100);
    expect(find.text('Repeat-the-Task Fluency Drill'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Tomorrow Kabir has a special riddle prepared!'), 100);
    expect(find.text('Tomorrow Kabir has a special riddle prepared!'), findsOneWidget);
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

  testWidgets('UnlockSheet renders bKash and Nagad buttons in direct flavor and Play in play flavor',
      (WidgetTester tester) async {
    bool bkashTapped = false;
    bool nagadTapped = false;
    bool playTapped = false;

    // Direct flavor
    AppConfig.flavor = AppFlavor.direct;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnlockSheet(
            title: 'Detective Kabir',
            priceText: '350 BDT',
            onPayWithPlay: () => playTapped = true,
            onPayWithBkash: () => bkashTapped = true,
            onPayWithNagad: () => nagadTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Unlock Detective Kabir'), findsOneWidget);
    expect(find.text('Pay with bKash'), findsOneWidget);
    expect(find.text('Pay with Nagad'), findsOneWidget);
    expect(find.text('Unlock with Google Play'), findsNothing);

    await tester.tap(find.text('Pay with bKash'));
    expect(bkashTapped, isTrue);

    await tester.tap(find.text('Pay with Nagad'));
    expect(nagadTapped, isTrue);

    // Play flavor
    AppConfig.flavor = AppFlavor.play;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnlockSheet(
            title: 'Detective Kabir',
            priceText: '350 BDT',
            onPayWithPlay: () => playTapped = true,
            onPayWithBkash: () => bkashTapped = true,
            onPayWithNagad: () => nagadTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Unlock with Google Play'), findsOneWidget);
    expect(find.text('Pay with bKash'), findsNothing);
    expect(find.text('Pay with Nagad'), findsNothing);

    await tester.tap(find.text('Unlock with Google Play'));
    expect(playTapped, isTrue);
  });

  testWidgets('DailyCapSheet renders friendly cap message and upgrade options in both flavors',
      (WidgetTester tester) async {
    bool bkashTapped = false;
    bool nagadTapped = false;
    bool playTapped = false;
    bool restoreTapped = false;
    bool dismissTapped = false;

    // Direct flavor
    AppConfig.flavor = AppFlavor.direct;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyCapSheet(
            onUpgradePlay: () => playTapped = true,
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

    // Play flavor
    AppConfig.flavor = AppFlavor.play;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyCapSheet(
            onUpgradePlay: () => playTapped = true,
            onUpgradeBkash: () => bkashTapped = true,
            onUpgradeNagad: () => nagadTapped = true,
            onRestore: () => restoreTapped = true,
            onDismiss: () => dismissTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Upgrade Pro with Google Play (200 BDT/mo)'), findsOneWidget);
    expect(find.text('Upgrade Pro with bKash (200 BDT/mo)'), findsNothing);
    expect(find.text('Upgrade Pro with Nagad (200 BDT/mo)'), findsNothing);

    await tester.tap(find.text('Upgrade Pro with Google Play (200 BDT/mo)'));
    expect(playTapped, isTrue);

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

  test('Dark Theme (Phase 8) has correct 60-30-10 tokens and contrast >= 4.5:1', () {
    // 60-30-10 tokens
    expect(SpeakabooTheme.darkBackground, const Color(0xFF1B1613));
    expect(SpeakabooTheme.darkSurface, const Color(0xFF2A221D));
    expect(SpeakabooTheme.darkAccent, const Color(0xFFFF7A33));
    expect(SpeakabooTheme.darkTextPrimary, const Color(0xFFF5EDE6));
    expect(SpeakabooTheme.darkTextSecondary, const Color(0xFFC4B8B0));

    // Tap target minimum 44px
    expect(SpeakabooTheme.minTapTarget, greaterThanOrEqualTo(44.0));

    // ThemeExtension registered
    final colors = SpeakabooTheme.darkTheme.extension<SpeakabooColors>();
    expect(colors, isNotNull);
    expect(colors!.background, SpeakabooTheme.darkBackground);
    expect(colors.surface, SpeakabooTheme.darkSurface);

    // WCAG Contrast ratio verification: (L1 + 0.05) / (L2 + 0.05)
    double luminance(Color c) => c.computeLuminance();
    final lText = luminance(SpeakabooTheme.darkTextPrimary);
    final lBg = luminance(SpeakabooTheme.darkBackground);
    final lSurface = luminance(SpeakabooTheme.darkSurface);

    final contrastBg = (lText + 0.05) / (lBg + 0.05);
    final contrastSurface = (lText + 0.05) / (lSurface + 0.05);

    expect(contrastBg, greaterThan(4.5)); // Well above 4.5:1 (actually ~15:1)
    expect(contrastSurface, greaterThan(4.5)); // Well above 4.5:1 (actually ~11:1)
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

  test('AnalyticsService records events and errors', () {
    final analytics = AnalyticsService();
    analytics.clear();
    analytics.track('app_opened', {'source': 'push'});
    expect(analytics.events.length, 1);
    expect(analytics.events.first.name, 'app_opened');

    analytics.recordError(Exception('Network timeout'), null, context: 'talk_turn');
    expect(analytics.errorLog.length, 1);
    expect(analytics.errorLog.first['context'], 'talk_turn');
  });

  testWidgets('ScenariosScreen renders scenarios list', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/learning/scenarios')) {
        return http.Response(
          jsonEncode({
            'scenarios': [
              {
                'id': 'sc_market',
                'title': 'Vegetable Market',
                'category': 'Daily Life',
                'difficulty': 'beginner',
                'description': 'Bargain and buy fresh produce',
                'roles': ['Buyer', 'Seller'],
                'goals': ['Ask price', 'Buy items'],
              }
            ]
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);

    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: ScenariosScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vegetable Market'), findsOneWidget);
    expect(find.text('Start Roleplay'), findsOneWidget);

    // Tap Start Roleplay to open pre-task planning scaffold sheet (CD-006)
    await tester.tap(find.text('Start Roleplay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pre-Task Prep: Vegetable Market'), findsOneWidget);
    expect(find.text('1. What is your goal?'), findsOneWidget);
    expect(find.text('Ready! Start Roleplay'), findsOneWidget);
  });

  testWidgets('TopicsScreen renders topics list', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/learning/topics')) {
        return http.Response(
          jsonEncode({
            'topics': [
              {
                'id': 'top_weather',
                'title': 'Monsoon Weather',
                'category': 'Environment',
                'difficulty': 'beginner',
                'starters': ['What is the weather like today?'],
              }
            ]
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);

    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: TopicsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Monsoon Weather'), findsOneWidget);
  });

  testWidgets('VocabularyScreen renders search and empty state', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/api/learning/vocabulary/')) {
        return http.Response(
          jsonEncode({'cards': []}),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: VocabularyScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vocabulary Notebook'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('CharacterDetailScreen renders character information and sample phrases', (WidgetTester tester) async {
    final character = Character(
      id: 'prof_anika',
      name: 'Professor Anika',
      tagline: 'Science & Nature Conversations',
      voiceId: 'diana',
      personalityPrompt: 'Curious researcher',
      speakingStyle: 'Warm and scholarly',
      vocabularyFocus: 'Science & Ecology',
      isFree: true,
      priceBdt: 0,
      avatarUrl: '',
      personalityTraits: ['Analytical', 'Encouraging'],
      sampleLines: ['Every observation matters.'],
      bestFor: 'Advanced learners',
    );

    final api = ApiService();
    final auth = AuthProvider(api: api);
    final audio = AudioService();
    final conv = ConversationProvider(api: api, audio: audio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AudioService>.value(value: audio),
          ChangeNotifierProvider<ConversationProvider>.value(value: conv),
        ],
        child: MaterialApp(home: CharacterDetailScreen(character: character)),
      ),
    );

    expect(find.text('Professor Anika'), findsWidgets);
    expect(find.text('Science & Nature Conversations'), findsOneWidget);
    expect(find.text('Hear their voice'), findsOneWidget);
    expect(find.text('"Every observation matters."'), findsOneWidget);
  });

  testWidgets('ShadowingScreen renders shadowing scripts and controls', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/learning/shadowing')) {
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'shad_morning',
                'title': 'Morning Walk',
                'difficulty': 'beginner',
                'target_text': 'I enjoy walking in the fresh morning air.',
                'reference_audio_url': '',
                'speed_options': [0.8, 1.0, 1.2],
              }
            ]
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/api/learning/shadowing/evaluate')) {
        return http.Response(
          jsonEncode({
            'accuracy_score': 88.0,
            'pace_wpm': 115.0,
            'feedback': 'Good rhythm and flow.',
            'transcript': 'I enjoy walking in the fresh morning air.',
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: ShadowingScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Shadowing Practice'), findsOneWidget);
    expect(find.text('Morning Walk'), findsOneWidget);
    expect(find.text('0.8x'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);
    expect(find.text('1.2x'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders settings items', (WidgetTester tester) async {
    final api = ApiService();
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('App Theme'), findsOneWidget);
    expect(find.text('Server Connection (Dev)'), findsOneWidget);
    expect(find.text('Delete My Data'), findsOneWidget);
  });

  testWidgets('ParentDashboardScreen sets PIN, unlocks, and copies WhatsApp report', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/auth/set-parent-pin')) {
        return http.Response(jsonEncode({'success': true}), 200);
      }
      if (request.url.path.contains('/api/parent/summary/')) {
        return http.Response(
          jsonEncode({
            'user_id': 'test_user',
            'weekly_minutes': 14.5,
            'total_words': 320,
            'current_streak': 5,
            'accuracy_trend': [0.75, 0.82],
            'safety_flags_count': 0,
            'topics_practiced': ['Daily Routine'],
            'weekly_goal_met': true,
            'tips': ['Praise effort rather than perfection.'],
          }),
          200,
        );
      }
      if (request.url.path.contains('/api/parent/safety-flags/')) {
        return http.Response(jsonEncode({'safety_flags': []}), 200);
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: ParentDashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Should prompt for PIN creation
    expect(find.text('Set 4-Digit Parent PIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4321');
    await tester.tap(find.text('Save PIN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Dashboard unlocked
    expect(find.text("This Week's Progress"), findsOneWidget);
    expect(find.text('14.5 min'), findsOneWidget);
    expect(find.text('Share Achievement on WhatsApp'), findsOneWidget);

    // Tap share achievement
    await tester.tap(find.byKey(const Key('whatsapp_parent_report_btn')));
    await tester.pump();
    expect(find.text('Weekly achievement report copied for WhatsApp!'), findsOneWidget);
  });
}
