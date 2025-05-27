// lib/core/services/feedback_service.dart - Updated with Page View Integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/page_view_service.dart';
import 'package:revboostapp/core/services/review_request_service.dart';
import 'package:revboostapp/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;
  final EmailService _emailService;
  final PageViewService _pageViewService = PageViewService();
  final String _collectionName = 'feedback';
  
  FeedbackService({
    required EmailService emailService,
    FirebaseFirestore? firestore,
  }) : _emailService = emailService,
       _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Submit new feedback with page view and review request tracking
  Future<String> submitFeedback({
    required String businessId,
    required double rating,
    required String feedback,
    String? businessName,
    String? businessEmail,
    String? customerName,
    String? customerEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Extract tracking information from metadata
      final trackingId = metadata?['trackingId'] as String?;
      final source = metadata?['source'] as String? ?? 'direct';
      
      // Create the feedback document
      final feedbackData = {
        'businessId': businessId,
        'rating': rating,
        'feedback': feedback,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'customerName': customerName,
        'customerEmail': customerEmail,
        'metadata': {
          'source': source,
          'trackingId': trackingId,
          'submittedAt': DateTime.now().toIso8601String(),
          ...metadata ?? {},
        },
      };
      
      // Add to Firestore
      final docRef = await _firestore.collection(_collectionName).add(feedbackData);
      
      // Update page view completion if tracking ID is available
      if (trackingId != null) {
        try {
          await _pageViewService.updatePageViewCompletion(
            businessId: businessId,
            trackingId: trackingId,
            rating: rating,
            completed: true,
          );
          
          // Also update the review request status if this came from an email
          if (source == 'email') {
            final reviewRequestService = ReviewRequestService(
              emailService: _emailService,
              firestore: _firestore,
            );
            
            await reviewRequestService.updateRequestByTrackingId(
              trackingId: trackingId,
              status: 'completed',
              rating: rating.toInt(),
              feedback: feedback,
            );
          }
        } catch (e) {
          debugPrint('Error updating tracking information: $e');
          // Don't fail the feedback submission if tracking update fails
        }
      } else {
        // If no tracking ID, try to update the most recent page view
        try {
          await _pageViewService.updatePageViewCompletion(
            businessId: businessId,
            trackingId: null,
            rating: rating,
            completed: true,
          );
        } catch (e) {
          debugPrint('Error updating page view without tracking ID: $e');
          // Don't fail the feedback submission
        }
      }
      
      // Update business statistics
      await _updateBusinessFeedbackStats(businessId, rating);
      
      // Send notification for negative feedback
      if (rating <= 3 && businessEmail != null && businessName != null) {
        try {
          await _emailService.sendFeedbackNotification(
            businessId: businessId,
            toEmail: businessEmail,
            businessName: businessName,
            rating: rating,
            feedback: feedback,
            customerName: customerName ?? 'Anonymous Customer',
          );
        } catch (e) {
          debugPrint('Error sending feedback notification: $e');
          // Don't fail the feedback submission if notification fails
        }
      }
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }
  
  /// Get all feedback for a business
  Stream<List<FeedbackModel>> getFeedbackForBusiness(String businessId) {
    return _firestore
        .collection(_collectionName)
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList();
        });
  }
  
  /// Get a specific feedback by ID
  Future<FeedbackModel?> getFeedbackById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (doc.exists) {
        return FeedbackModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting feedback: $e');
      return null;
    }
  }
  
  /// Update feedback status (e.g., mark as reviewed or block)
  Future<bool> updateFeedbackStatus(String id, FeedbackStatus status) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If blocked, increment blocked count
      if (status == FeedbackStatus.blocked) {
        final doc = await _firestore.collection(_collectionName).doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final businessId = data['businessId'];
          
          await _firestore.collection('businesses').doc(businessId).update({
            'feedbackStats.blockedCount': FieldValue.increment(1),
          });
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating feedback status: $e');
      return false;
    }
  }
  
  /// Get comprehensive feedback statistics including page view correlation
  Future<Map<String, dynamic>> getFeedbackStatistics(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final feedbacks = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
      
      // Calculate basic statistics
      int total = feedbacks.length;
      double averageRating = 0;
      Map<double, int> ratingCounts = {};
      int negativeCount = 0;
      int blockedCount = 0;
      Map<String, int> sourceBreakdown = {};
      
      if (total > 0) {
        double sum = 0;
        for (var feedback in feedbacks) {
          sum += feedback.rating;
          ratingCounts[feedback.rating] = (ratingCounts[feedback.rating] ?? 0) + 1;
          
          if (feedback.rating <= 3) {
            negativeCount++;
          }
          
          if (feedback.status == FeedbackStatus.blocked) {
            blockedCount++;
          }
          
          // Track sources
          final source = feedback.metadata?['source'] as String? ?? 'unknown';
          sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + 1;
        }
        
        averageRating = sum / total;
      }
      
      // Get page view statistics for correlation
      Map<String, dynamic> pageViewStats = {};
      try {
        pageViewStats = await _pageViewService.getPageViewStatistics(businessId);
      } catch (e) {
        debugPrint('Error getting page view statistics: $e');
      }
      
      // Time-based analysis (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentFeedbacks = feedbacks.where(
        (feedback) => feedback.createdAt.isAfter(thirtyDaysAgo)
      ).toList();
      
      // Calculate conversion rate (feedback submissions vs page views)
      double conversionRate = 0;
      if (pageViewStats['total'] != null && pageViewStats['total'] > 0) {
        conversionRate = total / pageViewStats['total'];
      }
      
      // Check if there's already a stats document for this business
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (businessDoc.exists) {
        final data = businessDoc.data();
        if (data != null && data['feedbackStats'] != null) {
          // Use the stored blockedCount if available
          blockedCount = data['feedbackStats']['blockedCount'] ?? blockedCount;
        }
      }
      
      return {
        'total': total,
        'averageRating': averageRating,
        'ratingCounts': ratingCounts,
        'negativeCount': negativeCount,
        'blockedCount': blockedCount,
        'sourceBreakdown': sourceBreakdown,
        'conversionRate': conversionRate,
        'pageViews': pageViewStats,
        'recent': {
          'total': recentFeedbacks.length,
          'averageRating': recentFeedbacks.isNotEmpty 
              ? recentFeedbacks.map((f) => f.rating).reduce((a, b) => a + b) / recentFeedbacks.length
              : 0,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting feedback statistics: $e');
      return {};
    }
  }
  
  /// Update business feedback statistics
  Future<void> _updateBusinessFeedbackStats(String businessId, double rating) async {
    try {
      final businessRef = _firestore.collection('businesses').doc(businessId);
      
      // Get current business data
      final businessDoc = await businessRef.get();
      
      if (businessDoc.exists) {
        // Update feedback stats
        await businessRef.update({
          'feedbackStats.totalCount': FieldValue.increment(1),
          'feedbackStats.lastUpdated': FieldValue.serverTimestamp(),
          if (rating <= 3) 'feedbackStats.negativeCount': FieldValue.increment(1),
        });
      } else {
        // Create initial feedback stats
        await businessRef.set({
          'feedbackStats': {
            'totalCount': 1,
            'negativeCount': rating <= 3 ? 1 : 0,
            'blockedCount': 0,
            'lastUpdated': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating business feedback stats: $e');
    }
  }

  /// Get feedback for business (one-time fetch)
  Future<List<FeedbackModel>> getFeedbackForBusinessOnce(String businessId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('businessId', isEqualTo: businessId)
        .get();

    return snapshot.docs.map((doc) {
      return FeedbackModel.fromFirestore(doc);
    }).toList();
  }
  
  /// Get feedback statistics for a specific time period
  Future<Map<String, dynamic>> getFeedbackStatsForPeriod({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      final feedbacks = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
      
      if (feedbacks.isEmpty) {
        return {
          'total': 0,
          'averageRating': 0,
          'ratingCounts': <double, int>{},
          'sourceBreakdown': <String, int>{},
        };
      }
      
      // Calculate period statistics
      final total = feedbacks.length;
      final sum = feedbacks.map((f) => f.rating).fold(0.0, (a, b) => a + b);
      final averageRating = sum / total;
      
      final Map<double, int> ratingCounts = {};
      final Map<String, int> sourceBreakdown = {};
      
      for (final feedback in feedbacks) {
        ratingCounts[feedback.rating] = (ratingCounts[feedback.rating] ?? 0) + 1;
        
        final source = feedback.metadata?['source'] as String? ?? 'unknown';
        sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + 1;
      }
      
      return {
        'total': total,
        'averageRating': averageRating,
        'ratingCounts': ratingCounts,
        'sourceBreakdown': sourceBreakdown,
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Error getting feedback stats for period: $e');
      return {};
    }
  }
  
  /// Get daily feedback counts for chart display
  Future<Map<String, int>> getDailyFeedbackCounts({
    required String businessId,
    required int days,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      final feedbacks = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
      
      // Initialize daily counts
      final Map<String, int> dailyCounts = {};
      for (int i = 0; i < days; i++) {
        final date = endDate.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyCounts[dateKey] = 0;
      }
      
      // Count feedbacks by day
      for (final feedback in feedbacks) {
        final date = feedback.createdAt;
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (dailyCounts.containsKey(dateKey)) {
          dailyCounts[dateKey] = dailyCounts[dateKey]! + 1;
        }
      }
      
      return dailyCounts;
    } catch (e) {
      debugPrint('Error getting daily feedback counts: $e');
      return {};
    }
  }
}