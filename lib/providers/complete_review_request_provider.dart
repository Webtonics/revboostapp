// lib/providers/complete_review_request_provider.dart
// Complete provider with CSV import and batch sending

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/complete_review_request_service.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/simple_rate_limiting_service.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/models/review_request_model.dart';

enum ReviewRequestOperationStatus {
  initial,
  loading,
  success,
  error,
  rateLimited,
}

class CompleteReviewRequestProvider with ChangeNotifier {
  final CompleteReviewRequestService _service;
  final String _userId;
  final String _businessId;
  final String _businessName;
  final String _planType;
  
  ReviewRequestOperationStatus _status = ReviewRequestOperationStatus.initial;
  String? _errorMessage;
  List<ReviewRequestModel> _reviewRequests = [];
  Map<String, dynamic> _usageStats = {};
  bool _isStatisticsLoading = false;
  
  // Stream subscription for review requests
  StreamSubscription<List<ReviewRequestModel>>? _reviewRequestsSubscription;
  
  /// Creates a [CompleteReviewRequestProvider] instance
  CompleteReviewRequestProvider({
    required EmailService emailService,
    required String userId,
    required String businessId,
    required String businessName,
    required String planType,
  }) : _service = CompleteReviewRequestService(emailService: emailService),
       _userId = userId,
       _businessId = businessId,
       _businessName = businessName,
       _planType = planType {
    _initialize();
  }
  
  // Getters
  ReviewRequestOperationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<ReviewRequestModel> get reviewRequests => _reviewRequests;
  Map<String, dynamic> get usageStats => _usageStats;
  bool get isStatisticsLoading => _isStatisticsLoading;
  
  // Usage statistics getters
  int get monthlyUsed => _usageStats['used'] ?? 0;
  int get monthlyLimit => _usageStats['limit'] ?? 100;
  int get monthlyRemaining => _usageStats['remaining'] ?? 100;
  double get monthlyUsagePercent => monthlyLimit > 0 ? (monthlyUsed / monthlyLimit * 100).clamp(0, 100) : 0;
  bool get hasUsageData => _usageStats.isNotEmpty;
  bool get isNearLimit => monthlyUsagePercent > 80;
  bool get canSendRequests => monthlyRemaining > 0;
  
  // Premium feature access
  bool get hasPremiumAccess => ['pro', 'monthly', 'yearly'].contains(_planType.toLowerCase());
  
  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      notifyListeners();
      
      // Load usage statistics
      await refreshUsageStats();
      
      // Start listening to review requests
      _startListeningToRequests();
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Start listening to review requests
  void _startListeningToRequests() {
    _reviewRequestsSubscription = _service
        .getReviewRequestsForBusiness(_businessId)
        .listen((requests) {
          _reviewRequests = requests;
          notifyListeners();
        });
  }
  
  /// Refresh usage statistics
  Future<void> refreshUsageStats() async {
    try {
      _usageStats = await _service.getUserUsageStats(_userId, _planType);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing usage stats: $e');
    }
  }
  
  /// Create and send single review request
  Future<bool> createAndSendReviewRequest({
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required BusinessModel business,
    String? replyToEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('Creating review request for: $customerEmail');
      
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      // Generate review link
      const baseUrl = "https://app.revboostapp.com";
      final reviewLink = '$baseUrl/r/${business.id}';
      
      // Create and send the request
      await _service.createAndSendReviewRequest(
        userId: _userId,
        businessId: _businessId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        businessName: _businessName,
        reviewLink: reviewLink,
        planType: _planType,
        replyToEmail: replyToEmail,
        metadata: metadata,
      );
      
      // Refresh usage stats
      await refreshUsageStats();
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return true;
    } on RateLimitException catch (e) {
      debugPrint('Rate limit exceeded: ${e.message}');
      
      _status = ReviewRequestOperationStatus.rateLimited;
      _errorMessage = e.message;
      notifyListeners();
      
      return false;
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('Error creating review request: $errorMsg');
      
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = errorMsg.contains('Exception: ') 
          ? errorMsg.replaceFirst('Exception: ', '')
          : errorMsg;
      notifyListeners();
      
      return false;
    }
  }
  
