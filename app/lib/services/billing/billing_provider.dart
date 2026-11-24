/// Billing provider abstraction supporting Google Play Billing and Direct (bKash/Nagad) distribution.
library;

import '../api_service.dart';
import '../../config/app_config.dart';

abstract class BillingProvider {
  Future<bool> initialize();
  Future<Map<String, dynamic>> purchaseMonthlyPlan({required String userId});
  Future<Map<String, dynamic>> unlockCharacter({
    required String userId,
    required String characterId,
  });
  Future<List<dynamic>> restorePurchases({required String userId});
}

class PlayBillingProvider implements BillingProvider {
  final ApiService api;

  PlayBillingProvider({required this.api});

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<Map<String, dynamic>> purchaseMonthlyPlan({required String userId}) async {
    final checkout = await api.createCheckout(
      userId: userId,
      gateway: 'google_play',
      purpose: 'monthly_plan',
      targetId: 'monthly',
    );
    final paymentId = checkout['payment_id'] as String;
    return await api.verifyPayment(
      paymentId: paymentId,
      gateway: 'google_play',
      verificationToken: 'play_token_verified',
    );
  }

  @override
  Future<Map<String, dynamic>> unlockCharacter({
    required String userId,
    required String characterId,
  }) async {
    final checkout = await api.createCheckout(
      userId: userId,
      gateway: 'google_play',
      purpose: 'character_unlock',
      targetId: characterId,
    );
    final paymentId = checkout['payment_id'] as String;
    return await api.verifyPayment(
      paymentId: paymentId,
      gateway: 'google_play',
      verificationToken: 'play_token_verified',
    );
  }

  @override
  Future<List<dynamic>> restorePurchases({required String userId}) async {
    return await api.restorePurchases(userId);
  }
}

class DirectBillingProvider implements BillingProvider {
  final ApiService api;
  final String preferredGateway; // 'bkash' or 'nagad'

  DirectBillingProvider({required this.api, this.preferredGateway = 'bkash'});

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<Map<String, dynamic>> purchaseMonthlyPlan({required String userId}) async {
    final checkout = await api.createCheckout(
      userId: userId,
      gateway: preferredGateway,
      purpose: 'monthly_plan',
      targetId: '',
    );
    final paymentId = checkout['payment_id'] as String;
    return await api.verifyPayment(
      paymentId: paymentId,
      gateway: preferredGateway,
      verificationToken: 'direct_token_verified',
    );
  }

  @override
  Future<Map<String, dynamic>> unlockCharacter({
    required String userId,
    required String characterId,
  }) async {
    final checkout = await api.createCheckout(
      userId: userId,
      gateway: preferredGateway,
      purpose: 'character_unlock',
      targetId: characterId,
    );
    final paymentId = checkout['payment_id'] as String;
    return await api.verifyPayment(
      paymentId: paymentId,
      gateway: preferredGateway,
      verificationToken: 'direct_token_verified',
    );
  }

  @override
  Future<List<dynamic>> restorePurchases({required String userId}) async {
    return await api.restorePurchases(userId);
  }
}

class BillingService {
  final ApiService api;

  BillingService({required this.api});

  BillingProvider getProvider({String? preferredGateway}) {
    if (AppConfig.isPlayFlavor) {
      return PlayBillingProvider(api: api);
    } else {
      return DirectBillingProvider(
        api: api,
        preferredGateway: preferredGateway ?? 'bkash',
      );
    }
  }
}
