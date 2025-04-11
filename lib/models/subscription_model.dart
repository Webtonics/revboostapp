// lib/models/subscription_model.dart

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String interval; // 'monthly' or 'yearly'
  final List<String> features;
  final String lemonSqueezyProductId;
  
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.interval,
    required this.features,
    required this.lemonSqueezyProductId,
  });
}

class SubscriptionStatus {
  final bool isActive;
  final String? planId;
  final DateTime? expiresAt;
  final String? orderId;
  
  SubscriptionStatus({
    required this.isActive,
    this.planId,
    this.expiresAt,
    this.orderId,
  });
  
  factory SubscriptionStatus.free() {
    return SubscriptionStatus(
      isActive: false,
      planId: null,
      expiresAt: null,
      orderId: null,
    );
  }
}