  /// Import contacts from CSV (Premium feature)
  Future<Map<String, dynamic>> importContactsFromCsv({
    required List<Map<String, String>> contacts,
    required BusinessModel business,
    bool sendImmediately = false,
  }) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      // Generate review link
      const baseUrl = "https://app.revboostapp.com";
      final reviewLink = '$baseUrl/r/${business.id}';
      
      final result = await _service.importContactsFromCsv(
        userId: _userId,
        businessId: _businessId,
        businessName: _businessName,
        planType: _planType,
        contacts: contacts,
        reviewLink: reviewLink,
        sendImmediately: sendImmediately,
      );
      
      // Refresh usage stats
      await refreshUsageStats();
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return result;
    } on RateLimitException catch (e) {
      _status = ReviewRequestOperationStatus.rateLimited;
      _errorMessage = e.message;
      notifyListeners();
      
      return {
        'successful': 0,
        'failed': contacts.length,
        'errors': [e.message],
        'rateLimited': true,
      };
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      
      return {
        'successful': 0,
        'failed': contacts.length,
        'errors': [e.toString()],
      };
    }
  }
  
  /// Batch send existing requests (Premium feature)
  Future<Map<String, dynamic>> batchSendRequests({
    required List<String> requestIds,
  }) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final result = await _service.batchSendRequests(
        userId: _userId,
        businessName: _businessName,
        planType: _planType,
        requestIds: requestIds,
      );
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return result;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      
      return {
        'successful': 0,
        'failed': requestIds.length,
        'errors': [e.toString()],
      };
    }
  }
  
  /// Delete review request
  Future<bool> deleteReviewRequest(String requestId) async {
    try {
      await _service.deleteReviewRequest(requestId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete request: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Get usage summary text
  String getUsageSummary() {
    if (!hasUsageData) return 'Loading usage data...';
    
    final percentage = monthlyUsagePercent.round();
    return 'Used $monthlyUsed of $monthlyLimit requests this month ($percentage%)';
  }
  
  /// Get rate limit warning
  String? getRateLimitWarning() {
    if (!hasUsageData) return null;
    
    if (monthlyRemaining <= 0) {
      return 'Monthly limit reached. Upgrade to send more requests.';
    } else if (monthlyRemaining <= 5) {
      return 'Only $monthlyRemaining requests remaining this month.';
    }
    
    return null;
  }
  
  /// Check if user can send a specific number of requests
  bool canSendRequestCount(int count) {
    return monthlyRemaining >= count;
  }
  
  /// Get filtered review requests
  List<ReviewRequestModel> getFilteredRequests({
    String? searchQuery,
    List<ReviewRequestStatus>? statusFilter,
  }) {
    if ((searchQuery == null || searchQuery.isEmpty) && 
        (statusFilter == null || statusFilter.isEmpty)) {
      return _reviewRequests;
    }
    
    return _reviewRequests.where((request) {
      // Apply status filter
      if (statusFilter != null && statusFilter.isNotEmpty && 
          !statusFilter.contains(request.status)) {
        return false;
      }
      
      // Apply search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return request.customerName.toLowerCase().contains(query) ||
               request.customerEmail.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  /// Get requests that can be batch sent (pending or failed)
  List<ReviewRequestModel> getBatchSendableRequests() {
    return _reviewRequests.where((request) => 
        request.status == ReviewRequestStatus.pending || 
        request.status == ReviewRequestStatus.failed
    ).toList();
  }
  
  /// Clear error state
  void clearError() {
    _status = ReviewRequestOperationStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _reviewRequestsSubscription?.cancel();
    super.dispose();
  }
}