// lib/providers/feedback_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/feedback_service.dart';
import 'package:revboostapp/core/utils/utils/throttler.dart';
import 'package:revboostapp/models/feedback_model.dart';

/// Status of a feedback operation
enum FeedbackOperationStatus {
  initial,
  loading,
  success,
  error,
}

class FeedbackProvider with ChangeNotifier {
  final FeedbackService _feedbackService;
  final String _businessId;
  final String _businessName;
  final String? _businessEmail;
  
  FeedbackOperationStatus _status = FeedbackOperationStatus.initial;
  String? _errorMessage;
  List<FeedbackModel> _feedbacks = [];
  Map<String, dynamic> _statistics = {};
  bool _isStatisticsLoading = false;
  
  // Stream subscription for feedbacks
  StreamSubscription<List<FeedbackModel>>? _feedbacksSubscription;
  
  // Throttler to prevent excessive statistics refreshes
  final Throttler _statsThrottler = Throttler(const Duration(seconds: 5));
  
  /// Creates a [FeedbackProvider] instance
  FeedbackProvider({
    required EmailService emailService,
    required String businessId,
    required String businessName,
    String? businessEmail,
  }) : _feedbackService = FeedbackService(emailService: emailService),
       _businessId = businessId,
       _businessName = businessName,
       _businessEmail = businessEmail {
    _initialize();
  }
  
  /// Current operation status
  FeedbackOperationStatus get status => _status;
  
  /// Error message if operation failed
  String? get errorMessage => _errorMessage;
  
  /// List of feedbacks
  List<FeedbackModel> get feedbacks => _feedbacks;
  
  /// Statistics for feedbacks
  Map<String, dynamic> get statistics => _statistics;
  
  /// Whether statistics are currently loading
  bool get isStatisticsLoading => _isStatisticsLoading;
  
  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      _status = FeedbackOperationStatus.loading;
      notifyListeners();
      
      // Start listening to feedbacks stream
      _feedbacksSubscription = _feedbackService
          .getFeedbackForBusiness(_businessId)
          .listen((feedbacks) {
            _feedbacks = feedbacks;
            notifyListeners();
            
            // Throttle statistics refresh when feedbacks change
            _statsThrottler.run(() {
              refreshStatistics();
            });
          });
      
      // Load statistics
      await refreshStatistics();
      
      _status = FeedbackOperationStatus.success;
      notifyListeners();
    } catch (e) {
      _status = FeedbackOperationStatus.error;
      _errorMessage = 'Failed to load feedbacks: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Refresh statistics
  Future<void> refreshStatistics() async {
    try {
      _isStatisticsLoading = true;
      notifyListeners();
      
      _statistics = await _feedbackService.getFeedbackStatistics(_businessId);
      
      _isStatisticsLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing statistics: $e');
      _isStatisticsLoading = false;
      notifyListeners();
    }
  }
  
  /// Submit feedback
  Future<bool> submitFeedback({
    required double rating,
    required String feedback,
    String? customerName,
    String? customerEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _status = FeedbackOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _feedbackService.submitFeedback(
        businessId: _businessId,
        rating: rating,
        feedback: feedback,
        businessName: _businessName,
        businessEmail: _businessEmail,
        customerName: customerName,
        customerEmail: customerEmail,
        metadata: {
          'source': 'app',
          'submittedAt': DateTime.now().toIso8601String(),
          ...metadata ?? {},
        },
      );
      
      // Refresh statistics
      await refreshStatistics();
      
      _status = FeedbackOperationStatus.success;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = FeedbackOperationStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Update feedback status
  Future<bool> updateFeedbackStatus(String feedbackId, FeedbackStatus status) async {
    try {
      _status = FeedbackOperationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final success = await _feedbackService.updateFeedbackStatus(feedbackId, status);
      
      // Statistics will be updated by the stream listener
      
      _status = FeedbackOperationStatus.success;
      notifyListeners();
      
      return success;
    } catch (e) {
      _status = FeedbackOperationStatus.error;
      _errorMessage = 'Failed to update feedback status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Get filtered feedbacks
  List<FeedbackModel> getFilteredFeedbacks({
    String? searchQuery,
    List<FeedbackStatus>? statusFilter,
    double? minRating,
    double? maxRating,
  }) {
    if ((searchQuery == null || searchQuery.isEmpty) && 
        (statusFilter == null || statusFilter.isEmpty) &&
        minRating == null && maxRating == null) {
      return _feedbacks;
    }
    
    return _feedbacks.where((feedback) {
      // Apply status filter
      if (statusFilter != null && statusFilter.isNotEmpty && 
          !statusFilter.contains(feedback.status)) {
        return false;
      }
      
      // Apply rating filter
      if (minRating != null && feedback.rating < minRating) {
        return false;
      }
      
      if (maxRating != null && feedback.rating > maxRating) {
        return false;
      }
      
      // Apply search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final nameMatch = feedback.customerName != null && 
                         feedback.customerName!.toLowerCase().contains(query);
        final emailMatch = feedback.customerEmail != null && 
                          feedback.customerEmail!.toLowerCase().contains(query);
        final feedbackMatch = feedback.feedback.toLowerCase().contains(query);
        
        return nameMatch || emailMatch || feedbackMatch;
      }
      
      return true;
    }).toList();
  }
  
  @override
  void dispose() {
    _feedbacksSubscription?.cancel();
    _statsThrottler.dispose();
    super.dispose();
  }
}