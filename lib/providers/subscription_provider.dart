// lib/providers/subscription_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revboostapp/models/subscription_model.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _errorMessage;
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.free();
  List<SubscriptionPlan> _availablePlans = [];
  
  // Your Lemon Squeezy store details
  final String _storeId = 'your-store-name'; // Replace with your store ID
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  bool get isSubscribed => _subscriptionStatus.isActive;
  
  // Constructor - initialize data
  SubscriptionProvider() {
    _initializePlans();
    reloadSubscriptionStatus();
  }
  
  void _initializePlans() {
    // Define your subscription plans with real product IDs
    _availablePlans = [
      SubscriptionPlan(
        id: 'monthly',
        name: 'Pro Monthly',
        description: 'Full access to all premium features',
        price: 19.99,
        interval: 'monthly',
        features: [
          'Unlimited review requests',
          'Custom QR codes',
          'Email & SMS review invites',
          'Private feedback collection',
          'Advanced review analytics',
          'Priority support',
        ],
        lemonSqueezyProductId: '488009', // Replace with your actual product ID
      ),
      SubscriptionPlan(
        id: 'yearly',
        name: 'Pro Yearly',
        description: 'Save 16% with annual billing',
        price: 199.99,
        interval: 'yearly',
        features: [
          'Everything in Pro Monthly',
          '16% discount vs monthly plan',
          'Advanced review analytics',
          'Custom branding options',
          'Priority 24/7 email support',
          'Dedicated account manager',
        ],
        lemonSqueezyProductId: 'pro-yearly', // Replace with your actual product ID
      ),
    ];
  }
  
  // Load subscription status from Firestore
  Future<void> _loadSubscriptionStatus() async {
    if (_auth.currentUser == null) {
      _subscriptionStatus = SubscriptionStatus.free();
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final userId = _auth.currentUser!.uid;
      
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        _subscriptionStatus = SubscriptionStatus.free();
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final userData = userDoc.data()!;
      
      // Check subscription status
      final isActive = userData['subscriptionStatus'] == 'active';
      final planId = userData['subscriptionPlanId'] as String?;
      final expiresAt = userData['subscriptionEndDate'] != null
          ? (userData['subscriptionEndDate'] as Timestamp).toDate()
          : null;
      final orderId = userData['subscriptionOrderId'] as String?;
      
      _subscriptionStatus = SubscriptionStatus(
        isActive: isActive,
        planId: planId,
        expiresAt: expiresAt,
        orderId: orderId,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading subscription status: $e';
      notifyListeners();
    }
  }
  
  // Public method to reload subscription status
  Future<void> reloadSubscriptionStatus() async {
    await _loadSubscriptionStatus();
  }
  
  // Get the checkout URL for a specific plan
  String getCheckoutUrl(String planId) {
  final plan = _availablePlans.firstWhere(
    (plan) => plan.id == planId,
    orElse: () => throw Exception('Plan not found'),
  );
  
  // Get the user's email for identification
  final userEmail = _auth.currentUser?.email ?? '';
  if (userEmail.isEmpty) {
    throw Exception('User email required for checkout');
  }
  
  // Create checkout URL with user email for identification
  return 'https://webtonics.lemonsqueezy.com/buy/${plan.lemonSqueezyProductId}?checkout[email]=$userEmail';
}
  
  // Get customer portal URL
  String getCustomerPortalUrl() {
    // This is a simple way to access the customer portal
    // The user's email must match what was used during checkout
    final userEmail = _auth.currentUser?.email ?? '';
    return 'https://$_storeId.lemonsqueezy.com/billing?customer_email=$userEmail';
  }
  
  // For testing - simulates cancellation
  Future<void> cancelSubscription() async {
    if (_auth.currentUser == null) return;
    
    try {
      final userId = _auth.currentUser!.uid;
      
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await reloadSubscriptionStatus();
    } catch (e) {
      _errorMessage = 'Error cancelling subscription: $e';
      notifyListeners();
    }
  }
}