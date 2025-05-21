// lib/providers/subscription_provider.dart

import 'package:flutter/material.dart';
import 'package:revboostapp/core/services/subscription_service.dart';
import 'package:revboostapp/models/subscription_model.dart';

enum SubscriptionProviderStatus {
  initial,
  loading,
  loaded,
  error,
}

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService;
  
  SubscriptionProviderStatus _status = SubscriptionProviderStatus.initial;
  String? _errorMessage;
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.free();
  List<SubscriptionPlan> _availablePlans = [];
  
  // UI State related
  String? _selectedPlanId;
  bool _isProcessingCheckout = false;
  bool _isProcessingTrial = false;
  
  // Getters
  SubscriptionProviderStatus get status => _status;
  String? get errorMessage => _errorMessage;
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  String? get selectedPlanId => _selectedPlanId;
  bool get isProcessingCheckout => _isProcessingCheckout;
  bool get isProcessingTrial => _isProcessingTrial;
  
  // Computed properties
  bool get isSubscribed => _subscriptionStatus.isActive;
  bool get isFreeTrial => _subscriptionStatus.isFreeTrial;
  DateTime? get trialEndDate => _subscriptionStatus.trialEndDate;
  
  // Constructor - inject the service
  SubscriptionProvider({SubscriptionService? subscriptionService}) 
      : _subscriptionService = subscriptionService ?? SubscriptionService() {
    _initializePlans();
    _loadSubscriptionStatus();
  }
  
  // Initialize available subscription plans
  void _initializePlans() {
    _availablePlans = [
      SubscriptionPlan(
        id: 'monthly',
        name: 'Pro',
        description: 'Full access to all premium features',
        price: 39.99,
        interval: 'monthly',
        features: [
          'Unlimited review requests',
          'Custom QR codes',
          'Email & SMS review invites',
          'Private feedback collection',
          'Priority support',
        ],
        lemonSqueezyProductId: '0016db55-8733-4da7-977f-0d6e61bdab26',
      ),
      SubscriptionPlan(
        id: 'yearly',
        name: 'Pro Yearly',
        description: 'Save 16% with annual billing',
        price: 299.99,
        interval: 'yearly',
        features: [
          'Everything in Pro Monthly',
          '16% discount vs monthly plan',
          'Priority 24/7 support',
          'Dedicated account manager',
        ],
        lemonSqueezyProductId: '167fb4dc-feaa-47c5-8447-df7b938a9564',
      ),
    ];
  }
  
  // Load subscription status
  Future<void> _loadSubscriptionStatus() async {
    try {
      _status = SubscriptionProviderStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      _subscriptionStatus = await _subscriptionService.getSubscriptionStatus();
      
      _status = SubscriptionProviderStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = SubscriptionProviderStatus.error;
      _errorMessage = 'Error loading subscription status: $e';
      notifyListeners();
    }
  }
  
  // Reload subscription status with option to force refresh
  Future<void> reloadSubscriptionStatus({bool forceRefresh = false}) async {
    try {
      _status = SubscriptionProviderStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      _subscriptionStatus = await _subscriptionService.getSubscriptionStatus(
        forceRefresh: forceRefresh
      );
      
      _status = SubscriptionProviderStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = SubscriptionProviderStatus.error;
      _errorMessage = 'Error reloading subscription status: $e';
      notifyListeners();
    }
  }
  
  // Refresh subscription status - calls forceRefresh by default
  Future<void> refreshSubscriptionStatus() async {
    await reloadSubscriptionStatus(forceRefresh: true);
  }
  
  // Select a plan for checkout
  void selectPlan(String planId) {
    _selectedPlanId = planId;
    notifyListeners();
  }
  
  // Get checkout URL for selected plan
  String? getCheckoutUrl({bool redirect = true}) {
    if (_selectedPlanId == null) return null;
    
    try {
      return _subscriptionService.getCheckoutUrl(_selectedPlanId!, _availablePlans, redirect: redirect);
    } catch (e) {
      _errorMessage = 'Error generating checkout URL: $e';
      notifyListeners();
      return null;
    }
  }
  
  // Open checkout URL in new tab/window (for web)
  void openCheckoutInNewTab() {
    final url = getCheckoutUrl(redirect: true);
    if (url != null) {
      _subscriptionService.openCheckoutUrl(url);
    }
  }
  
  // Redirect to checkout (for web)
  void redirectToCheckout() {
    final url = getCheckoutUrl(redirect: true);
    if (url != null) {
      _isProcessingCheckout = true;
      notifyListeners();
      _subscriptionService.redirectToCheckout(url);
    }
  }
  
  // Handle return from checkout with success parameters
  Future<bool> handleCheckoutSuccess(Map<String, String> queryParams) async {
    try {
      _isProcessingCheckout = true;
      notifyListeners();
      
      final success = await _subscriptionService.verifyPurchaseFromUrl(queryParams);
      
      if (success) {
        await refreshSubscriptionStatus();
      }
      
      _isProcessingCheckout = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _errorMessage = 'Error processing checkout success: $e';
      _isProcessingCheckout = false;
      notifyListeners();
      return false;
    }
  }
  
  // Check if URL has subscription success parameters
  bool hasSubscriptionSuccessParams(Uri uri) {
    return _subscriptionService.hasSubscriptionSuccessParams(uri);
  }
  
  // Get customer portal URL
  Future<String?> getCustomerPortalUrl() async {
    try {
      return await _subscriptionService.getCustomerPortalUrl();
    } catch (e) {
      _errorMessage = 'Error generating customer portal URL: $e';
      notifyListeners();
      return null;
    }
  }
  
  // Start a checkout process
  void startCheckout() {
    _isProcessingCheckout = true;
    notifyListeners();
  }
  
  // End a checkout process
  void endCheckout({bool success = false}) {
    _isProcessingCheckout = false;
    if (success) {
      // Force refresh subscription status after successful checkout
      refreshSubscriptionStatus();
    }
    notifyListeners();
  }
  
  // Start a free trial
  Future<bool> startFreeTrial({int trialDays = 14}) async {
    try {
      _isProcessingTrial = true;
      notifyListeners();
      
      final success = await _subscriptionService.startFreeTrial(trialDays: trialDays);
      
      if (success) {
        await refreshSubscriptionStatus();
      }
      
      _isProcessingTrial = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _errorMessage = 'Error starting free trial: $e';
      _isProcessingTrial = false;
      notifyListeners();
      return false;
    }
  }
  
  // Check if a trial is expired
  Future<bool> isTrialExpired() async {
    return await _subscriptionService.isTrialExpired();
  }
  
  // Get trial time remaining
  Future<Duration?> getTrialTimeRemaining() async {
    return await _subscriptionService.getTrialTimeRemaining();
  }
  
  // Save customer ID after checkout
  Future<void> saveCustomerId(String customerId) async {
    await _subscriptionService.saveCustomerId(customerId);
    // Refresh status after saving
    await refreshSubscriptionStatus();
  }
}







































