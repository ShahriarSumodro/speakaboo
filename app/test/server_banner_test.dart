import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/main.dart';
import 'package:speakaboo/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Server not ready banner displays when disconnected and clears on refresh tap when healthy',
      (WidgetTester tester) async {
    bool isHealthy = false;

    final mockClient = MockClient((request) async {
      if (!isHealthy) {
        return http.Response(
          jsonEncode({'error': 'server unavailable'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/api/health') || request.url.path.endsWith('/health')) {
        return http.Response(jsonEncode({'status': 'ok'}), 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('/api/auth/device')) {
        return http.Response(jsonEncode({'user_id': 'u1', 'auth_token': 'tok1'}), 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('/api/auth/profile')) {
        return http.Response(jsonEncode({'user_id': 'u1', 'display_name': 'Test'}), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 200);
    });

    final api = ApiService(client: mockClient);

    await tester.pumpWidget(SpeakabooApp(apiService: api));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Banner must be visible because isHealthy was false
    expect(find.byKey(const Key('server_not_ready_banner')), findsOneWidget);
    expect(find.text('Server not ready. Connect USB or check backend.'), findsOneWidget);

    // Make backend healthy
    isHealthy = true;

    // Tap refresh button
    final refreshButton = find.byKey(const Key('server_banner_refresh_button'));
    expect(refreshButton, findsOneWidget);
    await tester.tap(refreshButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Banner should now be cleared
    expect(find.byKey(const Key('server_not_ready_banner')), findsNothing);
  });
}
