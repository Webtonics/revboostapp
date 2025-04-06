// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;
  
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.subscriptionStatus,
    this.subscriptionEndDate,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      subscriptionStatus: data['subscriptionStatus'],
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? (data['subscriptionEndDate'] as Timestamp).toDate()
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
    };
  }
  
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    bool? isActive,
    String? subscriptionStatus,
    DateTime? subscriptionEndDate,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }
}