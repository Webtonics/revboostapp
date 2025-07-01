// lib/core/services/subscription_service.dart - Fixed Version

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revboostapp/models/subscription_model.dart';
import 'package:universal_html/html.dart' as html;

class SubscriptionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Cache mechanism
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  
  // Lemon Squeezy store details
  // final String _storeId = '165054';
  final String _storeName = 'webtonics';
  final String _baseCheckoutUrl = 'https://webtonics.lemonsqueezy.com/buy';

  SubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance;


  /// Get the current user's Lifetime subscription status
  Future<bool> getLifetimeSubscriptionStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return false;
    }
    
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return false;
    }
    
    final userData = userDoc.data()!;
    
    if (userData['hasFullAccess'] == true) {
      return true;
    }
    
    return false;
  }
  /// Get the current user's subscription status with automatic trial expiry check
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
        final status = cachedData['data'] as SubscriptionStatus;
        // Still check trial expiry even for cached data
        return await _checkAndUpdateTrialExpiry(status, userId);
      }
    }
    
    try {
      // Get from Firestore with cache disabled
      final userDoc = await _firestore.collection('users').doc(userId)
          .get(const GetOptions(source: Source.server));
      
      if (!userDoc.exists) {
        return SubscriptionStatus.free();
      }
      
      final userData = userDoc.data()!;
      
      // Create initial status
      final status = _createSubscriptionStatusFromData(userData);
      
      // Check and update trial expiry if needed
      final finalStatus = await _checkAndUpdateTrialExpiry(status, userId);
      
      // Cache the result
      _cache[cacheKey] = {
        'data': finalStatus,
        'expiryTime': DateTime.now().add(_cacheDuration),
      };
      
      return finalStatus;
    } catch (e) {
      debugPrint('Error loading subscription status: $e');
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]['data'] as SubscriptionStatus;
      }
      return SubscriptionStatus.free();
    }
  }

  /// Create SubscriptionStatus from Firestore data
  SubscriptionStatus _createSubscriptionStatusFromData(Map<String, dynamic> userData) {
    final status = userData['subscriptionStatus'] as String?;
    final isActive = status == 'active' || status == 'on_trial';
    
    // Check for free trial
    final isFreeTrial = status == 'on_trial';
    final trialEndDate = userData['trialEndDate'] != null
        ? (userData['trialEndDate'] as Timestamp).toDate()
        : null;
    
    String? orderId;
    if (userData['subscriptionOrderId'] != null) {
      orderId = userData['subscriptionOrderId'].toString();
    }
    
    final planId = userData['subscriptionPlanId'] as String?;
    final expiresAt = userData['subscriptionEndDate'] != null
        ? (userData['subscriptionEndDate'] as Timestamp).toDate()
        : null;
    
    String? customerId;
    if (userData['lemonSqueezyCustomerId'] != null) {
      customerId = userData['lemonSqueezyCustomerId'].toString();
    }
    
    return SubscriptionStatus(
      isActive: isActive,
      planId: planId,
      expiresAt: expiresAt,
      orderId: orderId,
      customerId: customerId,
      isFreeTrial: isFreeTrial,
      trialEndDate: trialEndDate,
    );
  }

  /// Check if trial has expired and update database if needed
  Future<SubscriptionStatus> _checkAndUpdateTrialExpiry(SubscriptionStatus status, String userId) async {
    // Only check if user is currently on trial
    if (!status.isFreeTrial || status.trialEndDate == null) {
      return status;
    }

    final now = DateTime.now();
    final isExpired = now.isAfter(status.trialEndDate!);

    if (isExpired) {
      debugPrint('Trial has expired for user $userId, updating database...');
      
      try {
        // Update the user's subscription status to expired
        await _firestore.collection('users').doc(userId).update({
          'subscriptionStatus': 'trial_expired',
          'trialExpiredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Clear cache so next call gets fresh data
        _clearCache(userId);

        // Return updated status
        return SubscriptionStatus(
          isActive: false, // Trial expired, no longer active
          planId: status.planId,
          expiresAt: status.expiresAt,
          orderId: status.orderId,
          customerId: status.customerId,
          isFreeTrial: false, // No longer on trial
          trialEndDate: status.trialEndDate,
        );
      } catch (e) {
        debugPrint('Error updating expired trial: $e');
        // If update fails, still return expired status for UI
        return SubscriptionStatus(
          isActive: false,
          planId: status.planId,
          expiresAt: status.expiresAt,
          orderId: status.orderId,
          customerId: status.customerId,
          isFreeTrial: false,
          trialEndDate: status.trialEndDate,
        );
      }
    }

    return status;
  }

  /// Start a free trial with enhanced validation
  Future<bool> startFreeTrial({required int trialDays}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('Cannot start trial: No authenticated user');
      return false;
    }
    
    try {
      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        debugPrint('Cannot start trial: User document not found');
        return false;
      }
      
      final userData = userDoc.data()!;
      
      // Enhanced eligibility checks
      final hasHadTrial = userData['hasHadTrial'] == true;
      final hasHadSubscription = userData['hasHadSubscription'] == true;
      final currentStatus = userData['subscriptionStatus'] as String?;
      
      // Check if user is eligible for trial
      if (hasHadTrial || hasHadSubscription) {
        debugPrint('User not eligible for trial: hasHadTrial=$hasHadTrial, hasHadSubscription=$hasHadSubscription');
        return false;
      }

      // Check if user is already on a trial or subscription
      if (currentStatus == 'on_trial' || currentStatus == 'active') {
        debugPrint('User already has active subscription/trial: $currentStatus');
        return false;
      }
      
      // Start the trial
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
      
      debugPrint('Free trial started successfully for user $userId');
      debugPrint('Trial ends on: $trialEndDate');
      
      return true;
    } catch (e) {
      debugPrint('Error starting free trial: $e');
      return false;
    }
  }

  /// Check if user is eligible for free trial
  Future<bool> isEligibleForFreeTrial() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      
      // User is eligible if they haven't had a trial or subscription
      final hasHadTrial = userData['hasHadTrial'] == true;
      final hasHadSubscription = userData['hasHadSubscription'] == true;
      final currentStatus = userData['subscriptionStatus'] as String?;
      
      return !hasHadTrial && !hasHadSubscription && 
             currentStatus != 'on_trial' && currentStatus != 'active';
    } catch (e) {
      debugPrint('Error checking trial eligibility: $e');
      return false;
    }
  }

  /// Get remaining trial time
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

  /// Get user's subscription history for eligibility checks
  Future<Map<String, dynamic>> getUserSubscriptionHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {'hasHadTrial': false, 'hasHadSubscription': false};
    }
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {'hasHadTrial': false, 'hasHadSubscription': false};
      }
      
      final userData = userDoc.data()!;
      
      return {
        'hasHadTrial': userData['hasHadTrial'] ?? false,
        'hasHadSubscription': userData['hasHadSubscription'] ?? false,
        'subscriptionStatus': userData['subscriptionStatus'],
        'trialStartDate': userData['trialStartDate'],
        'trialEndDate': userData['trialEndDate'],
      };
    } catch (e) {
      debugPrint('Error getting user subscription history: $e');
      return {'hasHadTrial': false, 'hasHadSubscription': false};
    }
  }

  /// Check if trial is expired (this method is now properly integrated)
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
  
 
}