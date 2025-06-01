// lib/core/services/simple_page_view_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Simple service for tracking page views - just like YouTube views
class SimplePageViewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'pageViews';
  
  /// Track a page view when someone visits the review page
  /// This is as simple as possible - just count every visit
  Future<void> trackPageView({
    required String businessId,
    String source = 'direct',
    String? trackingId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📊 Tracking page view for business: $businessId');
      
      // Create a simple page view document
      final pageViewData = {
        'businessId': businessId,
        'timestamp': FieldValue.serverTimestamp(),
        'source': source, // 'qr', 'email', 'direct', 'link'
        'trackingId': trackingId,
        'completed': false, // Will be updated if they submit feedback
        'rating': null, // Will be updated if they submit feedback
        'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
        'metadata': metadata ?? {},
      };
      
      // Add to Firestore - each document is one page view
      await _firestore.collection(_collectionName).add(pageViewData);
      
      debugPrint('✅ Page view tracked successfully');
    } catch (e) {
      debugPrint('❌ Error tracking page view: $e');
      // Don't throw error - page view tracking shouldn't break the app
    }
  }
  
  /// Update page view when user completes feedback/review
  Future<void> markPageViewCompleted({
    required String businessId,
    String? trackingId,
    required double rating,
  }) async {
    try {
      // Find the most recent page view for this business
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
          'completed': true,
          'rating': rating,
          'completedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ Page view marked as completed');
      }
    } catch (e) {
      debugPrint('❌ Error updating page view completion: $e');
    }
  }
  
  /// Get simple statistics for dashboard
  Future<Map<String, dynamic>> getSimpleStats(String businessId) async {
    try {
      debugPrint('📊 Getting simple stats for business: $businessId');
      
      // Get all page views for this business
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final pageViews = snapshot.docs;
      final totalViews = pageViews.length;
      
      // Count completed views (people who left feedback)
      final completedViews = pageViews.where((doc) {
        final data = doc.data();
        return data['completed'] == true;
      }).toList();
      
      final totalCompleted = completedViews.length;
      
      // Count by source
      final Map<String, int> sourceBreakdown = {};
      for (final doc in pageViews) {
        final data = doc.data();
        final source = data['source'] as String? ?? 'unknown';
        sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + 1;
      }
      
      // Calculate conversion rate
      final conversionRate = totalViews > 0 ? totalCompleted / totalViews : 0.0;
      
      // Count QR scans specifically
      final qrScans = sourceBreakdown['qr'] ?? 0;
      
      debugPrint('📊 Stats calculated: $totalViews views, $totalCompleted completed, ${(conversionRate * 100).toStringAsFixed(1)}% conversion');
      
      return {
        'totalViews': totalViews,
        'completedViews': totalCompleted,
        'conversionRate': conversionRate,
        'qrScans': qrScans,
        'sourceBreakdown': sourceBreakdown,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('❌ Error getting simple stats: $e');
      return {
        'totalViews': 0,
        'completedViews': 0,
        'conversionRate': 0.0,
        'qrScans': 0,
        'sourceBreakdown': <String, int>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }
  
  /// Get recent page views for activity feed
  Future<List<Map<String, dynamic>>> getRecentPageViews({
    required String businessId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
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
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting recent page views: $e');
      return [];
    }
  }
}