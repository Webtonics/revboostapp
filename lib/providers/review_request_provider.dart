// lib/providers/review_request_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/review_request_service.dart';
import 'package:revboostapp/core/utils/utils/throttler.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/models/review_request_model.dart';

/// Status of a review request operation
enum ReviewRequestOperationStatus {
  initial,
  loading,
  success,
  error,
}

/// Result of a batch operation
class BatchOperationResult {
  final int success;
  final int failure;
  final List<String> errors;
  
  BatchOperationResult({
    required this.success,
    required this.failure,
    this.errors = const [],
  });
}

/// Provider for managing review requests
class ReviewRequestProvider with ChangeNotifier {
  final ReviewRequestService _reviewRequestService;
  final String _businessId;
  final String _businessName;
  
  ReviewRequestOperationStatus _status = ReviewRequestOperationStatus.initial;
  String? _errorMessage;
  List<ReviewRequestModel> _reviewRequests = [];
  Map<String, dynamic> _statistics = {};
  bool _isStatisticsLoading = false;
  
  // Stream subscription for review requests
  StreamSubscription<List<ReviewRequestModel>>? _reviewRequestsSubscription;
  
  // Throttler to prevent excessive statistics refreshes
  final Throttler _statsThrottler = Throttler(const Duration(seconds: 5));
  
  /// Creates a [ReviewRequestProvider] instance
  ReviewRequestProvider({
    required EmailService emailService,
    required String businessId,
    required String businessName,
  }) : _reviewRequestService = ReviewRequestService(emailService: emailService),
       _businessId = businessId,
       _businessName = businessName {
    _initialize();
  }
  
  /// Current operation status
  ReviewRequestOperationStatus get status => _status;
  
  /// Error message if operation failed
  String? get errorMessage => _errorMessage;
  
  /// List of review requests
  List<ReviewRequestModel> get reviewRequests => _reviewRequests;
  
  /// Statistics for review requests
  Map<String, dynamic> get statistics => _statistics;
  
  /// Whether statistics are currently loading
  bool get isStatisticsLoading => _isStatisticsLoading;
  
  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      notifyListeners();
      
      // Start listening to review requests stream
      _reviewRequestsSubscription = _reviewRequestService
          .getReviewRequestsForBusiness(_businessId)
          .listen((requests) {
            _reviewRequests = requests;
            notifyListeners();
            
            // Throttle statistics refresh when requests change
            _statsThrottler.run(() {
              refreshStatistics();
            });
          });
      
      // Load statistics
      await refreshStatistics();
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to load review requests: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Refresh statistics
  Future<void> refreshStatistics() async {
    try {
      _isStatisticsLoading = true;
      notifyListeners();
      
      _statistics = await _reviewRequestService.getReviewRequestStatistics(_businessId);
      
      _isStatisticsLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing statistics: $e');
      _isStatisticsLoading = false;
      notifyListeners();
    }
  }
  
  /// Create and send a review request with improved error handling
  Future<bool> createAndSendReviewRequest({
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required BusinessModel business,
    String? replyToEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('Starting to create and send review request to: $customerEmail');
      
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      // Create review link with special tracking parameter
      const baseUrl = "https://app.revboostapp.com";
      final reviewLink = '$baseUrl/r/${business.id}';
      
      debugPrint('Generated review link: $reviewLink');
      
      // Create the review request
      debugPrint('Creating review request in Firestore...');
      String? requestId;
      try {
        requestId = await _reviewRequestService.createReviewRequest(
          businessId: _businessId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          reviewLink: reviewLink,
          metadata: {
            'source': 'manual',
            'createdAt': DateTime.now().toIso8601String(),
            ...metadata ?? {},
          },
        );
        debugPrint('Review request created with ID: $requestId');
      } catch (e) {
        debugPrint('Error creating review request in Firestore: $e');
        throw Exception('Failed to save review request: $e');
      }
      
      // Send the email
      debugPrint('Sending email to $customerEmail...');
      bool emailSent = false;
      try {
        emailSent = await _reviewRequestService.sendReviewRequestEmail(
          requestId: requestId,
          customerName: customerName,
          customerEmail: customerEmail,
          businessName: _businessName,
          reviewLink: reviewLink,
          replyToEmail: replyToEmail,
        );
        debugPrint('Email sent successfully: $emailSent');
      } catch (e) {
        debugPrint('Error sending email: $e');
        throw e; // Re-throw to be caught by outer try-catch
      }
      
      if (!emailSent) {
        debugPrint('Email service reported failure');
        throw Exception('Failed to send email: The email service reported a failure.');
      }
      
      // Refresh statistics
      try {
        await refreshStatistics();
      } catch (e) {
        debugPrint('Error refreshing statistics: $e');
        // This shouldn't fail the whole operation
      }
      
      debugPrint('Review request process completed successfully');
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('Error in createAndSendReviewRequest: $errorMsg');
      _status = ReviewRequestOperationStatus.error;
      
      // Clean up the error message a bit
      if (errorMsg.contains('Exception: ')) {
        _errorMessage = errorMsg.replaceFirst('Exception: ', '');
      } else {
        _errorMessage = errorMsg;
      }
      
      notifyListeners();
      return false;
    }
  }
  
