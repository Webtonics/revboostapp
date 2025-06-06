// // lib/providers/enhanced_dashboard_provider.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:revboostapp/core/services/email_service.dart';
// import 'package:revboostapp/core/services/feedback_service.dart';
// import 'package:revboostapp/core/services/page_view_service.dart';
// import 'package:revboostapp/core/services/review_request_service.dart';
// import 'package:revboostapp/models/business_model.dart';

// class DashboardStats {
//   final int totalReviewRequests;
//   final int reviewsReceived;
//   final int qrCodeScans;
//   final int pageViews;
//   final double averageRating;
//   final double clickThroughRate;
//   final double conversionRate;
//   final Map<String, int> ratingDistribution;
//   final Map<String, int> sourceBreakdown;
//   final Map<String, int> dailyViews;
//   final List<RecentActivity> recentActivity;
//   final Map<String, dynamic> reviewRequestStats;
//   final Map<String, dynamic> feedbackStats;
//   final DateTime lastUpdated;

//   DashboardStats({
//     required this.totalReviewRequests,
//     required this.reviewsReceived,
//     required this.qrCodeScans,
//     required this.pageViews,
//     required this.averageRating,
//     required this.clickThroughRate,
//     required this.conversionRate,
//     required this.ratingDistribution,
//     required this.sourceBreakdown,
//     required this.dailyViews,
//     required this.recentActivity,
//     required this.reviewRequestStats,
//     required this.feedbackStats,
//     required this.lastUpdated,
//   });

//   factory DashboardStats.empty() {
//     return DashboardStats(
//       totalReviewRequests: 0,
//       reviewsReceived: 0,
//       qrCodeScans: 0,
//       pageViews: 0,
//       averageRating: 0.0,
//       clickThroughRate: 0.0,
//       conversionRate: 0.0,
//       ratingDistribution: {},
//       sourceBreakdown: {},
//       dailyViews: {},
//       recentActivity: [],
//       reviewRequestStats: {},
//       feedbackStats: {},
//       lastUpdated: DateTime.now(),
//     );
//   }
// }

// class RecentActivity {
//   final String title;
//   final String subtitle;
//   final DateTime timestamp;
//   final ActivityType type;
//   final Map<String, dynamic>? metadata;

//   RecentActivity({
//     required this.title,
//     required this.subtitle,
//     required this.timestamp,
//     required this.type,
//     this.metadata,
//   });
// }

// enum ActivityType {
//   newReview,
//   newFeedback,
//   requestSent,
//   pageView,
//   qrScan,
// }

// class EnhancedDashboardProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final PageViewService _pageViewService = PageViewService();
  
//   bool _isLoading = false;
//   String? _errorMessage;
//   BusinessModel? _businessData;
//   DashboardStats _stats = DashboardStats.empty();
  
//   // Services will be initialized when business is loaded
//   FeedbackService? _feedbackService;
//   ReviewRequestService? _reviewRequestService;
  
//   // Getters
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   BusinessModel? get businessData => _businessData;
//   DashboardStats get stats => _stats;
  
//   /// Load complete dashboard data with all metrics
//   Future<void> loadDashboardData() async {
//     if (_auth.currentUser == null) {
//       _errorMessage = 'User not authenticated';
//       notifyListeners();
//       return;
//     }
    
//     try {
//       _isLoading = true;
//       _errorMessage = null;
//       notifyListeners();
      
//       final userId = _auth.currentUser!.uid;
      
//       // Fetch the user's business
//       final businessesSnapshot = await _firestore
//           .collection('businesses')
//           .where('ownerId', isEqualTo: userId)
//           .limit(1)
//           .get();
      
//       if (businessesSnapshot.docs.isEmpty) {
//         _errorMessage = 'No business found. Please complete business setup first.';
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
      
//       // Get business data
//       _businessData = BusinessModel.fromFirestore(businessesSnapshot.docs.first);
      
//       // Initialize services now that we have business data
//       await _initializeServices();
      
//       // Load all dashboard statistics
//       await _loadAllStatistics();
      
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = 'Error loading dashboard data: $e';
//       notifyListeners();
//     }
//   }
  
//   /// Initialize services with business context
//   Future<void> _initializeServices() async {
//     if (_businessData == null) return;
    
//     // Create a dummy email service for the feedback and review request services
//     final emailService = EmailService(
//       apiKey: '', 
//       fromEmail: 'noreply@revboostapp.com',
//       fromName: 'RevBoost',
//     );
    
