// lib/providers/enhanced_dashboard_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/feedback_service.dart';
import 'package:revboostapp/core/services/page_view_service.dart';
import 'package:revboostapp/core/services/review_request_service.dart';
import 'package:revboostapp/models/business_model.dart';

class DashboardStats {
  final int totalReviewRequests;
  final int reviewsReceived;
  final int qrCodeScans;
  final int pageViews;
  final double averageRating;
  final double clickThroughRate;
  final double conversionRate;
  final Map<String, int> ratingDistribution;
  final Map<String, int> sourceBreakdown;
  final Map<String, int> dailyViews;
  final List<RecentActivity> recentActivity;
  final Map<String, dynamic> reviewRequestStats;
  final Map<String, dynamic> feedbackStats;
  final DateTime lastUpdated;

  DashboardStats({
    required this.totalReviewRequests,
    required this.reviewsReceived,
    required this.qrCodeScans,
    required this.pageViews,
    required this.averageRating,
    required this.clickThroughRate,
    required this.conversionRate,
    required this.ratingDistribution,
    required this.sourceBreakdown,
    required this.dailyViews,
    required this.recentActivity,
    required this.reviewRequestStats,
    required this.feedbackStats,
    required this.lastUpdated,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalReviewRequests: 0,
      reviewsReceived: 0,
      qrCodeScans: 0,
      pageViews: 0,
      averageRating: 0.0,
      clickThroughRate: 0.0,
      conversionRate: 0.0,
      ratingDistribution: {},
      sourceBreakdown: {},
      dailyViews: {},
      recentActivity: [],
      reviewRequestStats: {},
      feedbackStats: {},
      lastUpdated: DateTime.now(),
    );
  }
}

class RecentActivity {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;
  final Map<String, dynamic>? metadata;

  RecentActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.metadata,
  });
}

enum ActivityType {
  newReview,
  newFeedback,
  requestSent,
  pageView,
  qrScan,
}

class EnhancedDashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageViewService _pageViewService = PageViewService();
  
  bool _isLoading = false;
  String? _errorMessage;
  BusinessModel? _businessData;
  DashboardStats _stats = DashboardStats.empty();
  
  // Services will be initialized when business is loaded
  FeedbackService? _feedbackService;
  ReviewRequestService? _reviewRequestService;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BusinessModel? get businessData => _businessData;
  DashboardStats get stats => _stats;
  
  /// Load complete dashboard data with all metrics
  Future<void> loadDashboardData() async {
    if (_auth.currentUser == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final userId = _auth.currentUser!.uid;
      
      // Fetch the user's business
      final businessesSnapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (businessesSnapshot.docs.isEmpty) {
        _errorMessage = 'No business found. Please complete business setup first.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get business data
      _businessData = BusinessModel.fromFirestore(businessesSnapshot.docs.first);
      
      // Initialize services now that we have business data
      await _initializeServices();
      
      // Load all dashboard statistics
      await _loadAllStatistics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading dashboard data: $e';
      notifyListeners();
    }
  }
  
  /// Initialize services with business context
  Future<void> _initializeServices() async {
    if (_businessData == null) return;
    
    // Create a dummy email service for the feedback and review request services
    final emailService = EmailService(
      apiKey: '', 
      fromEmail: 'noreply@revboostapp.com',
      fromName: 'RevBoost',
    );
    
    _feedbackService = FeedbackService(emailService: emailService);
    _reviewRequestService = ReviewRequestService(emailService: emailService);
  }
  
  /// Load all statistics from different services
  Future<void> _loadAllStatistics() async {
    if (_businessData == null || _feedbackService == null || _reviewRequestService == null) {
      return;
    }
    
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _reviewRequestService!.getReviewRequestStatistics(_businessData!.id),
        _feedbackService!.getFeedbackStatistics(_businessData!.id),
        _pageViewService.getPageViewStatistics(_businessData!.id),
        _loadRecentActivity(),
      ]);
      
      final reviewRequestStats = results[0] as Map<String, dynamic>;
      final feedbackStats = results[1] as Map<String, dynamic>;
      final pageViewStats = results[2] as Map<String, dynamic>;
      final recentActivity = results[3] as List<RecentActivity>;
      
      // Build comprehensive dashboard stats
      _stats = DashboardStats(
        totalReviewRequests: reviewRequestStats['total'] ?? 0,
        reviewsReceived: feedbackStats['total'] ?? 0,
        qrCodeScans: _calculateQRScans(pageViewStats),
        pageViews: pageViewStats['total'] ?? 0,
        averageRating: (feedbackStats['averageRating'] ?? 0.0).toDouble(),
        clickThroughRate: (reviewRequestStats['clickRate'] ?? 0.0).toDouble(),
        conversionRate: (pageViewStats['conversionRate'] ?? 0.0).toDouble(),
        ratingDistribution: _convertRatingDistribution(feedbackStats['ratingCounts']),
        sourceBreakdown: Map<String, int>.from(pageViewStats['sourceBreakdown'] ?? {}),
        dailyViews: Map<String, int>.from(pageViewStats['dailyViews'] ?? {}),
        recentActivity: recentActivity,
        reviewRequestStats: reviewRequestStats,
        feedbackStats: feedbackStats,
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      // Keep existing stats on error
    }
  }
  
  /// Calculate QR code scans from page view data
  int _calculateQRScans(Map<String, dynamic> pageViewStats) {
    final sourceBreakdown = pageViewStats['sourceBreakdown'] as Map<String, dynamic>? ?? {};
    return (sourceBreakdown['qr'] ?? 0) as int;
  }
  
  /// Convert rating distribution to proper format
  Map<String, int> _convertRatingDistribution(dynamic ratingCounts) {
    if (ratingCounts == null) return {};
    
    final Map<String, int> distribution = {};
    if (ratingCounts is Map) {
      ratingCounts.forEach((key, value) {
        distribution[key.toString()] = (value as num).toInt();
      });
    }
    return distribution;
  }
  
  /// Load recent activity from multiple sources
  Future<List<RecentActivity>> _loadRecentActivity() async {
    if (_businessData == null) return [];
    
    final List<RecentActivity> activities = [];
    
    try {
      // Get recent page views
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      final pageViews = await _pageViewService.getPageViewsForPeriod(
        businessId: _businessData!.id,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Convert page views to activities
      for (final pv in pageViews.take(5)) {
        final source = pv['source'] as String? ?? 'unknown';
        final completed = pv['completed'] as bool? ?? false;
        
        String title, subtitle;
        ActivityType type;
        
        if (completed) {
          title = 'New ${pv['rating'] != null ? 'Review' : 'Feedback'} Received';
          subtitle = 'Customer left ${pv['rating'] ?? 'feedback'} ${pv['rating'] != null ? 'stars' : ''}';
          type = ActivityType.newReview;
        } else {
          title = 'Page View';
          subtitle = 'Customer visited review page via $source';
          type = ActivityType.pageView;
        }
        
        activities.add(RecentActivity(
          title: title,
          subtitle: subtitle,
          timestamp: pv['timestamp'] as DateTime,
          type: type,
          metadata: {'source': source},
        ));
      }
      
      // Sort by timestamp (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    }
    
    return activities.take(10).toList();
  }
  
  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }
  
  /// Get growth percentage for a metric
  double getGrowthPercentage(String metric) {
    // This would typically compare current period to previous period
    // For now, return a mock growth percentage
    switch (metric) {
      case 'reviews':
        return 12.5;
      case 'requests':
        return 8.3;
      case 'pageViews':
        return 15.2;
      case 'rating':
        return 2.1;
      default:
        return 0.0;
    }
  }
  
  /// Get trend direction for a metric
  bool isMetricTrending(String metric) {
    return getGrowthPercentage(metric) > 0;
  }
  
  /// Get the review page URL for preview
  String getReviewPageUrl() {
    if (_businessData == null) return '';
    
    // This would be your actual domain in production
    const baseUrl = 'https://app.revboostapp.com';
    return '$baseUrl/r/${_businessData!.id}';
  }
}