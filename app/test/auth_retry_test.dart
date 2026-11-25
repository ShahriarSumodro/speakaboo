import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/services/auth_storage.dart';
import 'package:speakaboo/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.clear();
  });

  group('Auth Retry & Auto-Authentication Tests', () {
    test('ApiService automatically authenticates if no token is present', () async {
      int deviceAuthCalls = 0;
      int profileCalls = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/device')) {
          deviceAuthCalls++;
          return http.Response(
            jsonEncode({
              'user_id': 'u-auto',
              'token': 'tok_auto_1',
              'auth_token': 'tok_auto_1',
              'is_new': false,
              'plan': 'free',
              'display_name': 'Auto Learner',
              'profile': {
                'user_id': 'u-auto',
                'display_name': 'Auto Learner',
                'age_band': 'adult',
                'goal': 'Fluency',
                'level': 'beginner',
                'daily_goal_minutes': 10,
                'reminder_time': '20:00',
                'theme': 'system',
                'has_parent_pin': false,
                'language': 'en',
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/api/auth/profile')) {
          profileCalls++;
          expect(request.headers['Authorization'], equals('Bearer tok_auto_1'));
          return http.Response(
            jsonEncode({
              'user_id': 'u-auto',
              'display_name': 'Auto Learner',
              'age_band': 'adult',
              'goal': 'Fluency',
              'level': 'beginner',
              'daily_goal_minutes': 10,
              'reminder_time': '20:00',
              'theme': 'system',
              'has_parent_pin': false,
              'language': 'en',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      expect(api.authToken, isNull);

      final profile = await api.getProfile();
      expect(profile.userId, equals('u-auto'));
      expect(deviceAuthCalls, equals(1));
      expect(profileCalls, equals(1));
      expect(api.authToken, equals('tok_auto_1'));
    });

    test('ApiService retries on 401 Unauthorized by re-authenticating device', () async {
      int deviceAuthCalls = 0;
      int profileAttempts = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/device')) {
          deviceAuthCalls++;
          return http.Response(
            jsonEncode({
              'user_id': 'u-refreshed',
              'token': 'tok_fresh_999',
              'auth_token': 'tok_fresh_999',
              'is_new': false,
              'plan': 'free',
              'display_name': 'Refreshed Learner',
              'profile': {
                'user_id': 'u-refreshed',
                'display_name': 'Refreshed Learner',
                'age_band': 'adult',
                'goal': 'Fluency',
                'level': 'beginner',
                'daily_goal_minutes': 10,
                'reminder_time': '20:00',
                'theme': 'system',
                'has_parent_pin': false,
                'language': 'en',
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/api/auth/profile')) {
          profileAttempts++;
          if (profileAttempts == 1) {
            // First attempt with old/stale token returns 401
            return http.Response(
              jsonEncode({'detail': 'Authentication token required'}),
              401,
            );
          } else {
            // Retry attempt with refreshed token succeeds
            expect(request.headers['Authorization'], equals('Bearer tok_fresh_999'));
            return http.Response(
              jsonEncode({
                'user_id': 'u-refreshed',
                'display_name': 'Refreshed Learner',
                'age_band': 'adult',
                'goal': 'Fluency',
                'level': 'intermediate',
                'daily_goal_minutes': 15,
                'reminder_time': '20:00',
                'theme': 'system',
                'has_parent_pin': false,
                'language': 'en',
              }),
              200,
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient, authToken: 'stale_token');

      final profile = await api.getProfile();
      expect(profile.userId, equals('u-refreshed'));
      expect(profile.level, equals('intermediate'));
      expect(deviceAuthCalls, equals(1));
      expect(profileAttempts, equals(2));
      expect(api.authToken, equals('tok_fresh_999'));
    });

    test('AuthProvider initializes properly when backend returns token field only', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/device')) {
          return http.Response(
            jsonEncode({
              'user_id': 'u-tok-only',
              'token': 'signed_token_field_only',
              'is_new': true,
              'plan': 'free',
              'display_name': 'Token Only Learner',
              'profile': {
                'user_id': 'u-tok-only',
                'display_name': 'Token Only Learner',
                'age_band': 'adult',
                'goal': 'Speaking',
                'level': 'beginner',
                'daily_goal_minutes': 10,
                'reminder_time': '20:00',
                'theme': 'system',
                'has_parent_pin': false,
                'language': 'en',
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/api/auth/profile')) {
          return http.Response(
            jsonEncode({
              'user_id': 'u-tok-only',
              'display_name': 'Token Only Learner',
              'age_band': 'adult',
              'goal': 'Speaking',
              'level': 'beginner',
              'daily_goal_minutes': 10,
              'reminder_time': '20:00',
              'theme': 'system',
              'has_parent_pin': false,
              'language': 'en',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      final provider = AuthProvider(api: api);

      await provider.initialize();
      expect(provider.isAuthenticated, isTrue);
      expect(provider.userId, equals('u-tok-only'));
      expect(provider.authToken, equals('signed_token_field_only'));
      expect(provider.errorMessage, isNull);
    });

    test('getVocabulary handles direct list from backend without crashing', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/learning/vocabulary/')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'v-1',
                'word_or_phrase': 'procrastinate',
                'context_sentence': 'Do not procrastinate on your tasks.',
                'correction_notes': 'To delay doing something.',
                'box': 2,
                'next_review_date': '2026-11-26',
                'times_reviewed': 3,
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient, authToken: 'tok');
      final vocab = await api.getVocabulary('u-123');
      expect(vocab.length, equals(1));
      expect(vocab.first.word, equals('procrastinate'));
      expect(vocab.first.example, equals('Do not procrastinate on your tasks.'));
      expect(vocab.first.definition, equals('To delay doing something.'));
      expect(vocab.first.repetitions, equals(3));
    });

    test('getShadowing calls /scripts and parses scripts correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/learning/shadowing/scripts')) {
          return http.Response(
            jsonEncode([
              {
                'id': 's-1',
                'title': 'Morning Market',
                'target_text': 'I went to the market early today.',
                'target_wpm': 120,
                'difficulty': 'beginner',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient, authToken: 'tok');
      final items = await api.getShadowing();
      expect(items.length, equals(1));
      expect(items.first.id, equals('s-1'));
      expect(items.first.title, equals('Morning Market'));
    });
  });
}
