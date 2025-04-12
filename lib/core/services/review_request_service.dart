// lib/features/review_requests/services/review_request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/models/review_request_model.dart';
import 'package:uuid/uuid.dart';

/// Service for managing review requests
class ReviewRequestService {
  final FirebaseFirestore _firestore;
  final EmailService _emailService;
  final String _collectionName = 'reviewRequests';
  final Uuid _uuid = const Uuid();
  
  /// Creates a [ReviewRequestService] instance
  ReviewRequestService({
    required EmailService emailService,
    FirebaseFirestore? firestore,
  }) : _emailService = emailService,
       _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Creates a new review request
  /// 
  /// Returns the ID of the created request
  Future<String> createReviewRequest({
    required String businessId,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required String reviewLink,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create a tracking ID for the request
      final trackingId = _uuid.v4();
      
      // Add tracking parameter to review link
      final uri = Uri.parse(reviewLink);
      final updatedLink = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'tracking_id': trackingId,
      }).toString();
      
      // Create the request object
      final reviewRequest = {
        'businessId': businessId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reviewLink': updatedLink,
        'trackingId': trackingId,
        'metadata': metadata,
      };
      
      // Add to Firestore
      final docRef = await _firestore.collection(_collectionName).add(reviewRequest);
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating review request: $e');
      throw Exception('Failed to create review request: $e');
    }
  }
  
  /// Sends a review request email
  /// 
  /// Returns `true` if the email was sent successfully
  Future<bool> sendReviewRequestEmail({
    required String requestId,
    required String customerName,
    required String customerEmail,
    required String businessName,
    required String reviewLink,
    String? replyToEmail,
  }) async {
    try {
      // Send the email
      final success = await _emailService.sendReviewRequest(
        toEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        reviewLink: reviewLink,
        replyTo: replyToEmail,
        customData: {
          'requestId': requestId,
        },
      );
      
      if (success) {
        // Update the request status
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'sent',
          'sentAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      } else {
        // Mark as failed
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'failed',
        });
        
        return false;
      }
    } catch (e) {
      debugPrint('Error sending review request email: $e');
      
      // Try to mark as failed
      try {
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'failed',
        });
      } catch (_) {
        // Ignore errors when updating status
      }
      
      return false;
    }
  }
  
  /// Gets a stream of review requests for a business
  Stream<List<ReviewRequestModel>> getReviewRequestsForBusiness(String businessId) {
    return _firestore
        .collection(_collectionName)
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReviewRequestModel.fromFirestore(doc))
              .toList();
        });
  }
  
  /// Gets a review request by ID
  Future<ReviewRequestModel?> getReviewRequestById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (doc.exists) {
        return ReviewRequestModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting review request: $e');
      return null;
    }
  }
  
  /// Gets a review request by tracking ID
  Future<ReviewRequestModel?> getReviewRequestByTrackingId(String trackingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('trackingId', isEqualTo: trackingId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return ReviewRequestModel.fromFirestore(snapshot.docs.first);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting review request by tracking ID: $e');
      return null;
    }
  }
  
  /// Updates a review request when clicked
  Future<void> trackRequestClick(String requestId) async {
    try {
      await _firestore.collection(_collectionName).doc(requestId).update({
        'status': 'clicked',
        'clickedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking request click: $e');
      throw Exception('Failed to track request click: $e');
    }
  }
  
  /// Updates a review request when completed
  Future<void> completeRequest({
    required String requestId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(requestId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'rating': rating,
        'feedback': feedback,
      });
    } catch (e) {
      debugPrint('Error completing request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }
  
  /// Deletes a review request
  Future<void> deleteReviewRequest(String requestId) async {
    try {
      await _firestore.collection(_collectionName).doc(requestId).delete();
    } catch (e) {
      debugPrint('Error deleting review request: $e');
      throw Exception('Failed to delete review request: $e');
    }
  }
  
  /// Resends a review request
  Future<bool> resendReviewRequest({
    required String requestId,
    required String businessName,
  }) async {
    try {
      // Get the request
      final doc = await _firestore.collection(_collectionName).doc(requestId).get();
      
      if (!doc.exists) {
        throw Exception('Review request not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Send the email
      final success = await _emailService.sendReviewRequest(
        toEmail: data['customerEmail'],
        customerName: data['customerName'],
        businessName: businessName,
        reviewLink: data['reviewLink'],
        customData: {
          'requestId': requestId,
          'isResend': true,
        },
      );
      
      if (success) {
        // Update the request status
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'sent',
          'sentAt': FieldValue.serverTimestamp(),
          'metadata.resendCount': FieldValue.increment(1),
          'metadata.lastResendAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error resending review request: $e');
      return false;
    }
  }
  
  /// Gets statistics for review requests
  Future<Map<String, dynamic>> getReviewRequestStatistics(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final requests = snapshot.docs
          .map((doc) => ReviewRequestModel.fromFirestore(doc))
          .toList();
      
      // Calculate statistics
      int total = requests.length;
      int pending = requests.where((req) => req.status == ReviewRequestStatus.pending).length;
      int sent = requests.where((req) => req.status == ReviewRequestStatus.sent).length;
      int clicked = requests.where((req) => req.status == ReviewRequestStatus.clicked).length;
      int completed = requests.where((req) => req.status == ReviewRequestStatus.completed).length;
      int failed = requests.where((req) => req.status == ReviewRequestStatus.failed).length;
      
      // Reviews by rating
      Map<int, int> reviewsByRating = {};
      for (int i = 1; i <= 5; i++) {
        reviewsByRating[i] = requests.where((req) => req.rating == i).length;
      }
      
      // Calculate rates
      double clickRate = sent > 0 ? (clicked + completed) / sent : 0;
      double completionRate = sent > 0 ? completed / sent : 0;
      double positiveRate = completed > 0 
          ? requests.where((req) => (req.rating ?? 0) >= 4).length / completed 
          : 0;
      
      // Time-based metrics (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRequests = requests.where(
        (req) => req.createdAt.isAfter(thirtyDaysAgo)
      ).toList();
      
      int recentTotal = recentRequests.length;
      int recentCompleted = recentRequests.where(
        (req) => req.status == ReviewRequestStatus.completed
      ).length;
      
      return {
        'total': total,
        'pending': pending,
        'sent': sent,
        'clicked': clicked,
        'completed': completed,
        'failed': failed,
        'reviewsByRating': reviewsByRating,
        'clickRate': clickRate,
        'completionRate': completionRate,
        'positiveRate': positiveRate,
        'recent': {
          'total': recentTotal,
          'completed': recentCompleted,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting review request statistics: $e');
      return {};
    }
  }
  
  /// Imports review requests from a CSV
  Future<Map<String, dynamic>> importReviewRequestsFromCsv({
    required String businessId,
    required List<Map<String, dynamic>> contacts,
    required String businessName,
    required String reviewLink,
    bool sendImmediately = false,
  }) async {
    int successful = 0;
    int failed = 0;
    List<String> errors = [];
    
    try {
      // Process in batches for better performance
      for (int i = 0; i < contacts.length; i += 20) {
        final batch = _firestore.batch();
        final end = (i + 20 < contacts.length) ? i + 20 : contacts.length;
        final currentBatch = contacts.sublist(i, end);
        
        for (final contact in currentBatch) {
          try {
            // Validate required fields
            final name = contact['name'] as String?;
            final email = contact['email'] as String?;
            
            if (name == null || name.isEmpty || email == null || email.isEmpty) {
              failed++;
              errors.add('Missing name or email for contact');
              continue;
            }
            
            // Create a tracking ID
            final trackingId = _uuid.v4();
            
            // Add tracking parameter to review link
            final uri = Uri.parse(reviewLink);
            final updatedLink = uri.replace(queryParameters: {
              ...uri.queryParameters,
              'tracking_id': trackingId,
            }).toString();
            
            // Create the request object
            final requestDoc = _firestore.collection(_collectionName).doc();
            
            final reviewRequest = {
              'businessId': businessId,
              'customerName': name,
              'customerEmail': email,
              'customerPhone': contact['phone'],
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'pending',
              'reviewLink': updatedLink,
              'trackingId': trackingId,
              'metadata': {
                'importBatch': DateTime.now().toIso8601String(),
                'source': 'csv_import',
              },
            };
            
            batch.set(requestDoc, reviewRequest);
            successful++;
            
          } catch (e) {
            failed++;
            errors.add(e.toString());
          }
        }
        
        // Commit the batch
        await batch.commit();
      }
      
      return {
        'successful': successful,
        'failed': failed,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('Error importing review requests: $e');
      return {
        'successful': successful,
        'failed': failed,
        'errors': [e.toString()],
      };
    }
  }
  
  /// Bulk send review requests
  Future<Map<String, dynamic>> bulkSendReviewRequests({
    required String businessId,
    required String businessName,
    required List<String> requestIds,
  }) async {
    int successful = 0;
    int failed = 0;
    List<String> errors = [];
    
    try {
      for (final requestId in requestIds) {
        try {
          final doc = await _firestore.collection(_collectionName).doc(requestId).get();
          
          if (!doc.exists) {
            failed++;
            errors.add('Request $requestId not found');
            continue;
          }
          
          final data = doc.data() as Map<String, dynamic>;
          
          // Send the email
          final success = await _emailService.sendReviewRequest(
            toEmail: data['customerEmail'],
            customerName: data['customerName'],
            businessName: businessName,
            reviewLink: data['reviewLink'],
          );
          
          if (success) {
            // Update the request status
            await _firestore.collection(_collectionName).doc(requestId).update({
              'status': 'sent',
              'sentAt': FieldValue.serverTimestamp(),
            });
            
            successful++;
          } else {
            // Mark as failed
            await _firestore.collection(_collectionName).doc(requestId).update({
              'status': 'failed',
            });
            
            failed++;
            errors.add('Failed to send email for request $requestId');
          }
        } catch (e) {
          failed++;
          errors.add('Error processing request $requestId: $e');
        }
      }
      
      return {
        'successful': successful,
        'failed': failed,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('Error in bulk send: $e');
      return {
        'successful': successful,
        'failed': failed,
        'errors': [e.toString()],
      };
    }
  }
}