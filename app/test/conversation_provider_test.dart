import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/providers/conversation_provider.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/services/audio_service.dart';

class _TestAudioService extends AudioService {
  final Uint8List recordedBytes;
  final List<String> spokenOnDevice = [];
  int playChunksCalls = 0;

  _TestAudioService(this.recordedBytes);

  @override
  Future<bool> startRecording() async => true;

  @override
  Future<Uint8List?> stopRecording() async => recordedBytes;

  @override
  Future<void> playChunks(List<Uint8List> chunks) async {
    playChunksCalls++;
  }

  @override
  Future<bool> speakOnDevice(String text, {double speed = 1.0}) async {
    spokenOnDevice.add(text);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('W1: retryLastTurn resends stored audio after failure and uses on-device voice when audio_unavailable', () async {
    int turnCalls = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/conversation/start') {
        return http.Response(
          jsonEncode({
            'conversation_id': 'c1',
            'character_name': 'Farmer Reggie',
            'greeting': 'Hello!',
          }),
          200,
        );
      }
      if (request.url.path == '/api/conversation/stream-turn' ||
          request.url.path == '/api/conversation/turn') {
        turnCalls++;
        if (turnCalls <= 2) {
          return http.Response('LLM error', 503);
        }
        if (request.url.path == '/api/conversation/stream-turn') {
          final tEv = jsonEncode({'transcript': 'Hello Reggie', 'duration_seconds': 1.5});
          final cEv = jsonEncode({
            'turn_id': 't1',
            'reply': 'Howdy partner! How are you?',
            'correction': null,
            'new_words': [],
            'level': 'beginner',
            'audio_chunks': [],
            'audio_unavailable': true,
            'latency_ms': 250.0,
          });
          return http.Response(
            'event: transcript\ndata: $tEv\n\nevent: turn_complete\ndata: $cEv\n\n',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }
        return http.Response(
          jsonEncode({
            'conversation_id': 'c1',
            'turn_id': 't1',
            'user_transcript': 'Hello Reggie',
            'reply': 'Howdy partner! How are you?',
            'correction': null,
            'new_words': [],
            'audio_base64': [],
            'audio_unavailable': true,
            'level': 'beginner',
            'latency_ms': 250.0,
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient, authToken: 'tok');
    final audio = _TestAudioService(Uint8List.fromList([1, 2, 3, 4]));
    final conv = ConversationProvider(api: api, audio: audio);

    await conv.startConversation(userId: 'u1', characterId: 'rule_farmer');
    expect(conv.status, equals(ConversationStatus.ready));

    await conv.startRecording();
    await conv.stopRecordingAndSend();
    expect(conv.status, equals(ConversationStatus.error));

    // Now retry: must actually resend stored audio and succeed!
    await conv.retryLastTurn();
    expect(conv.status, equals(ConversationStatus.ready));
    expect(conv.messages.last.text, equals('Howdy partner! How are you?'));
    expect(audio.spokenOnDevice, contains('Howdy partner! How are you?'));
  });
}