// // lib/providers/subscription_provider.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:revboostapp/models/subscription_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class SubscriptionProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   bool _isLoading = false;
//   String? _errorMessage;
//   SubscriptionStatus _subscriptionStatus = SubscriptionStatus.free();
//   List<SubscriptionPlan> _availablePlans = [];

//   bool _isFreeTrial = false;
//   DateTime? _trialEndDate;

//   bool get isFreeTrial => _isFreeTrial;
//   DateTime? get trialEndDate => _trialEndDate;
  
//   // Your Lemon Squeezy store details
//   final String _storeId = '165054'; // Your store ID
//   final String _baseCheckoutUrl = 'https://webtonics.lemonsqueezy.com/buy';
  
//   // Getters
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
//   List<SubscriptionPlan> get availablePlans => _availablePlans;
//   bool get isSubscribed => _subscriptionStatus.isActive;
  
//   // Constructor - initialize data
//   SubscriptionProvider() {
//     _initializePlans();
//     reloadSubscriptionStatus();
//   }
  
//   void _initializePlans() {
//     // Define your subscription plans with real product IDs
//     _availablePlans = [
//       // SubscriptionPlan(
//       //   id: 'free',
//       //   name: 'Startup',
//       //   description: 'Full access to all premium features',
//       //   price: 9.99,
//       //   interval: 'monthly',
//       //   features: [
//       //     'Custom QR codes',
//       //     'Negative Review Filtering',
//       //     'Private feedback collection',
//       //     'Priority support',
//       //   ],
//       //   lemonSqueezyProductId: '5411962e-7695-4cb0-9f79-271fbc0c2964', // Test product ID
//       // ),
//       SubscriptionPlan(
//         id: 'monthly',
//         name: 'Pro',
//         description: 'Full access to all premium features',
//         price: 29.99,
//         interval: 'monthly',
//         features: [
//           'Unlimited review requests',
//           'Custom QR codes',
//           'Email & SMS review invites',
//           'Private feedback collection',
//           'Priority support',
//         ],
//         // lemonSqueezyggProductId: '5411962e-7695-4cb0-9f79-271fbc0c2964', // Test product ID
//         lemonSqueezyProductId: '0016db55-8733-4da7-977f-0d6e61bdab26', // Live product ID
//       ),
//       SubscriptionPlan(
//         id: 'yearly',
//         name: 'Pro Yearly',
//         description: 'Save 16% with annual billing',
//         price: 299.99,
//         interval: 'yearly',
//         features: [
//           'Everything in Pro Monthly',
//           '16% discount vs monthly plan',
//           'Priority 24/7 support',
//           'Dedicated account manager',
//         ],
//         // lemonSqueezyProductId: 'b5efc2ff-8c50-4d47-a34a-5e317feea837', // Test product ID
//         lemonSqueezyProductId: '167fb4dc-feaa-47c5-8447-df7b938a9564', // Live product ID
//       ),
//     ];
//   }
  
