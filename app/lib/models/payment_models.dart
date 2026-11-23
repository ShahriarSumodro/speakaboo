/// Payment plans and checkout result models.
library;

class PaymentPlan {
  final String id;
  final String name;
  final int priceBdt;
  final String interval;
  final String description;
  final List<String> features;

  PaymentPlan({
    required this.id,
    required this.name,
    required this.priceBdt,
    required this.interval,
    required this.description,
    required this.features,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      priceBdt: json['price_bdt'] ?? 0,
      interval: json['interval'] ?? 'month',
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

class Entitlement {
  final String id;
  final String type; // 'plan', 'character'
  final String targetId;
  final String expiresAt;
  final bool active;

  Entitlement({
    required this.id,
    required this.type,
    required this.targetId,
    required this.expiresAt,
    required this.active,
  });

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(
      id: json['id'] ?? '',
      type: json['type'] ?? 'plan',
      targetId: json['target_id'] ?? '',
      expiresAt: json['expires_at'] ?? '',
      active: json['active'] ?? true,
    );
  }
}
