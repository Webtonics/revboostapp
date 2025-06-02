// lib/core/services/complete_review_request_service.dart
// Complete service with CSV import and batch sending

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/simple_rate_limiting_service.dart';
import 'package:revboostapp/models/review_request_model.dart';
import 'package:uuid/uuid.dart';

class CompleteReviewRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService;
  final SimpleRateLimitingService _rateLimitService = SimpleRateLimitingService();
  final String _collectionName = 'reviewRequests';
  final Uuid _uuid = const Uuid();
  
  CompleteReviewRequestService({
    required EmailService emailService,
    FirebaseFirestore? firestore,
  }) : _emailService = emailService;
  
  /// Check if user has access to premium features
  bool _hasPremiumAccess(String planType) {
    return ['pro', 'monthly', 'yearly'].contains(planType.toLowerCase());
  }
  
  /// Create and send single review request
  Future<String> createAndSendReviewRequest({
    required String userId,
    required String businessId,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required String businessName,
    required String reviewLink,
    required String planType,
    String? replyToEmail,
    Map<String, dynamic>? metadata,
  }) async {
    // Check rate limit first
    await _rateLimitService.checkAndUpdateUsage(
      userId: userId,
      planType: planType,
      requestCount: 1,
    );
    
    try {
      // Create tracking ID
      final trackingId = _uuid.v4();
      
      // Add tracking to review link
      final uri = Uri.parse(reviewLink);
      final updatedLink = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'tracking_id': trackingId,
        'source': 'email',
      }).toString();
      
      // Create review request document
      final reviewRequest = {
        'userId': userId,
        'businessId': businessId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reviewLink': updatedLink,
        'trackingId': trackingId,
        'planType': planType,
        'metadata': {
          'source': 'single_request',
          'trackingId': trackingId,
          ...metadata ?? {},
        },
      };
      
      // Add to Firestore
      final docRef = await _firestore.collection(_collectionName).add(reviewRequest);
      
      try {
        // Send email
        final success = await _emailService.sendReviewRequest(
          toEmail: customerEmail,
          customerName: customerName,
          businessName: businessName,
          reviewLink: updatedLink,
          replyTo: replyToEmail,
          customData: {
            'requestId': docRef.id,
            'trackingId': trackingId,
          },
        );
        
        if (success) {
          // Update status to sent
          await _firestore.collection(_collectionName).doc(docRef.id).update({
            'status': 'sent',
            'sentAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('Review request sent successfully: ${docRef.id}');
          return docRef.id;
        } else {
          // Mark as failed and rollback usage
          await _firestore.collection(_collectionName).doc(docRef.id).update({
            'status': 'failed',
            'metadata.error': 'Email service failed',
          });
          
          await _rateLimitService.rollbackUsage(userId: userId, requestCount: 1);
          throw Exception('Email service failed to send the request');
        }
      } catch (e) {
        // Mark as failed and rollback usage
        await _firestore.collection(_collectionName).doc(docRef.id).update({
          'status': 'failed',
          'metadata.error': e.toString(),
        });
        
        await _rateLimitService.rollbackUsage(userId: userId, requestCount: 1);
        rethrow;
      }
    } catch (e) {
      debugPrint('Error creating review request: $e');
      rethrow;
    }
  }
  
  /// Import contacts from CSV (Premium feature) - FIXED VERSION
  Future<Map<String, dynamic>> importContactsFromCsv({
    required String userId,
    required String businessId,
    required String businessName,
    required String planType,
    required List<Map<String, String>> contacts,
    required String reviewLink,
    bool sendImmediately = false,
  }) async {
    try {
      // Check if user has premium access
      if (!_hasPremiumAccess(planType)) {
        throw Exception('CSV import is only available for premium users. Please upgrade your plan.');
      }
      
      final validContacts = <Map<String, String>>[];
      final errors = <String>[];
      
      // Validate contacts
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        final name = contact['name']?.trim();
        final email = contact['email']?.trim();
        
        if (name == null || name.isEmpty) {
          errors.add('Row ${i + 1}: Missing name');
          continue;
        }
        
        if (email == null || email.isEmpty) {
          errors.add('Row ${i + 1}: Missing email');
          continue;
        }
        
        // Basic email validation
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
          errors.add('Row ${i + 1}: Invalid email format');
          continue;
        }
        
        validContacts.add({
          'name': name,
          'email': email,
          'phone': contact['phone']?.trim() ?? '',
        });
      }
      
      if (validContacts.isEmpty) {
        return {
          'successful': 0,
          'failed': contacts.length,
          'errors': errors.isEmpty ? ['No valid contacts found'] : errors,
        };
      }
      
      // Check rate limit for all valid contacts
      await _rateLimitService.checkAndUpdateUsage(
        userId: userId,
        planType: planType,
        requestCount: validContacts.length,
      );
      
      int successful = 0;
      int failed = 0;
      final createdRequestIds = <String>[];
      
      // Create review requests in batches
      for (int i = 0; i < validContacts.length; i += 20) {
        final batch = _firestore.batch();
        final end = (i + 20 < validContacts.length) ? i + 20 : validContacts.length;
        final currentBatch = validContacts.sublist(i, end);
        
        for (final contact in currentBatch) {
          try {
            final trackingId = _uuid.v4();
            
            // Add tracking to review link
            final uri = Uri.parse(reviewLink);
            final updatedLink = uri.replace(queryParameters: {
              ...uri.queryParameters,
              'tracking_id': trackingId,
              'source': 'csv_import',
            }).toString();
            
            final requestDoc = _firestore.collection(_collectionName).doc();
            
            final reviewRequest = {
              'userId': userId,
              'businessId': businessId,
              'customerName': contact['name']!,
              'customerEmail': contact['email']!,
              'customerPhone': contact['phone']!.isEmpty ? null : contact['phone'],
              'createdAt': FieldValue.serverTimestamp(),
              'status': sendImmediately ? 'pending' : 'draft',
              'reviewLink': updatedLink,
              'trackingId': trackingId,
              'planType': planType,
              'metadata': {
                'source': 'csv_import',
                'trackingId': trackingId,
                'importBatch': DateTime.now().toIso8601String(),
                'sendImmediately': sendImmediately,
              },
            };
            
            batch.set(requestDoc, reviewRequest);
            successful++;
            
            if (sendImmediately) {
              createdRequestIds.add(requestDoc.id);
            }
          } catch (e) {
            failed++;
            errors.add('Error processing ${contact['name']}: $e');
          }
        }
        
        // Commit batch
        await batch.commit();
      }
      
      // If sending immediately, send emails for created requests
      if (sendImmediately && createdRequestIds.isNotEmpty) {
        try {
          await _sendCreatedRequests(
            requestIds: createdRequestIds,
            businessName: businessName,
          );
        } catch (e) {
          debugPrint('Error sending emails after import: $e');
          // Don't fail the entire import, just log the error
          errors.add('Import successful but some emails failed to send: $e');
        }
      }
      
      return {
        'successful': successful,
        'failed': failed,
        'errors': errors,
        'sendImmediately': sendImmediately,
      };
    } catch (e) {
      debugPrint('Error in importContactsFromCsv: $e');
      
      // Return proper error response
      return {
        'successful': 0,
        'failed': contacts.length,
        'errors': ['Import failed: ${e.toString()}'],
      };
    }
  }
  
  /// Send specific created requests (helper method)
  Future<void> _sendCreatedRequests({
    required List<String> requestIds,
    required String businessName,
  }) async {
    for (final requestId in requestIds) {
      try {
        final doc = await _firestore.collection(_collectionName).doc(requestId).get();
        
        if (!doc.exists) {
          debugPrint('Request $requestId not found');
          continue;
        }
        
        final data = doc.data() as Map<String, dynamic>;
        
        final success = await _emailService.sendReviewRequest(
          toEmail: data['customerEmail'],
          customerName: data['customerName'],
          businessName: businessName,
          reviewLink: data['reviewLink'],
          customData: {
            'requestId': requestId,
            'trackingId': data['trackingId'],
            'source': 'csv_import',
          },
        );
        
        if (success) {
          await _firestore.collection(_collectionName).doc(requestId).update({
            'status': 'sent',
            'sentAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore.collection(_collectionName).doc(requestId).update({
            'status': 'failed',
            'metadata.sendError': 'Email service failed',
          });
        }
        
        // Small delay to avoid overwhelming email service
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Error sending request $requestId: $e');
        try {
          await _firestore.collection(_collectionName).doc(requestId).update({
            'status': 'failed',
            'metadata.sendError': e.toString(),
          });
        } catch (updateError) {
          debugPrint('Failed to update request status: $updateError');
        }
      }
    }
  }
  /// Batch send existing requests (Premium feature)
  Future<Map<String, dynamic>> batchSendRequests({
    required String userId,
    required String businessName,
    required String planType,
    required List<String> requestIds,
  }) async {
    // Check if user has premium access
    if (!_hasPremiumAccess(planType)) {
      throw Exception('Batch sending is only available for premium users. Please upgrade your plan.');
    }
    
    int successful = 0;
    int failed = 0;
    final errors = <String>[];
    
    // Process in chunks to avoid overwhelming the email service
    for (int i = 0; i < requestIds.length; i += 5) {
      final end = (i + 5 < requestIds.length) ? i + 5 : requestIds.length;
      final chunk = requestIds.sublist(i, end);
      
      for (final requestId in chunk) {
        try {
          final doc = await _firestore.collection(_collectionName).doc(requestId).get();
          
          if (!doc.exists) {
            failed++;
            errors.add('Request $requestId not found');
            continue;
          }
          
          final data = doc.data() as Map<String, dynamic>;
          
          // Only send if status is pending or failed
          if (data['status'] != 'pending' && data['status'] != 'failed') {
            failed++;
            errors.add('Request $requestId has already been sent');
            continue;
          }
          
          // Send email
          final success = await _emailService.sendReviewRequest(
            toEmail: data['customerEmail'],
            customerName: data['customerName'],
            businessName: businessName,
            reviewLink: data['reviewLink'],
            customData: {
              'requestId': requestId,
              'trackingId': data['trackingId'],
              'batchSend': true,
            },
          );
          
          if (success) {
            await _firestore.collection(_collectionName).doc(requestId).update({
              'status': 'sent',
              'sentAt': FieldValue.serverTimestamp(),
              'metadata.batchSent': true,
            });
            successful++;
          } else {
            await _firestore.collection(_collectionName).doc(requestId).update({
              'status': 'failed',
              'metadata.batchSendError': 'Email service failed',
            });
            failed++;
            errors.add('Failed to send email for request $requestId');
          }
        } catch (e) {
          failed++;
          errors.add('Error processing request $requestId: $e');
        }
      }
      
      // Small delay between chunks
      if (i + 5 < requestIds.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return {
      'successful': successful,
      'failed': failed,
      'errors': errors,
    };
  }
  
  /// Get user's current usage stats
  Future<Map<String, dynamic>> getUserUsageStats(String userId, String planType) async {
    return await _rateLimitService.getUserUsage(userId, planType);
  }
  
  /// Get review requests for business
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
  
  /// Delete review request
  Future<void> deleteReviewRequest(String requestId) async {
    await _firestore.collection(_collectionName).doc(requestId).delete();
  }
}