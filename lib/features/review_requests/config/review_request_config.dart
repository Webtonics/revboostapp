// lib/features/review_requests/config/review_request_config.dart

import 'package:flutter/material.dart';

/// Configuration settings for the review request feature
class ReviewRequestConfig {
  /// Resend API key for sending emails
  /// Note: In production, this should be fetched from a secure source,
  /// not hardcoded in the app.
  static const String resendApiKey = 'YOUR_RESEND_API_KEY';
  
  /// Sender email address for review requests
  static const String senderEmail = 'reviews@revboostapp.com';
  
  /// Sender name for review requests
  static const String senderName = 'RevBoost';
  
  /// Minimum delay between review request emails to the same customer
  static const Duration resendDelay = Duration(days: 7);
  
  /// Maximum number of review requests that can be sent in a single batch
  static const int maxBatchSize = 100;
  
  /// Maximum number of review requests per business in the free tier
  static const int freeRequestsLimit = 25;
  
  /// Color mappings for review request statuses
  static const Map<String, Color> statusColors = {
    'pending': Colors.grey,
    'sent': Colors.blue,
    'clicked': Colors.purple,
    'completed': Colors.green,
    'failed': Colors.red,
  };
  
  /// Gets a color for a status
  static Color getStatusColor(String status) {
    return statusColors[status.toLowerCase()] ?? Colors.grey;
  }
  
  /// Email templates for review requests
  static const Map<String, String> emailTemplates = {
    'standard': 'standard_template',
    'minimal': 'minimal_template',
    'branded': 'branded_template',
  };
  
  /// Validation settings
  static const Map<String, dynamic> validation = {
    'email': {
      'pattern': r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      'errorMessage': 'Please enter a valid email address',
    },
    'phone': {
      'pattern': r'^\+?[0-9]{10,15}$',
      'errorMessage': 'Please enter a valid phone number',
    },
  };
  
  /// Analytics event names for tracking
  static const Map<String, String> analyticsEvents = {
    'reviewRequestSent': 'review_request_sent',
    'reviewRequestClicked': 'review_request_clicked',
    'reviewSubmitted': 'review_submitted',
    'bulkImport': 'bulk_import_completed',
  };
  
  /// Review rating thresholds
  static const int positiveRatingThreshold = 4; // 4-5 stars are considered positive
  
  /// Default URL for review page
  static String getDefaultReviewUrl(String baseUrl, String businessId) {
    return '$baseUrl/r/$businessId';
  }
  
  /// Creates tracking parameters for a review URL
  static String addTrackingToUrl(String url, String trackingId, {String? source}) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    queryParams['tracking_id'] = trackingId;
    if (source != null) {
      queryParams['source'] = source;
    }
    
    return uri.replace(queryParameters: queryParams).toString();
  }
}