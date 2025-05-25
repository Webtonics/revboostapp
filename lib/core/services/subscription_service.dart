// lib/core/services/subscription_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revboostapp/models/subscription_model.dart';
import 'package:universal_html/html.dart' as html;

/// Service for handling subscription-related operations
class SubscriptionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Cache mechanism
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  
  // Lemon Squeezy store details
  final String _storeId = '165054'; // Your store ID
  final String _storeName = 'webtonics'; // Your store name
  final String _baseCheckoutUrl = 'https://webtonics.lemonsqueezy.com/buy';

  
  /// Creates a new [SubscriptionService] instance
  SubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance;
  
  /// Get the current user's subscription status
  Future<SubscriptionStatus> getSubscriptionStatus({bool forceRefresh = false}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return SubscriptionStatus.free();
    }
    
    // Check cache first if not forcing refresh
    final cacheKey = 'subscription_status_$userId';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey];
      final expiryTime = cachedData['expiryTime'] as DateTime;
      
      if (DateTime.now().isBefore(expiryTime)) {
        debugPrint('Using cached subscription status');
        return cachedData['data'] as SubscriptionStatus;
      }
    }
    
    try {
      // Get from Firestore with cache disabled to ensure fresh data
      final userDoc = await _firestore.collection('users').doc(userId)
          .get(GetOptions(source: Source.server));
      
      if (!userDoc.exists) {
        return SubscriptionStatus.free();
      }
      
      final userData = userDoc.data()!;
      
      // Check subscription status
      final status = userData['subscriptionStatus'] as String?;
      final isActive = status == 'active' || status == 'on_trial';
      
      // Check for free trial
      final isFreeTrial = status == 'on_trial';
      final trialEndDate = userData['trialEndDate'] != null
          ? (userData['trialEndDate'] as Timestamp).toDate()
          : null;
      
      // Handle the orderId properly - convert to string if needed
      String? orderId;
      if (userData['subscriptionOrderId'] != null) {
        orderId = userData['subscriptionOrderId'].toString();
      }
      
      final planId = userData['subscriptionPlanId'] as String?;
      final expiresAt = userData['subscriptionEndDate'] != null
          ? (userData['subscriptionEndDate'] as Timestamp).toDate()
          : null;
      
      // Get customerId and ensure it's a string
      String? customerId;
      if (userData['lemonSqueezyCustomerId'] != null) {
        customerId = userData['lemonSqueezyCustomerId'].toString();
      }
      
      final subscriptionStatus = SubscriptionStatus(
        isActive: isActive,
        planId: planId,
        expiresAt: expiresAt,
        orderId: orderId,
        customerId: customerId,
        isFreeTrial: isFreeTrial,
        trialEndDate: trialEndDate,
      );
      
      // Cache the result with expiry time
      _cache[cacheKey] = {
        'data': subscriptionStatus,
        'expiryTime': DateTime.now().add(_cacheDuration),
      };
      
      return subscriptionStatus;
    } catch (e) {
      debugPrint('Error loading subscription status: $e');
      // Return cached version if available and there's an error
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]['data'] as SubscriptionStatus;
      }
      return SubscriptionStatus.free();
    }
  }
  
  /// Start a free trial for the user
  Future<bool> startFreeTrial({required int trialDays}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return false;
    }
    
    try {
      // Check if user is eligible for trial (not previously subscribed)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data()!;
      
      // If user already had a subscription or trial, don't allow new trial
      if (userData['hasHadSubscription'] == true || 
          userData['hasHadTrial'] == true) {
        return false;
      }
      
      // Set trial data
      final now = DateTime.now();
      final trialEndDate = now.add(Duration(days: trialDays));
      
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'on_trial',
        'trialStartDate': Timestamp.fromDate(now),
        'trialEndDate': Timestamp.fromDate(trialEndDate),
        'hasHadTrial': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error starting free trial: $e');
      return false;
    }
  }
  
  /// Save customer ID for later use
  Future<void> saveCustomerId(String customerId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      // Save to Firestore
      await _firestore.collection('users').doc(userId).update({
        'lemonSqueezyCustomerId': customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Save to local storage as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lemonSqueezyCustomerId', customerId);
      
      // Clear cache
      _clearCache(userId);
    } catch (e) {
      debugPrint('Error saving customer ID: $e');
    }
  }
  
  /// Get the customer ID from either Firestore or SharedPreferences
  Future<String?> getCustomerId() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    try {
      // Try Firestore first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final customerId = userData['lemonSqueezyCustomerId'] as String?;
        
        if (customerId != null && customerId.isNotEmpty) {
          return customerId;
        }
      }
      
      // Fall back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('lemonSqueezyCustomerId');
    } catch (e) {
      debugPrint('Error getting customer ID: $e');
      return null;
    }
  }
  
  /// Get the checkout URL for a specific plan
  String getCheckoutUrl(String planId, List<SubscriptionPlan> availablePlans, {bool redirect = true}) {
    final plan = availablePlans.firstWhere(
      (plan) => plan.id == planId,
      orElse: () => throw Exception('Plan not found'),
    );
    
    if (plan.lemonSqueezyProductId.isEmpty) {
      throw Exception('Invalid product checkout URL');
    }
    
    // Get the user's email for identification
    final userEmail = _auth.currentUser?.email ?? '';
    final userId = _auth.currentUser?.uid ?? '';
    
    // Get current URL to use as success/cancel URL
    String currentUrl = '';
    if (kIsWeb) {
      try {
        currentUrl = html.window.location.href;
        // Remove any parameters
        if (currentUrl.contains('?')) {
          currentUrl = currentUrl.substring(0, currentUrl.indexOf('?'));
        }
      } catch (e) {
        debugPrint('Error getting current URL: $e');
      }
    }
    
    // Build the success and cancel URLs
    final successUrl = '$currentUrl/subscription/success?plan_id=$planId&user_id=$userId';
    final cancelUrl = '$currentUrl/subscription';
    
    // Build checkout URL with parameters
    final baseUrl = '$_baseCheckoutUrl/${plan.lemonSqueezyProductId}';
    final checkoutUrl = Uri.parse(baseUrl).replace(
      queryParameters: {
        'checkout[email]': userEmail,
        'checkout[custom][user_id]': userId,
        'checkout[custom][plan_id]': planId,
        'checkout[custom][app_version]': '1.0',
        'checkout[custom][current_url]': currentUrl,
        'checkout[custom][timestamp]': DateTime.now().millisecondsSinceEpoch.toString(),
        'success_url': redirect ? successUrl : '',
        'cancel_url': redirect ? cancelUrl : '',
      },
    ).toString();
    
    return checkoutUrl;
  }
  
  /// For web: Open checkout URL in a new tab/window
  void openCheckoutUrl(String url) {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
  }
  
  /// For web: Redirect to checkout URL
  void redirectToCheckout(String url) {
    if (kIsWeb) {
      html.window.location.href = url;
    }
  }
  
  /// Get the customer portal URL
  Future<String> getCustomerPortalUrl() async {
    final customerId = await getCustomerId();
    final userEmail = _auth.currentUser?.email ?? '';
    
    // Construct the base URL with the correct format
    final baseUrl = 'https://$_storeName.lemonsqueezy.com/billing';
    
    // Add appropriate query parameters
    if (customerId != null && customerId.isNotEmpty) {
      // Use customer_id parameter for direct lookup
      return '$baseUrl?customer_id=$customerId';
    } else if (userEmail.isNotEmpty) {
      // Fall back to email if no customer ID is available
      return '$baseUrl?email=${Uri.encodeComponent(userEmail)}';
    } else {
      // Fallback if neither is available
      throw Exception('No customer identifier available for billing portal');
    }
  }
  
  /// Process a webhook event from Lemon Squeezy
  Future<bool> processWebhookEvent(Map<String, dynamic> payload) async {
    try {
      final eventName = payload['meta']?['event_name'] as String?;
      
      if (eventName == null) {
        debugPrint('Invalid webhook payload: no event name');
        return false;
      }
      
      debugPrint('Processing webhook event: $eventName');
      
      // Extract customer data
      final customerData = payload['data']?['attributes']?['customer_data'] as Map<String, dynamic>?;
      if (customerData == null) {
        debugPrint('No customer data found in webhook');
        return false;
      }
      
      // Extract user ID from custom data
      final customData = payload['data']?['attributes']?['custom_data'] as Map<String, dynamic>?;
      final userId = customData?['user_id'] as String?;
      
      if (userId == null || userId.isEmpty) {
        debugPrint('No user ID found in webhook custom data');
        return false;
      }
      
      // Process based on event type
      switch (eventName) {
        case 'order_created':
          return await _handleOrderCreated(payload, userId);
        case 'subscription_created':
          return await _handleSubscriptionCreated(payload, userId);
        case 'subscription_updated':
          return await _handleSubscriptionUpdated(payload, userId);
        case 'subscription_cancelled':
          return await _handleSubscriptionCancelled(payload, userId);
        case 'subscription_resumed':
          return await _handleSubscriptionResumed(payload, userId);
        case 'subscription_expired':
          return await _handleSubscriptionExpired(payload, userId);
        case 'subscription_payment_failed':
          return await _handleSubscriptionPaymentFailed(payload, userId);
        case 'subscription_payment_success':
          return await _handleSubscriptionPaymentSuccess(payload, userId);
        default:
          debugPrint('Unhandled webhook event: $eventName');
          return false;
      }
    } catch (e) {
      debugPrint('Error processing webhook: $e');
      return false;
    }
  }
  
  /// Handle order created event
  Future<bool> _handleOrderCreated(Map<String, dynamic> payload, String userId) async {
    try {
      final orderData = payload['data']?['attributes'] as Map<String, dynamic>?;
      if (orderData == null) return false;
      
      final orderId = payload['data']?['id'] as String?;
      final customerId = orderData['customer_id'] as String?;
      final customData = orderData['custom_data'] as Map<String, dynamic>?;
      final planId = customData?['plan_id'] as String?;
      
      // Save to Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionOrderId': orderId,
        'lemonSqueezyCustomerId': customerId,
        'subscriptionPlanId': planId,
        'hasHadSubscription': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling order created: $e');
      return false;
    }
  }
  
  /// Handle subscription created event
  Future<bool> _handleSubscriptionCreated(Map<String, dynamic> payload, String userId) async {
    try {
      final subscriptionData = payload['data']?['attributes'] as Map<String, dynamic>?;
      if (subscriptionData == null) return false;
      
      final subscriptionId = payload['data']?['id'] as String?;
      final status = subscriptionData['status'] as String?;
      final renewsAt = subscriptionData['renews_at'] as String?;
      final endsAt = subscriptionData['ends_at'] as String?;
      
      // Determine subscription end date
      DateTime? subscriptionEndDate;
      if (renewsAt != null) {
        subscriptionEndDate = DateTime.parse(renewsAt);
      } else if (endsAt != null) {
        subscriptionEndDate = DateTime.parse(endsAt);
      }
      
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionId': subscriptionId,
        'subscriptionStatus': status ?? 'active',
        'subscriptionEndDate': subscriptionEndDate != null 
            ? Timestamp.fromDate(subscriptionEndDate) 
            : null,
        'hasHadSubscription': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription created: $e');
      return false;
    }
  }
  
  /// Handle subscription updated event
  Future<bool> _handleSubscriptionUpdated(Map<String, dynamic> payload, String userId) async {
    try {
      final subscriptionData = payload['data']?['attributes'] as Map<String, dynamic>?;
      if (subscriptionData == null) return false;
      
      final status = subscriptionData['status'] as String?;
      final renewsAt = subscriptionData['renews_at'] as String?;
      final endsAt = subscriptionData['ends_at'] as String?;
      
      // Determine subscription end date
      DateTime? subscriptionEndDate;
      if (renewsAt != null) {
        subscriptionEndDate = DateTime.parse(renewsAt);
      } else if (endsAt != null) {
        subscriptionEndDate = DateTime.parse(endsAt);
      }
      
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': status ?? 'active',
        'subscriptionEndDate': subscriptionEndDate != null 
            ? Timestamp.fromDate(subscriptionEndDate) 
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription updated: $e');
      return false;
    }
  }
  
  /// Handle subscription cancelled event
  Future<bool> _handleSubscriptionCancelled(Map<String, dynamic> payload, String userId) async {
    try {
      final subscriptionData = payload['data']?['attributes'] as Map<String, dynamic>?;
      if (subscriptionData == null) return false;
      
      final endsAt = subscriptionData['ends_at'] as String?;
      
      // Determine subscription end date
      DateTime? subscriptionEndDate;
      if (endsAt != null) {
        subscriptionEndDate = DateTime.parse(endsAt);
      }
      
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'cancelled',
        'subscriptionEndDate': subscriptionEndDate != null 
            ? Timestamp.fromDate(subscriptionEndDate) 
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription cancelled: $e');
      return false;
    }
  }
  
  /// Handle subscription resumed event
  Future<bool> _handleSubscriptionResumed(Map<String, dynamic> payload, String userId) async {
    try {
      final subscriptionData = payload['data']?['attributes'] as Map<String, dynamic>?;
      if (subscriptionData == null) return false;
      
      final renewsAt = subscriptionData['renews_at'] as String?;
      
      // Determine subscription end date
      DateTime? subscriptionEndDate;
      if (renewsAt != null) {
        subscriptionEndDate = DateTime.parse(renewsAt);
      }
      
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'active',
        'subscriptionEndDate': subscriptionEndDate != null 
            ? Timestamp.fromDate(subscriptionEndDate) 
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription resumed: $e');
      return false;
    }
  }
  
  /// Handle subscription expired event
  Future<bool> _handleSubscriptionExpired(Map<String, dynamic> payload, String userId) async {
    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription expired: $e');
      return false;
    }
  }
  
  /// Handle subscription payment failed event
  Future<bool> _handleSubscriptionPaymentFailed(Map<String, dynamic> payload, String userId) async {
    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'past_due',
        'subscriptionPaymentFailed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription payment failed: $e');
      return false;
    }
  }
  
  /// Handle subscription payment success event
  Future<bool> _handleSubscriptionPaymentSuccess(Map<String, dynamic> payload, String userId) async {
    try {
      final subscriptionData = payload['data']?['attributes'] as Map<String, dynamic>?;
      if (subscriptionData == null) return false;
      
      final renewsAt = subscriptionData['renews_at'] as String?;
      
      // Determine subscription end date
      DateTime? subscriptionEndDate;
      if (renewsAt != null) {
        subscriptionEndDate = DateTime.parse(renewsAt);
      }
      
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'active',
        'subscriptionPaymentFailed': false,
        'subscriptionEndDate': subscriptionEndDate != null 
            ? Timestamp.fromDate(subscriptionEndDate) 
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error handling subscription payment success: $e');
      return false;
    }
  }
  
  /// Verify purchase success from URL parameters
  Future<bool> verifyPurchaseFromUrl(Map<String, String> queryParams) async {
    final userId = queryParams['user_id'];
    final planId = queryParams['plan_id'];
    final orderId = queryParams['order_id'];
    
    if (userId == null || planId == null) {
      debugPrint('Missing parameters in success URL');
      return false;
    }
    
    try {
      // Update user's subscription in Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionPlanId': planId,
        'subscriptionOrderId': orderId,
        'subscriptionStatus': 'active',
        'hasHadSubscription': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _clearCache(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
      return false;
    }
  }
  
  /// Check if the URL contains subscription success parameters
  bool hasSubscriptionSuccessParams(Uri uri) {
    return uri.queryParameters.containsKey('plan_id') && 
           uri.queryParameters.containsKey('user_id');
  }
  
  /// Clear cache for a user
  void _clearCache(String userId) {
    final cacheKey = 'subscription_status_$userId';
    _cache.remove(cacheKey);
  }
  
  /// For testing - check if trial is expired
  Future<bool> isTrialExpired() async {
    final status = await getSubscriptionStatus(forceRefresh: true);
    
    if (!status.isFreeTrial) {
      return false; // Not on trial
    }
    
    if (status.trialEndDate == null) {
      return true; // No end date specified
    }
    
    return DateTime.now().isAfter(status.trialEndDate!);
  }
  
  /// For testing - check time remaining in trial
  Future<Duration?> getTrialTimeRemaining() async {
    final status = await getSubscriptionStatus();
    
    if (!status.isFreeTrial || status.trialEndDate == null) {
      return null;
    }
    
    final now = DateTime.now();
    if (now.isAfter(status.trialEndDate!)) {
      return Duration.zero;
    }
    
    return status.trialEndDate!.difference(now);
  }
}