// lib/models/feedback_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackStatus {
  submitted,
  reviewed,
  resolved,
  blocked
}

class FeedbackModel {
  final String id;
  final String businessId;
  final double rating;
  final String feedback;
  final DateTime createdAt;
  final FeedbackStatus status;
  final Map<String, dynamic>? metadata;
  final String? customerName;
  final String? customerEmail;

  FeedbackModel({
    required this.id,
    required this.businessId,
    required this.rating,
    required this.feedback,
    required this.createdAt,
    this.status = FeedbackStatus.submitted,
    this.metadata,
    this.customerName,
    this.customerEmail,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      feedback: data['feedback'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      status: _parseStatus(data['status']),
      metadata: data['metadata'],
      customerName: data['customerName'],
      customerEmail: data['customerEmail'],
    );
  }

  static FeedbackStatus _parseStatus(String? status) {
    if (status == null) return FeedbackStatus.submitted;
    
    switch (status) {
      case 'reviewed': return FeedbackStatus.reviewed;
      case 'resolved': return FeedbackStatus.resolved;
      case 'blocked': return FeedbackStatus.blocked;
      default: return FeedbackStatus.submitted;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt,
      'status': status.toString().split('.').last,
      'metadata': metadata ?? {},
      'customerName': customerName,
      'customerEmail': customerEmail,
    };
  }
}