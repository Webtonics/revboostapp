// lib/models/review_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a review request
enum ReviewRequestStatus {
  pending,   // Created but not sent
  sent,      // Email was sent
  clicked,   // Link was clicked
  completed, // Review was completed
  failed     // Failed to send
}

/// Model representing a review request
class ReviewRequestModel {
  final String id;
  final String businessId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? clickedAt;
  final DateTime? completedAt;
  final ReviewRequestStatus status;
  final String reviewLink;
  final int? rating;
  final String? feedback;
  final Map<String, dynamic>? metadata;
  
  const ReviewRequestModel({
    required this.id,
    required this.businessId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.createdAt,
    this.sentAt,
    this.clickedAt,
    this.completedAt,
    required this.status,
    required this.reviewLink,
    this.rating,
    this.feedback,
    this.metadata,
  });
  
  /// Creates a [ReviewRequestModel] from a Firestore document
  // factory ReviewRequestModel.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
    
  //   return ReviewRequestModel(
  //     id: doc.id,
  //     businessId: data['businessId'] ?? '',
  //     customerName: data['customerName'] ?? '',
  //     customerEmail: data['customerEmail'] ?? '',
  //     customerPhone: data['customerPhone'],
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //     sentAt: data['sentAt'] != null ? (data['sentAt'] as Timestamp).toDate() : null,
  //     clickedAt: data['clickedAt'] != null ? (data['clickedAt'] as Timestamp).toDate() : null,
  //     completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
  //     status: _statusFromString(data['status'] ?? 'pending'),
  //     reviewLink: data['reviewLink'] ?? '',
  //     rating: data['rating'],
  //     feedback: data['feedback'],
  //     metadata: data['metadata'],
  //   );
  // }
  factory ReviewRequestModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  return ReviewRequestModel(
    id: doc.id,
    businessId: data['businessId'] ?? '',
    customerName: data['customerName'] ?? '',
    customerEmail: data['customerEmail'] ?? '',
    customerPhone: data['customerPhone'],
    createdAt: data['createdAt'] != null 
        ? (data['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),  // Provide a default value
    sentAt: data['sentAt'] != null 
        ? (data['sentAt'] as Timestamp).toDate() 
        : null,
    clickedAt: data['clickedAt'] != null 
        ? (data['clickedAt'] as Timestamp).toDate() 
        : null,
    completedAt: data['completedAt'] != null 
        ? (data['completedAt'] as Timestamp).toDate() 
        : null,
    status: _statusFromString(data['status'] ?? 'pending'),
    reviewLink: data['reviewLink'] ?? '',
    rating: data['rating'],
    feedback: data['feedback'],
  );
}
  
  /// Converts this [ReviewRequestModel] to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'clickedAt': clickedAt != null ? Timestamp.fromDate(clickedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': _statusToString(status),
      'reviewLink': reviewLink,
      'rating': rating,
      'feedback': feedback,
      'metadata': metadata,
    };
  }
  
  /// Creates a copy of this [ReviewRequestModel] with updated values
  ReviewRequestModel copyWith({
    String? id,
    String? businessId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? clickedAt,
    DateTime? completedAt,
    ReviewRequestStatus? status,
    String? reviewLink,
    int? rating,
    String? feedback,
    Map<String, dynamic>? metadata,
  }) {
    return ReviewRequestModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      clickedAt: clickedAt ?? this.clickedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      reviewLink: reviewLink ?? this.reviewLink,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Converts a string status to [ReviewRequestStatus]
  static ReviewRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return ReviewRequestStatus.pending;
      case 'sent':
        return ReviewRequestStatus.sent;
      case 'clicked':
        return ReviewRequestStatus.clicked;
      case 'completed':
        return ReviewRequestStatus.completed;
      case 'failed':
        return ReviewRequestStatus.failed;
      default:
        return ReviewRequestStatus.pending;
    }
  }
  
  /// Converts [ReviewRequestStatus] to a string
  static String _statusToString(ReviewRequestStatus status) {
    switch (status) {
      case ReviewRequestStatus.pending:
        return 'pending';
      case ReviewRequestStatus.sent:
        return 'sent';
      case ReviewRequestStatus.clicked:
        return 'clicked';
      case ReviewRequestStatus.completed:
        return 'completed';
      case ReviewRequestStatus.failed:
        return 'failed';
    }
  }
  
  /// Returns whether this review request is considered active
  bool get isActive => status != ReviewRequestStatus.completed && status != ReviewRequestStatus.failed;
  
  /// Returns whether the review request has been completed
  bool get isCompleted => status == ReviewRequestStatus.completed;
  
  /// Returns whether the review was positive (4 or 5 stars)
  bool get isPositive => (rating ?? 0) >= 4;
  
  /// Returns a human-readable status text
  String get statusText {
    switch (status) {
      case ReviewRequestStatus.pending:
        return 'Pending';
      case ReviewRequestStatus.sent:
        return 'Sent';
      case ReviewRequestStatus.clicked:
        return 'Viewed';
      case ReviewRequestStatus.completed:
        return 'Completed';
      case ReviewRequestStatus.failed:
        return 'Failed';
    }
  }
  
  /// Returns a color associated with the status
  /// Note: Returns the color name as a string - should be converted in the UI
  String get statusColor {
    switch (status) {
      case ReviewRequestStatus.pending:
        return 'gray';
      case ReviewRequestStatus.sent:
        return 'blue';
      case ReviewRequestStatus.clicked:
        return 'purple';
      case ReviewRequestStatus.completed:
        return 'green';
      case ReviewRequestStatus.failed:
        return 'red';
    }
  }


}

class BatchOperationResult {
  final int success;
  final int failure;
  final List<String> errors;
  
  BatchOperationResult({
    required this.success, 
    required this.failure,
    this.errors = const [],
  });
}