//   // Method to load subscription status
  
//   // In your loadSubscriptionStatus or reloadSubscriptionStatus method
// Future<void> _loadSubscriptionStatus() async {
//   if (_auth.currentUser == null) {
//     _subscriptionStatus = SubscriptionStatus.free();
//     notifyListeners();
//     return;
//   }
  
//   try {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
    
//     final userId = _auth.currentUser!.uid;
    
//     // Get user document
//     final userDoc = await _firestore.collection('users').doc(userId).get();
    
//     if (!userDoc.exists) {
//       _subscriptionStatus = SubscriptionStatus.free();
//       _isLoading = false;
//       notifyListeners();
//       return;
//     }
    
//     final userData = userDoc.data()!;
    
//     // Check subscription status
//     final status = userData['subscriptionStatus'] as String?;
//     final isActive = status == 'active' || status == 'on_trial';
    
//     // Check for free trial
//     final isFreeTrial = status == 'on_trial';
//     final trialEndDate = userData['trialEndDate'] != null
//         ? (userData['trialEndDate'] as Timestamp).toDate()
//         : null;
    
//     // Handle the orderId properly - convert to string if needed
//     String? orderId;
//     if (userData['subscriptionOrderId'] != null) {
//       // Convert to string regardless of original type
//       orderId = userData['subscriptionOrderId'].toString();
//     }
    
//     final planId = userData['subscriptionPlanId'] as String?;
//     final expiresAt = userData['subscriptionEndDate'] != null
//         ? (userData['subscriptionEndDate'] as Timestamp).toDate()
//         : null;
    
