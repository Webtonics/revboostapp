// lib/core/services/feedback_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;
  final EmailService _emailService;
  final String _collectionName = 'feedback';
  
  FeedbackService({
    required EmailService emailService,
    FirebaseFirestore? firestore,
  }) : _emailService = emailService,
       _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Submit new feedback
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
      // Create the feedback document
      final feedbackData = {
        'businessId': businessId,
        'rating': rating,
        'feedback': feedback,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'customerName': customerName,
        'customerEmail': customerEmail,
        'metadata': metadata ?? {
          'source': 'app',
          'submittedAt': DateTime.now().toIso8601String(),
        },
      };
      
      // Add to Firestore
      final docRef = await _firestore.collection(_collectionName).add(feedbackData);
      
      // Update business statistics
      await _updateBusinessFeedbackStats(businessId, rating);
      
      // Send notification for negative feedback
      if (rating <= 3 && businessEmail != null && businessName != null) {
        await _emailService.sendFeedbackNotification(
          businessId: businessId,
          toEmail: businessEmail,
          businessName: businessName,
          rating: rating,
          feedback: feedback,
          customerName: customerName ?? 'Anonymous Customer',
        );
      }
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }
  
  // Get all feedback for a business
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
  
  // Get a specific feedback by ID
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
  
  // Update feedback status (e.g., mark as reviewed or block)
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
  
  // Get feedback statistics for a business
  Future<Map<String, dynamic>> getFeedbackStatistics(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final feedbacks = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
      
      // Calculate statistics
      int total = feedbacks.length;
      double averageRating = 0;
      Map<double, int> ratingCounts = {};
      int negativeCount = 0;
      int blockedCount = 0;
      
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
        }
        
        averageRating = sum / total;
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
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting feedback statistics: $e');
      return {};
    }
  }
  
  // Update business feedback statistics
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

  Future<List<FeedbackModel>> getFeedbackForBusinessOnce(String businessId) async {
  final snapshot = await _firestore
      .collection(_collectionName)  // Use 'feedback' (singular) instead of 'feedbacks'
      .where('businessId', isEqualTo: businessId)
      .get();

  return snapshot.docs.map((doc) {
    return FeedbackModel.fromFirestore(doc);  // Pass the DocumentSnapshot directly
  }).toList();
}
}