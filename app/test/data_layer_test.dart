import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/services/auth_storage.dart';
import 'package:speakaboo/services/cache_service.dart';
import 'package:speakaboo/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthStorage Tests', () {
    test('generates and persists device ID', () async {
      final id1 = await AuthStorage.getDeviceId();
      expect(id1.isNotEmpty, isTrue);

      final id2 = await AuthStorage.getDeviceId();
      expect(id1, equals(id2));
    });

    test('saves and clears credentials', () async {
      await AuthStorage.saveAuth(userId: 'u123', authToken: 'tok_abc', displayName: 'Rahim');
      expect(await AuthStorage.getUserId(), equals('u123'));
      expect(await AuthStorage.getAuthToken(), equals('tok_abc'));

      await AuthStorage.clear();
      expect(await AuthStorage.getUserId(), isNull);
      expect(await AuthStorage.getAuthToken(), isNull);
    });
  });

  group('CacheService Tests', () {
    test('caches and retrieves objects', () async {
      await CacheService.set('missions_test', {'count': 3});
      final res = await CacheService.get('missions_test');
      expect(res, isNotNull);
      expect(res['count'], equals(3));
    });
  });

  group('ApiService Tests', () {
    test('fetches characters and parses models correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/characters/')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'rule_farmer',
                'name': 'Farmer Reggie',
                'tagline': 'Friendly village farmer',
                'voice_id': 'austin',
                'personality_prompt': 'Enthusiastic',
                'speaking_style': 'Simple',
                'vocabulary_focus': 'Agriculture',
                'is_free': true,
                'price_bdt': 0,
                'avatar_url': '/assets/farmer.png',
                'personality_traits': ['Warm', 'Patient'],
                'sample_lines': ['Good morning!'],
                'best_for': 'Beginners',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      final characters = await api.getCharacters();
      expect(characters.length, equals(1));
      expect(characters.first.name, equals('Farmer Reggie'));
      expect(characters.first.isFree, isTrue);
      expect(characters.first.personalityTraits, contains('Warm'));
    });

    test('authenticates device and receives auth_token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/device')) {
          final body = jsonDecode(request.body);
          expect(body['device_id'], equals('dev-001'));
          return http.Response(
            jsonEncode({
              'user_id': 'user-100',
              'auth_token': 'signed_jwt_token_123',
              'is_new': true,
              'profile': {
                'user_id': 'user-100',
                'display_name': 'New Learner',
                'age_band': 'adult',
                'goal': 'Fluency',
                'level': 'beginner',
                'daily_goal_minutes': 10,
                'reminder_time': '20:00',
                'theme': 'system',
                'has_parent_pin': false,
                'created_at': '2026-11-24',
                'updated_at': '2026-11-24',
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      final res = await api.deviceAuth(deviceId: 'dev-001');
      expect(res['user_id'], equals('user-100'));
      expect(api.authToken, equals('signed_jwt_token_123'));
    });

    test('fetches learning missions and progress', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/learning/missions/u1')) {
          return http.Response(
            jsonEncode({
              'date': '2026-11-24',
              'missions': [
                {
                  'id': 'm1',
                  'title': 'Speak 3 minutes',
                  'description': 'Talk to companion',
                  'xp_reward': 50,
                  'target': 3,
                  'progress': 1,
                  'completed': false,
                  'claimed': false,
                  'category': 'speaking',
                }
              ],
              'streak': 4,
              'freezes': 1,
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/api/learning/progress/u1')) {
          return http.Response(
            jsonEncode({
              'user_id': 'u1',
              'level': 'intermediate',
              'xp': 320,
              'total_words_spoken': 850,
              'streak_days': 4,
              'weekly_minutes': 28.5,
              'accuracy_score': 82.0,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      final missionsRes = await api.getMissions('u1');
      expect(missionsRes.missions.length, equals(1));
      expect(missionsRes.streak, equals(4));

      final prog = await api.getProgress('u1');
      expect(prog.xp, equals(320));
      expect(prog.level, equals('intermediate'));
    });

    test('getTopics and getScenarios parse top-level JSON list responses from backend', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/learning/topics') {
          return http.Response(
            jsonEncode([
              {
                'id': 'weather_monsoon',
                'title': 'Monsoon Rains',
                'category': 'Nature',
                'description': 'Talk about rain',
                'sample_questions': ['Do you enjoy monsoon rain?'],
              }
            ]),
            200,
          );
        }
        if (request.url.path == '/api/learning/scenarios') {
          return http.Response(
            jsonEncode([
              {
                'id': 'job_interview',
                'title': 'First Job Interview',
                'category': 'Career',
                'description': 'Answer interview questions',
                'difficulty': 'intermediate',
                'suggested_vocabulary': ['teamwork', 'experience'],
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      final topics = await api.getTopics();
      expect(topics.length, equals(1));
      expect(topics.first.title, equals('Monsoon Rains'));
      expect(topics.first.starters, contains('Do you enjoy monsoon rain?'));

      final scenarios = await api.getScenarios();
      expect(scenarios.length, equals(1));
      expect(scenarios.first.title, equals('First Job Interview'));
      expect(scenarios.first.goals, contains('teamwork'));
    });
  });

  group('AuthProvider Tests', () {
    test('initializes and authenticates device automatically', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/device')) {
          return http.Response(
            jsonEncode({
              'user_id': 'auto-user-7',
              'auth_token': 'token_xyz_999',
              'is_new': true,
              'profile': {
                'user_id': 'auto-user-7',
                'display_name': 'Learner',
                'age_band': 'teen',
                'goal': 'IELTS',
                'level': 'intermediate',
                'daily_goal_minutes': 15,
                'reminder_time': '21:00',
                'theme': 'system',
                'has_parent_pin': false,
                'created_at': '2026-11-24',
                'updated_at': '2026-11-24',
              }
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/api/auth/profile')) {
          return http.Response(
            jsonEncode({
              'user_id': 'auto-user-7',
              'display_name': 'Learner',
              'age_band': 'teen',
              'goal': 'IELTS',
              'level': 'intermediate',
              'daily_goal_minutes': 15,
              'reminder_time': '21:00',
              'theme': 'system',
              'has_parent_pin': false,
              'created_at': '2026-11-24',
              'updated_at': '2026-11-24',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
      final provider = AuthProvider(api: api);

      await provider.initialize();

      expect(provider.userId, equals('auto-user-7'));
      expect(provider.isAuthenticated, isTrue);
      expect(provider.profile?.level, equals('intermediate'));
      expect(provider.serverConnected, isTrue);
    });
  });
}