//     // Get customerId and ensure it's a string
//     String? customerId;
//     if (userData['lemonSqueezyCustomerId'] != null) {
//       customerId = userData['lemonSqueezyCustomerId'].toString();
//     }
    
//     _subscriptionStatus = SubscriptionStatus(
//       isActive: isActive,
//       planId: planId,
//       expiresAt: expiresAt,
//       orderId: orderId,
//       customerId: customerId,
//       isFreeTrial: isFreeTrial,
//       trialEndDate: trialEndDate,
//     );
    
//     _isLoading = false;
//     notifyListeners();
//   } catch (e) {
//     _isLoading = false;
//     _errorMessage = 'Error loading subscription status: $e';
//     notifyListeners();
//   }
// }


// Future<void> refreshSubscriptionStatus() async {
//   if (_auth.currentUser == null) {
//     _subscriptionStatus = SubscriptionStatus.free();
//     notifyListeners();
//     return;
//   }
  
//   try {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
    
//     final userId = _auth.currentUser!.uid;
    
//     // Get user document with cache disabled to ensure fresh data
//     final userDoc = await _firestore.collection('users').doc(userId)
//         .get(GetOptions(source: Source.server)); // Force server fetch
    
//     if (!userDoc.exists) {
//       _subscriptionStatus = SubscriptionStatus.free();
//       _isLoading = false;
//       notifyListeners();
//       return;
//     }
    
//     final userData = userDoc.data()!;
    
//     // Check subscription status
//     final status = userData['subscriptionStatus'] as String?;
//     final isActive = status == 'active' || status == 'on_trial';
    
//     // Check for free trial
//     final isFreeTrial = status == 'on_trial';
//     final trialEndDate = userData['trialEndDate'] != null
//         ? (userData['trialEndDate'] as Timestamp).toDate()
//         : null;
    
//     // Update instance variables
//     _isFreeTrial = isFreeTrial;
//     _trialEndDate = trialEndDate;
    
//     // Handle the orderId properly - convert to string if needed
//     String? orderId;
//     if (userData['subscriptionOrderId'] != null) {
//       // Convert to string regardless of original type
//       orderId = userData['subscriptionOrderId'].toString();
//     }
    
//     final planId = userData['subscriptionPlanId'] as String?;
//     final expiresAt = userData['subscriptionEndDate'] != null
//         ? (userData['subscriptionEndDate'] as Timestamp).toDate()
//         : null;
    
//     // Get customerId and ensure it's a string
//     String? customerId;
//     if (userData['lemonSqueezyCustomerId'] != null) {
//       customerId = userData['lemonSqueezyCustomerId'].toString();
//     }
    
//     _subscriptionStatus = SubscriptionStatus(
//       isActive: isActive,
//       planId: planId,
//       expiresAt: expiresAt,
//       orderId: orderId,
//       customerId: customerId,
//       isFreeTrial: isFreeTrial,
//       trialEndDate: trialEndDate,
//     );
    
//     debugPrint('Refreshed subscription status - isActive: $isActive, isFreeTrial: $isFreeTrial');
    
//     _isLoading = false;
//     notifyListeners();
//   } catch (e) {
//     _isLoading = false;
//     _errorMessage = 'Error refreshing subscription status: $e';
//     debugPrint(_errorMessage);
//     notifyListeners();
//   }
// }
//   // Save customer ID to shared preferences
//   Future<void> _saveCustomerId(String customerId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('lemonSqueezyCustomerId', customerId);
//     } catch (e) {
//       print('Error saving customer ID: $e');
//     }
//   }
  
//   // Get customer ID from shared preferences
//   Future<String?> _getCustomerId() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getString('lemonSqueezyCustomerId');
//     } catch (e) {
//       print('Error getting customer ID: $e');
//       return null;
//     }
//   }
  
//   // Public method to reload subscription status
//   Future<void> reloadSubscriptionStatus() async {
//     await _loadSubscriptionStatus();
//   }
  
