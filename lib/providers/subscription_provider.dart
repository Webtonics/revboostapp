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
  
  // Trial eligibility
  bool _isEligibleForTrial = false;
  Duration? _trialTimeRemaining;
  bool _hasHadTrial = false;
  bool _hasHadSubscription = false;
  
  // Getters
  SubscriptionProviderStatus get status => _status;
  String? get errorMessage => _errorMessage;
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  String? get selectedPlanId => _selectedPlanId;
  bool get isProcessingCheckout => _isProcessingCheckout;
  bool get isProcessingTrial => _isProcessingTrial;
  
  // Enhanced computed properties
  bool get isSubscribed => _subscriptionStatus.isActive && !_subscriptionStatus.isFreeTrial;
  bool get isFreeTrial => _subscriptionStatus.isFreeTrial;
  bool get hasActiveAccess => _subscriptionStatus.isActive;
  bool get isEligibleForTrial => _isEligibleForTrial;
  bool get hasHadTrial => _hasHadTrial;
  bool get hasHadSubscription => _hasHadSubscription;
  DateTime? get trialEndDate => _subscriptionStatus.trialEndDate;
  Duration? get trialTimeRemaining => _trialTimeRemaining;
  
  // Constructor
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
  

  String get currentPlanType {
  if (isSubscribed) {
    return _subscriptionStatus.planId ?? 'free';
  } else if (isFreeTrial) {
    return 'trial';
  } else {
    return 'free';
  }
}
  // Load subscription status with trial checks
  Future<void> _loadSubscriptionStatus() async {
    try {
      _status = SubscriptionProviderStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      _subscriptionStatus = await _subscriptionService.getSubscriptionStatus();
      await _loadEligibilityData();
      
      _status = SubscriptionProviderStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = SubscriptionProviderStatus.error;
      _errorMessage = 'Error loading subscription status: $e';
      notifyListeners();
    }
  }
  
  // Load trial eligibility and history data
  Future<void> _loadEligibilityData() async {
    try {
      _isEligibleForTrial = await _subscriptionService.isEligibleForFreeTrial();
      
      final historyData = await _subscriptionService.getUserSubscriptionHistory();
      _hasHadTrial = historyData['hasHadTrial'] ?? false;
      _hasHadSubscription = historyData['hasHadSubscription'] ?? false;
      
      if (_subscriptionStatus.isFreeTrial) {
        _trialTimeRemaining = await _subscriptionService.getTrialTimeRemaining();
      }
    } catch (e) {
      debugPrint('Error loading eligibility data: $e');
      _isEligibleForTrial = false;
      _hasHadTrial = true;
      _hasHadSubscription = false;
    }
  }
  
  // Reload subscription status with enhanced checks
  Future<void> reloadSubscriptionStatus({bool forceRefresh = false}) async {
    try {
      _status = SubscriptionProviderStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      _subscriptionStatus = await _subscriptionService.getSubscriptionStatus(
        forceRefresh: forceRefresh
      );
      
      await _loadEligibilityData();
      
      _status = SubscriptionProviderStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = SubscriptionProviderStatus.error;
      _errorMessage = 'Error reloading subscription status: $e';
      notifyListeners();
    }
  }
  
  // Enhanced refresh method that always force refreshes
  Future<void> refreshSubscriptionStatus() async {
    await reloadSubscriptionStatus(forceRefresh: true);
  }
  
  // Start free trial with enhanced validation
  Future<bool> startFreeTrial({int trialDays = 14}) async {
    if (!_isEligibleForTrial) {
      _errorMessage = 'You are not eligible for a free trial';
      notifyListeners();
      return false;
    }
    
    try {
      _isProcessingTrial = true;
      _errorMessage = null;
      notifyListeners();
      
      final success = await _subscriptionService.startFreeTrial(trialDays: trialDays);
      
      if (success) {
        await refreshSubscriptionStatus();
      } else {
        _errorMessage = 'Failed to start free trial. You may have already used your trial.';
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

  // Check if trial is expired (useful for UI)
  Future<bool> isTrialExpired() async {
    return await _subscriptionService.isTrialExpired();
  }
  
  // Get detailed trial information for UI display
  Map<String, dynamic> getTrialInfo() {
    if (!_subscriptionStatus.isFreeTrial) {
      return {
        'isOnTrial': false,
        'daysRemaining': 0,
        'hoursRemaining': 0,
        'isExpired': false,
        'statusText': 'Not on trial',
      };
    }
    
    if (_trialTimeRemaining == null || _trialTimeRemaining!.isNegative) {
      return {
        'isOnTrial': false,
        'daysRemaining': 0,
        'hoursRemaining': 0,
        'isExpired': true,
        'statusText': 'Trial expired',
      };
    }
    
    final days = _trialTimeRemaining!.inDays;
    final hours = _trialTimeRemaining!.inHours % 24;
    
    String statusText;
    if (days > 0) {
      statusText = '$days day${days == 1 ? '' : 's'} remaining';
    } else if (hours > 0) {
      statusText = '$hours hour${hours == 1 ? '' : 's'} remaining';
    } else {
      statusText = 'Less than 1 hour remaining';
    }
    
    return {
      'isOnTrial': true,
      'daysRemaining': days,
      'hoursRemaining': hours,
      'isExpired': false,
      'statusText': statusText,
    };
  }
  
  // Get reason why trial is not available
  String getTrialUnavailableReason() {
    if (_hasHadSubscription) {
      return 'You have already been a subscriber';
    }
    if (_hasHadTrial) {
      return 'You have already used your free trial';
    }
    if (_subscriptionStatus.isActive) {
      if (_subscriptionStatus.isFreeTrial) {
        return 'You are currently on a free trial';
      }
      return 'You have an active subscription';
    }
    return 'Free trial not available';
  }
  
  // Get human-readable trial status
  String getTrialStatusText() {
    if (!_subscriptionStatus.isFreeTrial) {
      return 'Not on trial';
    }
    
    if (_trialTimeRemaining == null) {
      return 'Trial status unknown';
    }
    
    if (_trialTimeRemaining!.isNegative || _trialTimeRemaining! == Duration.zero) {
      return 'Trial expired';
    }
    
    final days = _trialTimeRemaining!.inDays;
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} remaining';
    }
    
    final hours = _trialTimeRemaining!.inHours;
    if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} remaining';
    }
    
    return 'Less than 1 hour remaining';
  }

  // Rest of your existing methods...
  void selectPlan(String planId) {
    _selectedPlanId = planId;
    notifyListeners();
  }
  
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
  
  void openCheckoutInNewTab() {
    final url = getCheckoutUrl(redirect: true);
    if (url != null) {
      _subscriptionService.openCheckoutUrl(url);
    }
  }
  
  Future<void> openBillingPortal() async {
    try {
      final url = await _subscriptionService.getCustomerPortalUrl();
      _subscriptionService.openCheckoutUrl(url);
    } catch (e) {
      _errorMessage = 'Error opening billing portal: $e';
      notifyListeners();
    }
  }
  
  void redirectToCheckout() {
    final url = getCheckoutUrl(redirect: true);
    if (url != null) {
      _isProcessingCheckout = true;
      notifyListeners();
      _subscriptionService.redirectToCheckout(url);
    }
  }
  
  bool hasSubscriptionSuccessParams(Uri uri) {
    return _subscriptionService.hasSubscriptionSuccessParams(uri);
  }
  
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
  
  Future<String?> getCustomerPortalUrl() async {
    try {
      return await _subscriptionService.getCustomerPortalUrl();
    } catch (e) {
      _errorMessage = 'Error generating customer portal URL: $e';
      notifyListeners();
      return null;
    }
  }
  
  void startCheckout() {
    _isProcessingCheckout = true;
    notifyListeners();
  }
  
  void endCheckout({bool success = false}) {
    _isProcessingCheckout = false;
    if (success) {
      refreshSubscriptionStatus();
    }
    notifyListeners();
  }
  
  Future<void> saveCustomerId(String customerId) async {
    await _subscriptionService.saveCustomerId(customerId);
    await refreshSubscriptionStatus();
  }
}