import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speakaboo/config/app_config.dart';
import 'package:speakaboo/services/api_service.dart';
import 'package:speakaboo/services/billing/billing_provider.dart';

void main() {
  group('Billing Provider Tests', () {
    late ApiService mockApi;

    setUp(() {
      mockApi = ApiService(
        client: MockClient((request) async {
          if (request.url.path.contains('/api/payment/checkout')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'payment_id': 'test_pmt_123',
                'gateway': body['gateway'],
                'amount_bdt': 200,
                'checkout_url': 'https://pay.example.com',
                'status': 'pending',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.contains('/api/payment/verify')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'payment_id': body['payment_id'],
                'success': true,
                'status': 'completed',
                'transaction_id': 'TXN_TEST_456',
                'message': 'Success',
                'entitlement_granted': 'plan:monthly',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.contains('/api/payment/restore')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'ent_1',
                  'user_id': 'user_123',
                  'type': 'plan',
                  'value': 'monthly',
                  'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400,
                  'is_active': true,
                }
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{"error": "Not Found"}', 404);
        }),
      );
    });

    test('PlayBillingProvider completes monthly plan purchase using google_play', () async {
      final provider = PlayBillingProvider(api: mockApi);
      final res = await provider.purchaseMonthlyPlan(userId: 'test_user');
      expect(res['success'], isTrue);
      expect(res['status'], 'completed');
      expect(res['entitlement_granted'], 'plan:monthly');
    });

    test('DirectBillingProvider completes purchase using preferredGateway', () async {
      final provider = DirectBillingProvider(api: mockApi, preferredGateway: 'bkash');
      final res = await provider.purchaseMonthlyPlan(userId: 'test_user');
      expect(res['success'], isTrue);
      expect(res['status'], 'completed');
    });

    test('BillingService selects provider based on AppConfig.flavor', () {
      final service = BillingService(api: mockApi);

      AppConfig.flavor = AppFlavor.play;
      final playProvider = service.getProvider();
      expect(playProvider, isA<PlayBillingProvider>());

      AppConfig.flavor = AppFlavor.direct;
      final directProvider = service.getProvider();
      expect(directProvider, isA<DirectBillingProvider>());
    });

    test('BillingProvider restores active purchases', () async {
      final provider = PlayBillingProvider(api: mockApi);
      final items = await provider.restorePurchases(userId: 'test_user');
      expect(items.length, 1);
      expect(items.first['value'], 'monthly');
    });
  });
}