//   // Get the checkout URL for a specific plan
//   String getCheckoutUrl(String planId) {
//     final plan = _availablePlans.firstWhere(
//       (plan) => plan.id == planId,
//       orElse: () => throw Exception('Plan not found'),
//     );
    
//     if (plan.lemonSqueezyProductId.isEmpty) {
//       throw Exception('Invalid product checkout URL');
//     }
    
//     // Get the user's email for identification
//     final userEmail = _auth.currentUser?.email ?? '';
    
//     // Build checkout URL with parameters
//     final baseUrl = '$_baseCheckoutUrl/${plan.lemonSqueezyProductId}';
//     final checkoutUrl = Uri.parse(baseUrl).replace(
//       queryParameters: {
//         'checkout[email]': userEmail,
//         'checkout[custom][user_id]': _auth.currentUser?.uid ?? '',
//         'checkout[custom][plan_id]': planId,
//         'checkout[custom][app_version]': '1.0',
//         'embed': '1', // For embedded checkout, if supported
//       },
//     ).toString();
    
//     return checkoutUrl;
//   }
  
//   // Get customer portal URL
//   // Future<String> getCustomerPortalUrl() async {
//   //   // Use the customer ID if possible
//   //   final customerId = await _getCustomerId() ?? 
//   //                    _subscriptionStatus.customerId;
    
//   //   if (customerId != null) {
//   //     return 'https://$_storeId.lemonsqueezy.com/billing?customer_id=$customerId';
//   //   }
    
//   //   // Fall back to email
//   //   final userEmail = _auth.currentUser?.email ?? '';
//   //   return 'https://$_storeId.lemonsqueezy.com/billing?customer_email=$userEmail';
//   // }
//   // Replace your existing getCustomerPortalUrl method with this updated version

// Future<String> getCustomerPortalUrl() async {
//   // Check if we have a customerId
//   final customerId = _subscriptionStatus.customerId;
//   final userEmail = _auth.currentUser?.email ?? '';
  
//   // Log the values for debugging
//   print('Store ID: $_storeId');
//   print('Customer ID: $customerId');
//   print('User Email: $userEmail');
  
//   // Get your store name - this is different from store ID
//   // Your store ID is numeric (165054), but the URL needs your store's subdomain
//   final storeName = 'webtonics'; // Replace with your actual store name from the URL
  
//   // Construct the base URL with the correct format
//   final baseUrl = 'https://$storeName.lemonsqueezy.com/billing';
  
//   // Add appropriate query parameters
//   if (customerId != null && customerId.isNotEmpty) {
//     // Use customer_id parameter for direct lookup
//     return '$baseUrl?customer_id=$customerId';
//   } else if (userEmail.isNotEmpty) {
//     // Fall back to email if no customer ID is available
//     return '$baseUrl?email=${Uri.encodeComponent(userEmail)}';
//   } else {
//     // Fallback if neither is available
//     throw Exception('No customer identifier available for billing portal');
//   }
// }
  
//   // For testing - simulates a subscription status check
//   Future<bool> checkSubscriptionStatus() async {
//     if (_auth.currentUser == null) return false;
    
//     try {
//       await reloadSubscriptionStatus();
//       return _subscriptionStatus.isActive;
//     } catch (e) {
//       _errorMessage = 'Error checking subscription: $e';
//       notifyListeners();
//       return false;
//     }
//   }
  
//   // For testing - simulates cancellation
//   Future<void> cancelSubscription() async {
//     if (_auth.currentUser == null) return;
    
//     try {
//       final userId = _auth.currentUser!.uid;
      
//       await _firestore.collection('users').doc(userId).update({
//         'subscriptionStatus': 'cancelled',
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       await reloadSubscriptionStatus();
//     } catch (e) {
//       _errorMessage = 'Error cancelling subscription: $e';
//       notifyListeners();
//     }
//   }
// }