  /// Delete a review request
  Future<bool> deleteReviewRequest(String requestId) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _reviewRequestService.deleteReviewRequest(requestId);
      
      // Statistics will be updated by the stream listener
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to delete review request: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Resend a review request
  Future<bool> resendReviewRequest(String requestId) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final success = await _reviewRequestService.resendReviewRequest(
        requestId: requestId,
        businessName: _businessName,
      );
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return success;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to resend review request: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Import review requests from CSV
  Future<Map<String, dynamic>> importReviewRequestsFromCsv({
    required List<Map<String, dynamic>> contacts,
    required String reviewLink,
    bool sendImmediately = false,
  }) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final result = await _reviewRequestService.importReviewRequestsFromCsv(
        businessId: _businessId,
        contacts: contacts,
        businessName: _businessName,
        reviewLink: reviewLink,
        sendImmediately: sendImmediately,
      );
      
      // Refresh statistics
      await refreshStatistics();
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return result;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to import review requests: ${e.toString()}';
      notifyListeners();
      
      return {
        'successful': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }
  
  /// Bulk send review requests
  Future<Map<String, dynamic>> bulkSendReviewRequests({
    required List<String> requestIds,
  }) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final result = await _reviewRequestService.bulkSendReviewRequests(
        businessId: _businessId,
        businessName: _businessName,
        requestIds: requestIds,
      );
      
      // Refresh statistics
      await refreshStatistics();
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return result;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to send review requests: ${e.toString()}';
      notifyListeners();
      
      return {
        'successful': 0,
        'failed': requestIds.length,
        'errors': [e.toString()],
      };
    }
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
  
  /// Get a review request by ID
  Future<ReviewRequestModel?> getReviewRequestById(String id) async {
    return await _reviewRequestService.getReviewRequestById(id);
  }
  
  /// Delete multiple review requests in batch
  Future<bool> batchDeleteRequests(List<String> requestIds) async {
    if (requestIds.isEmpty) return true;
    
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      int successCount = 0;
      List<String> errors = [];
      
      // Process deletions sequentially to avoid overwhelming Firestore
      for (final requestId in requestIds) {
        try {
          await _reviewRequestService.deleteReviewRequest(requestId);
          successCount++;
        } catch (e) {
          errors.add('Failed to delete request $requestId: ${e.toString()}');
        }
      }
      
      // Refresh statistics
      await refreshStatistics();
      
      _status = ReviewRequestOperationStatus.success;
      _errorMessage = errors.isEmpty ? null : errors.join('\n');
      notifyListeners();
      
      return successCount == requestIds.length;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to batch delete review requests: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Resend multiple review requests in batch
  Future<BatchOperationResult> batchResendRequests(List<String> requestIds, BusinessModel business) async {
    if (requestIds.isEmpty) {
      return BatchOperationResult(success: 0, failure: 0);
    }
    
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];
      
      // Process resends sequentially to avoid rate limiting
      for (final requestId in requestIds) {
        try {
          // Get the request details
          final request = await _reviewRequestService.getReviewRequestById(requestId);
          
          if (request != null) {
            final success = await _reviewRequestService.resendReviewRequest(
              requestId: requestId,
              businessName: _businessName,
            );
            
            if (success) {
              successCount++;
            } else {
              failureCount++;
              errors.add('Failed to resend request to ${request.customerEmail}');
            }
          } else {
            failureCount++;
            errors.add('Request $requestId not found');
          }
        } catch (e) {
          failureCount++;
          errors.add('Error resending request $requestId: ${e.toString()}');
        }
        
        // Add a small delay to avoid overwhelming the email service
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Refresh statistics
      await refreshStatistics();
      
      _status = ReviewRequestOperationStatus.success;
      _errorMessage = errors.isEmpty ? null : errors.join('\n');
      notifyListeners();
      
      return BatchOperationResult(
        success: successCount,
        failure: failureCount,
        errors: errors,
      );
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to batch resend review requests: ${e.toString()}';
      notifyListeners();
      
      return BatchOperationResult(
        success: 0,
        failure: requestIds.length,
        errors: [e.toString()],
      );
    }
  }
  
  /// Resend a single review request using the request model
  Future<bool> resendRequest(ReviewRequestModel request, BusinessModel business) async {
    try {
      _status = ReviewRequestOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final success = await _reviewRequestService.resendReviewRequest(
        requestId: request.id,
        businessName: _businessName,
      );
      
      _status = ReviewRequestOperationStatus.success;
      notifyListeners();
      
      return success;
    } catch (e) {
      _status = ReviewRequestOperationStatus.error;
      _errorMessage = 'Failed to resend review request: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Manually set error state (useful for UI timeout handling)
  void setErrorState(String message) {
    _status = ReviewRequestOperationStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _reviewRequestsSubscription?.cancel();
    _statsThrottler.dispose();
    super.dispose();
  }
}