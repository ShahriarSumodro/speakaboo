import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/providers/auth_provider.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/widgets/dev_server_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('W3: DevServerDialog fails Test Connection when /health passes but device auth fails',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/health')) {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path.endsWith('/api/auth/device')) {
        return http.Response(jsonEncode({'detail': 'auth disabled'}), 500);
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DevServerDialog(httpClient: mockClient),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test Connection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Connected!'), findsNothing);
    expect(find.textContaining('500'), findsOneWidget);
  });

  testWidgets('W3: DevServerDialog fails Test Connection when /health and auth pass but /profile fails',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/health')) {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path.endsWith('/api/auth/device')) {
        return http.Response(jsonEncode({'user_id': 'u_test', 'token': 'tok_test'}), 200);
      }
      if (request.url.path.endsWith('/api/auth/profile')) {
        return http.Response(jsonEncode({'detail': 'Invalid token'}), 401);
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DevServerDialog(httpClient: mockClient),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test Connection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Connected!'), findsNothing);
    expect(find.textContaining('401'), findsOneWidget);
  });

  testWidgets('W3: DevServerDialog succeeds only when health + device auth + profile pass, and Save & Apply reauthenticates',
      (WidgetTester tester) async {
    int deviceCalls = 0;
    int profileCalls = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/health')) {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path.endsWith('/api/auth/device')) {
        deviceCalls++;
        return http.Response(jsonEncode({'user_id': 'u_new', 'token': 'tok_fresh_$deviceCalls'}), 200);
      }
      if (request.url.path.endsWith('/api/auth/profile')) {
        profileCalls++;
        return http.Response(jsonEncode({'user_id': 'u_new', 'display_name': 'Tester'}), 200);
      }
      return http.Response('Not Found', 404);
    });

    final api = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
    final auth = AuthProvider(api: api);
    addTearDown(auth.dispose);
    await auth.initialize();
    expect(auth.authToken, equals('tok_fresh_1'));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DevServerDialog(httpClient: mockClient),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test Connection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Connected!'), findsOneWidget);
    expect(deviceCalls, 2);
    expect(profileCalls, 2);

    await tester.tap(find.text('Save & Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Save & Apply triggered reauthenticate() so token refreshed beyond the pre-save token!
    expect(auth.authToken, equals('tok_fresh_3'));
    expect(auth.isAuthenticated, isTrue);
  });
}
