// lib/core/services/page_view_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:universal_html/html.dart' as html;

/// Service for tracking page views and analytics
class PageViewService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final String _collectionName = 'pageViews';
  
  /// Track a page view when someone visits the review page
  Future<void> trackPageView({
    required String businessId,
    String source = 'direct',
    String? trackingId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get user agent and other browser info if available
      String? userAgent;
      String? referrer;
      
      if (kIsWeb) {
        try {
          userAgent = html.window.navigator.userAgent;
          referrer = html.document.referrer;
        } catch (e) {
          debugPrint('Could not get browser info: $e');
        }
      }
      
      // Create page view document
      final pageViewData = {
        'businessId': businessId,
        'timestamp': FieldValue.serverTimestamp(),
        'source': source, // 'qr', 'email', 'direct', 'link'
        'trackingId': trackingId,
        'userAgent': userAgent,
        'referrer': referrer,
        'completed': false, // Will be updated if they submit feedback
        'rating': null, // Will be updated if they submit feedback
        'metadata': metadata ?? {},
      };
      
      // Add to Firestore
      await _firestore.collection(_collectionName).add(pageViewData);
      
      debugPrint('Page view tracked for business: $businessId, source: $source');
    } catch (e) {
      debugPrint('Error tracking page view: $e');
      // Don't throw error - page view tracking shouldn't break the app
    }
  }
  
  /// Update page view when user completes feedback/review
  Future<void> updatePageViewCompletion({
    required String businessId,
    String? trackingId,
    required double rating,
    bool completed = true,
  }) async {
    try {
      // Find the most recent page view for this business/tracking ID
      Query query = _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .where('completed', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1);
      
      // If we have a tracking ID, use it for more precise matching
      if (trackingId != null && trackingId.isNotEmpty) {
        query = _firestore
            .collection(_collectionName)
            .where('businessId', isEqualTo: businessId)
            .where('trackingId', isEqualTo: trackingId)
            .where('completed', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .limit(1);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        
        await _firestore.collection(_collectionName).doc(docId).update({
          'completed': completed,
          'rating': rating,
          'completedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Page view completion updated for business: $businessId');
      } else {
        debugPrint('No matching page view found to update completion');
      }
    } catch (e) {
      debugPrint('Error updating page view completion: $e');
      // Don't throw error - this shouldn't break the feedback submission
    }
  }
  
  /// Get page view statistics for a business
  Future<Map<String, dynamic>> getPageViewStatistics(String businessId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // Get all page views for this business
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final pageViews = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'source': data['source'] ?? 'unknown',
          'completed': data['completed'] ?? false,
          'rating': data['rating'],
          'trackingId': data['trackingId'],
        };
      }).toList();
      
      // Calculate statistics
      final total = pageViews.length;
      final completed = pageViews.where((pv) => pv['completed'] == true).length;
      final conversionRate = total > 0 ? completed / total : 0.0;
      
      // Recent views (last 30 days)
      final recentViews = pageViews.where((pv) {
        final timestamp = pv['timestamp'] as DateTime;
        return timestamp.isAfter(thirtyDaysAgo);
      }).toList();
      
      // Last 7 days
      final weeklyViews = pageViews.where((pv) {
        final timestamp = pv['timestamp'] as DateTime;
        return timestamp.isAfter(sevenDaysAgo);
      }).toList();
      
      // Source breakdown
      final Map<String, int> sourceBreakdown = {};
      for (final pv in pageViews) {
        final source = pv['source'] as String;
        sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + 1;
      }
      
      // Daily breakdown for last 7 days
      final Map<String, int> dailyViews = {};
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        final dayViews = pageViews.where((pv) {
          final timestamp = pv['timestamp'] as DateTime;
          return timestamp.year == date.year &&
                 timestamp.month == date.month &&
                 timestamp.day == date.day;
        }).length;
        
        dailyViews[dateKey] = dayViews;
      }
      
      return {
        'total': total,
        'completed': completed,
        'conversionRate': conversionRate,
        'recent': {
          'thirtyDays': recentViews.length,
          'sevenDays': weeklyViews.length,
        },
        'sourceBreakdown': sourceBreakdown,
        'dailyViews': dailyViews,
        'averageRating': _calculateAverageRating(pageViews),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting page view statistics: $e');
      return {};
    }
  }
  
  /// Calculate average rating from completed page views
  double _calculateAverageRating(List<Map<String, dynamic>> pageViews) {
    final completedWithRating = pageViews
        .where((pv) => pv['completed'] == true && pv['rating'] != null)
        .toList();
    
    if (completedWithRating.isEmpty) return 0.0;
    
    final sum = completedWithRating
        .map((pv) => (pv['rating'] as num).toDouble())
        .fold(0.0, (a, b) => a + b);
    
    return sum / completedWithRating.length;
  }
  
  /// Get page views for a specific time period
  Future<List<Map<String, dynamic>>> getPageViewsForPeriod({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'source': data['source'] ?? 'unknown',
          'completed': data['completed'] ?? false,
          'rating': data['rating'],
          'trackingId': data['trackingId'],
          'userAgent': data['userAgent'],
          'referrer': data['referrer'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting page views for period: $e');
      return [];
    }
  }
  
  /// Delete old page views (cleanup function)
  Future<void> cleanupOldPageViews({int keepDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        debugPrint('Cleaned up ${snapshot.docs.length} old page views');
      }
    } catch (e) {
      debugPrint('Error cleaning up old page views: $e');
    }
  }
}