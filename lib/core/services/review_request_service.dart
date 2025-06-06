// lib/core/services/review_request_service.dart - Updated with Page View Tracking

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/models/review_request_model.dart';
import 'package:uuid/uuid.dart';

/// Service for managing review requests with enhanced tracking
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
  
  /// Access to the email service (for provider access)
  EmailService get emailService => _emailService;
  
  /// Creates a new review request with enhanced tracking
  Future<String> createReviewRequest({
    required String businessId,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required String reviewLink,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('Creating new review request for $customerEmail');
      
      // Create a unique tracking ID for this request
      final trackingId = _uuid.v4();
      
      // Add tracking parameters to review link
      final uri = Uri.parse(reviewLink);
      final updatedLink = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'tracking_id': trackingId,
        'source': 'email', // Mark this as coming from email
      }).toString();
      
      debugPrint('Generated tracking ID: $trackingId');
      debugPrint('Review link with tracking: $updatedLink');
      
      // Create the request object
      final reviewRequest = {
        'businessId': businessId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reviewLink': updatedLink,
        'trackingId': trackingId, // Store tracking ID in the request
        'metadata': {
          'source': 'email',
          'trackingId': trackingId,
          ...metadata ?? {},
        },
      };
      
      // Add to Firestore
      final docRef = await _firestore.collection(_collectionName).add(reviewRequest);
      
      debugPrint('Review request created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating review request: $e');
      throw Exception('Failed to create review request: $e');
    }
  }
  
  /// Sends a review request email with tracking
  Future<bool> sendReviewRequestEmail({
    required String requestId,
    required String customerName,
    required String customerEmail,
    required String businessName,
    required String reviewLink,
    String? replyToEmail,
  }) async {
    try {
      debugPrint('Sending review request email for ID: $requestId');
      
      // Send the email with the tracking-enabled link
      final success = await _emailService.sendReviewRequest(
        toEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        reviewLink: reviewLink, // This already contains tracking parameters
        replyTo: replyToEmail,
        customData: {
          'requestId': requestId,
          'trackingEnabled': true,
        },
      );
      
      debugPrint('Email sending result: $success');
      
      if (success) {
        // Update the request status
        debugPrint('Updating request status to "sent"');
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'sent',
          'sentAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      } else {
        // Mark as failed
        debugPrint('Email failed to send, updating request status to "failed"');
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'failed',
          'metadata.error': 'Email service reported failure',
        });
        
        return false;
      }
    } catch (e) {
      debugPrint('Exception in sendReviewRequestEmail: $e');
      
      // Try to mark as failed
      try {
        await _firestore.collection(_collectionName).doc(requestId).update({
          'status': 'failed',
          'metadata.error': e.toString(),
        });
      } catch (updateError) {
        debugPrint('Failed to update request status: $updateError');
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
  
  /// Gets a review request by tracking ID (useful for connecting page views to requests)
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
  
  /// Updates a review request when the link is clicked (tracked via page views)
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
  
  /// Updates a review request when completed (called from page view tracking)
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
  
  /// Updates review request status based on tracking ID (for page view integration)
  Future<void> updateRequestByTrackingId({
    required String trackingId,
    required String status,
    int? rating,
    String? feedback,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('trackingId', isEqualTo: trackingId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        final updateData = <String, dynamic>{
          'status': status,
        };
        
        if (status == 'clicked') {
          updateData['clickedAt'] = FieldValue.serverTimestamp();
        } else if (status == 'completed') {
          updateData['completedAt'] = FieldValue.serverTimestamp();
          if (rating != null) updateData['rating'] = rating;
          if (feedback != null) updateData['feedback'] = feedback;
        }
        
        await _firestore.collection(_collectionName).doc(docId).update(updateData);
        debugPrint('Updated review request status via tracking ID: $trackingId -> $status');
      } else {
        debugPrint('No review request found with tracking ID: $trackingId');
      }
    } catch (e) {
      debugPrint('Error updating request by tracking ID: $e');
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
      
      // Send the email (link already has tracking parameters)
      final success = await _emailService.sendReviewRequest(
        toEmail: data['customerEmail'],
        customerName: data['customerName'],
        businessName: businessName,
        reviewLink: data['reviewLink'], // Already has tracking
        customData: {
          'requestId': requestId,
          'isResend': true,
          'trackingId': data['trackingId'],
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
  
  /// Gets statistics for review requests with enhanced tracking data
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
      
      // Average response time calculation
      double averageResponseHours = 0;
      final completedWithTimes = requests
          .where((req) => req.status == ReviewRequestStatus.completed && 
                        req.sentAt != null && 
                        req.completedAt != null)
          .toList();
      
      if (completedWithTimes.isNotEmpty) {
        final totalHours = completedWithTimes
            .map((req) => req.completedAt!.difference(req.sentAt!).inHours)
            .fold(0, (sum, hours) => sum + hours);
        averageResponseHours = totalHours / completedWithTimes.length;
      }
      
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
        'averageResponseHours': averageResponseHours,
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
  
  /// Import review requests from CSV with tracking
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
            
            // Create a tracking ID for this import
            final trackingId = _uuid.v4();
            
            // Add tracking parameters to review link
            final uri = Uri.parse(reviewLink);
            final updatedLink = uri.replace(queryParameters: {
              ...uri.queryParameters,
              'tracking_id': trackingId,
              'source': 'csv_import',
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
                'trackingId': trackingId,
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
  
  /// Bulk send review requests with tracking
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
          
          // Send the email (tracking already embedded in link)
          final success = await _emailService.sendReviewRequest(
            toEmail: data['customerEmail'],
            customerName: data['customerName'],
            businessName: businessName,
            reviewLink: data['reviewLink'], // Contains tracking
            customData: {
              'requestId': requestId,
              'trackingId': data['trackingId'],
              'bulkSend': true,
            },
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