//     _feedbackService = FeedbackService(emailService: emailService);
//     _reviewRequestService = ReviewRequestService(emailService: emailService);
//   }
  
//   /// Load all statistics from different services
//   Future<void> _loadAllStatistics() async {
//     if (_businessData == null || _feedbackService == null || _reviewRequestService == null) {
//       return;
//     }
    
//     try {
//       // Fetch all data in parallel for better performance
//       final results = await Future.wait([
//         _reviewRequestService!.getReviewRequestStatistics(_businessData!.id),
//         _feedbackService!.getFeedbackStatistics(_businessData!.id),
//         _pageViewService.getPageViewStatistics(_businessData!.id),
//         _loadRecentActivity(),
//       ]);
      
//       final reviewRequestStats = results[0] as Map<String, dynamic>;
//       final feedbackStats = results[1] as Map<String, dynamic>;
//       final pageViewStats = results[2] as Map<String, dynamic>;
//       final recentActivity = results[3] as List<RecentActivity>;
      
//       // Build comprehensive dashboard stats
//       _stats = DashboardStats(
//         totalReviewRequests: reviewRequestStats['total'] ?? 0,
//         reviewsReceived: feedbackStats['total'] ?? 0,
//         qrCodeScans: _calculateQRScans(pageViewStats),
//         pageViews: pageViewStats['total'] ?? 0,
//         averageRating: (feedbackStats['averageRating'] ?? 0.0).toDouble(),
//         clickThroughRate: (reviewRequestStats['clickRate'] ?? 0.0).toDouble(),
//         conversionRate: (pageViewStats['conversionRate'] ?? 0.0).toDouble(),
//         ratingDistribution: _convertRatingDistribution(feedbackStats['ratingCounts']),
//         sourceBreakdown: Map<String, int>.from(pageViewStats['sourceBreakdown'] ?? {}),
//         dailyViews: Map<String, int>.from(pageViewStats['dailyViews'] ?? {}),
//         recentActivity: recentActivity,
//         reviewRequestStats: reviewRequestStats,
//         feedbackStats: feedbackStats,
//         lastUpdated: DateTime.now(),
//       );
      
//     } catch (e) {
//       debugPrint('Error loading statistics: $e');
//       // Keep existing stats on error
//     }
//   }
  
//   /// Calculate QR code scans from page view data
//   int _calculateQRScans(Map<String, dynamic> pageViewStats) {
//     final sourceBreakdown = pageViewStats['sourceBreakdown'] as Map<String, dynamic>? ?? {};
//     return (sourceBreakdown['qr'] ?? 0) as int;
//   }
  
//   /// Convert rating distribution to proper format
//   Map<String, int> _convertRatingDistribution(dynamic ratingCounts) {
//     if (ratingCounts == null) return {};
    
//     final Map<String, int> distribution = {};
//     if (ratingCounts is Map) {
//       ratingCounts.forEach((key, value) {
//         distribution[key.toString()] = (value as num).toInt();
//       });
//     }
//     return distribution;
//   }
  
//   /// Load recent activity from multiple sources
//   Future<List<RecentActivity>> _loadRecentActivity() async {
//     if (_businessData == null) return [];
    
//     final List<RecentActivity> activities = [];
    
//     try {
//       // Get recent page views
//       final endDate = DateTime.now();
//       final startDate = endDate.subtract(const Duration(days: 7));
      
//       final pageViews = await _pageViewService.getPageViewsForPeriod(
//         businessId: _businessData!.id,
//         startDate: startDate,
//         endDate: endDate,
//       );
      
//       // Convert page views to activities
//       for (final pv in pageViews.take(5)) {
//         final source = pv['source'] as String? ?? 'unknown';
//         final completed = pv['completed'] as bool? ?? false;
        
//         String title, subtitle;
//         ActivityType type;
        
//         if (completed) {
//           title = 'New ${pv['rating'] != null ? 'Review' : 'Feedback'} Received';
//           subtitle = 'Customer left ${pv['rating'] ?? 'feedback'} ${pv['rating'] != null ? 'stars' : ''}';
//           type = ActivityType.newReview;
//         } else {
//           title = 'Page View';
//           subtitle = 'Customer visited review page via $source';
//           type = ActivityType.pageView;
//         }
        
//         activities.add(RecentActivity(
//           title: title,
//           subtitle: subtitle,
//           timestamp: pv['timestamp'] as DateTime,
//           type: type,
//           metadata: {'source': source},
//         ));
//       }
      
//       // Sort by timestamp (most recent first)
//       activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
//     } catch (e) {
//       debugPrint('Error loading recent activity: $e');
//     }
    
//     return activities.take(10).toList();
//   }
  
//   /// Refresh dashboard data
//   Future<void> refresh() async {
//     await loadDashboardData();
//   }
  
//   /// Get growth percentage for a metric
//   double getGrowthPercentage(String metric) {
//     // This would typically compare current period to previous period
//     // For now, return a mock growth percentage
//     switch (metric) {
//       case 'reviews':
//         return 12.5;
//       case 'requests':
//         return 8.3;
//       case 'pageViews':
//         return 15.2;
//       case 'rating':
//         return 2.1;
//       default:
//         return 0.0;
//     }
//   }
  
//   /// Get trend direction for a metric
//   bool isMetricTrending(String metric) {
//     return getGrowthPercentage(metric) > 0;
//   }
  
//   /// Get the review page URL for preview
//   String getReviewPageUrl() {
//     if (_businessData == null) return '';
    
//     // This would be your actual domain in production
//     const baseUrl = 'https://app.revboostapp.com';
//     return '$baseUrl/r/${_businessData!.id}';
//   }
// }

// lib/providers/simplified_dashboard_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revboostapp/core/services/simple_page_view_service.dart';
import 'package:revboostapp/models/business_model.dart';

class SimplifiedDashboardStats {
  final int totalReviewRequests;
  final int reviewsReceived;
  final int pageViews;
  final int qrCodeScans;
  final double averageRating;
  final double conversionRate;
  final Map<String, int> ratingDistribution;
  final Map<String, int> sourceBreakdown;
  final List<SimpleRecentActivity> recentActivity;
  final DateTime lastUpdated;

  SimplifiedDashboardStats({
    required this.totalReviewRequests,
    required this.reviewsReceived,
    required this.pageViews,
    required this.qrCodeScans,
    required this.averageRating,
    required this.conversionRate,
    required this.ratingDistribution,
    required this.sourceBreakdown,
    required this.recentActivity,
    required this.lastUpdated,
  });

  factory SimplifiedDashboardStats.empty() {
    return SimplifiedDashboardStats(
      totalReviewRequests: 0,
      reviewsReceived: 0,
      pageViews: 0,
      qrCodeScans: 0,
      averageRating: 0.0,
      conversionRate: 0.0,
      ratingDistribution: {},
      sourceBreakdown: {},
      recentActivity: [],
      lastUpdated: DateTime.now(),
    );
  }
}

class SimpleRecentActivity {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String type;

  SimpleRecentActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
  });
}

class SimplifiedDashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SimplePageViewService _pageViewService = SimplePageViewService();
  
  bool _isLoading = false;
  String? _errorMessage;
  BusinessModel? _businessData;
  SimplifiedDashboardStats _stats = SimplifiedDashboardStats.empty();
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BusinessModel? get businessData => _businessData;
  SimplifiedDashboardStats get stats => _stats;
  
  /// Load dashboard data with simplified approach
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
      
      // Get the user's business
      await _loadBusinessData(userId);
      
      if (_businessData == null) {
        _errorMessage = 'No business found. Please complete business setup first.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Load all the simplified statistics
      await _loadSimplifiedStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading dashboard data: $e';
      notifyListeners();
    }
  }
  
  Future<void> _loadBusinessData(String userId) async {
    try {
      // Try to get business from user document first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final businessIds = List<String>.from(userData['businessIds'] ?? []);
        
        if (businessIds.isNotEmpty) {
          final businessDoc = await _firestore.collection('businesses').doc(businessIds.first).get();
          if (businessDoc.exists) {
            _businessData = BusinessModel.fromFirestore(businessDoc);
            return;
          }
        }
      }
      
      // Fallback: query businesses by owner
      final businessQuery = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (businessQuery.docs.isNotEmpty) {
        _businessData = BusinessModel.fromFirestore(businessQuery.docs.first);
      }
    } catch (e) {
      debugPrint('Error loading business data: $e');
    }
  }
  
  Future<void> _loadSimplifiedStats() async {
    if (_businessData == null) return;
    
    try {
      final businessId = _businessData!.id;
      
      // Get all data in parallel
      final results = await Future.wait([
        _getReviewRequestsCount(businessId),
        _getFeedbackStats(businessId),
        _pageViewService.getSimpleStats(businessId),
        _pageViewService.getRecentPageViews(businessId: businessId, limit: 10),
      ]);
      
      final reviewRequestsCount = results[0] as int;
      final feedbackStats = results[1] as Map<String, dynamic>;
      final pageViewStats = results[2] as Map<String, dynamic>;
      final recentPageViews = results[3] as List<Map<String, dynamic>>;
      
      // Build simplified stats
      _stats = SimplifiedDashboardStats(
        totalReviewRequests: reviewRequestsCount,
        reviewsReceived: feedbackStats['total'] ?? 0,
        pageViews: pageViewStats['totalViews'] ?? 0,
        qrCodeScans: pageViewStats['qrScans'] ?? 0,
        averageRating: (feedbackStats['averageRating'] ?? 0.0).toDouble(),
        conversionRate: (pageViewStats['conversionRate'] ?? 0.0).toDouble(),
        ratingDistribution: Map<String, int>.from(feedbackStats['ratingDistribution'] ?? {}),
        sourceBreakdown: Map<String, int>.from(pageViewStats['sourceBreakdown'] ?? {}),
        recentActivity: _buildSimpleRecentActivity(recentPageViews),
        lastUpdated: DateTime.now(),
      );
      
      debugPrint('📊 Dashboard stats loaded:');
      debugPrint('  - Page Views: ${_stats.pageViews}');
      debugPrint('  - QR Scans: ${_stats.qrCodeScans}');
      debugPrint('  - Reviews: ${_stats.reviewsReceived}');
      debugPrint('  - Conversion: ${(_stats.conversionRate * 100).toStringAsFixed(1)}%');
      
    } catch (e) {
      debugPrint('Error loading simplified stats: $e');
      // Keep existing stats on error
    }
  }
  
  /// Get count of review requests sent
  Future<int> _getReviewRequestsCount(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('reviewRequests')
          .where('businessId', isEqualTo: businessId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting review requests count: $e');
      return 0;
    }
  }
  
  /// Get feedback statistics
  Future<Map<String, dynamic>> _getFeedbackStats(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('feedback')
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final feedbacks = snapshot.docs;
      final total = feedbacks.length;
      
      if (total == 0) {
        return {
          'total': 0,
          'averageRating': 0.0,
          'ratingDistribution': <String, int>{},
        };
      }
      
      // Calculate average rating
      double totalRating = 0;
      Map<String, int> ratingDistribution = {};
      
      for (final doc in feedbacks) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0).toDouble();
        totalRating += rating;
        
        final ratingKey = rating.toInt().toString();
        ratingDistribution[ratingKey] = (ratingDistribution[ratingKey] ?? 0) + 1;
      }
      
      return {
        'total': total,
        'averageRating': totalRating / total,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      debugPrint('Error getting feedback stats: $e');
      return {
        'total': 0,
        'averageRating': 0.0,
        'ratingDistribution': <String, int>{},
      };
    }
  }
  
  /// Build simple recent activity from page views
  List<SimpleRecentActivity> _buildSimpleRecentActivity(List<Map<String, dynamic>> pageViews) {
    final activities = <SimpleRecentActivity>[];
    
    for (final pv in pageViews) {
      final source = pv['source'] as String? ?? 'unknown';
      final completed = pv['completed'] as bool? ?? false;
      final rating = pv['rating'] as double?;
      final timestamp = pv['timestamp'] as DateTime;
      
      String title, subtitle;
      
      if (completed && rating != null) {
        title = 'New Review Received';
        subtitle = 'Customer left ${rating.toInt()} stars via $source';
      } else {
        title = 'Page View';
        subtitle = 'Customer visited review page via $source';
      }
      
      activities.add(SimpleRecentActivity(
        title: title,
        subtitle: subtitle,
        timestamp: timestamp,
        type: completed ? 'review' : 'view',
      ));
    }
    
    return activities;
  }
  
  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }
  
  /// Get growth percentage (mock data for now)
  double getGrowthPercentage(String metric) {
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
  
  /// Get the review page URL
  String getReviewPageUrl() {
    if (_businessData == null) return '';
    const baseUrl = 'https://app.revboostapp.com';
    return '$baseUrl/r/${_businessData!.id}';
  }
}