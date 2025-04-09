// // Modify lib/models/user_model.dart to add business setup fields

// import 'package:cloud_firestore/cloud_firestore.dart';

// class UserModel {
//   final String id;
//   final String email;
//   final String? displayName;
//   final String? photoUrl;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final bool isActive;
//   final String? subscriptionStatus;
//   final DateTime? subscriptionEndDate;
//   final bool hasCompletedSetup;  // Added field
//   final List<String> businessIds;  // Added field
  
//   const UserModel({
//     required this.id,
//     required this.email,
//     this.displayName,
//     this.photoUrl,
//     required this.createdAt,
//     required this.updatedAt,
//     this.isActive = true,
//     this.subscriptionStatus,
//     this.subscriptionEndDate,
//     this.hasCompletedSetup = false,  // Default to false
//     this.businessIds = const [],  // Default to empty list
//   });
  
//   factory UserModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
    
//     return UserModel(
//       id: doc.id,
//       email: data['email'] ?? '',
//       displayName: data['displayName'],
//       photoUrl: data['photoUrl'],
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       updatedAt: (data['updatedAt'] as Timestamp).toDate(),
//       isActive: data['isActive'] ?? true,
//       subscriptionStatus: data['subscriptionStatus'],
//       subscriptionEndDate: data['subscriptionEndDate'] != null
//           ? (data['subscriptionEndDate'] as Timestamp).toDate()
//           : null,
//       hasCompletedSetup: data['hasCompletedSetup'] ?? false,
//       businessIds: List<String>.from(data['businessIds'] ?? []),
//     );
//   }
  
//   Map<String, dynamic> toFirestore() {
//     return {
//       'email': email,
//       'displayName': displayName,
//       'photoUrl': photoUrl,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': Timestamp.fromDate(updatedAt),
//       'isActive': isActive,
//       'subscriptionStatus': subscriptionStatus,
//       'subscriptionEndDate': subscriptionEndDate != null
//           ? Timestamp.fromDate(subscriptionEndDate!)
//           : null,
//       'hasCompletedSetup': hasCompletedSetup,
//       'businessIds': businessIds,
//     };
//   }
  
//   UserModel copyWith({
//     String? displayName,
//     String? photoUrl,
//     bool? isActive,
//     String? subscriptionStatus,
//     DateTime? subscriptionEndDate,
//     DateTime? updatedAt,
//     bool? hasCompletedSetup,
//     List<String>? businessIds,
//   }) {
//     return UserModel(
//       id: id,
//       email: email,
//       displayName: displayName ?? this.displayName,
//       photoUrl: photoUrl ?? this.photoUrl,
//       createdAt: createdAt,
//       updatedAt: updatedAt ?? DateTime.now(),
//       isActive: isActive ?? this.isActive,
//       subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
//       subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
//       hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
//       businessIds: businessIds ?? this.businessIds,
//     );
//   }
// }
// lib/models/user_model.dart (update)

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
  final bool hasCompletedSetup;
  final List<String> businessIds;
  final String? phoneNumber;
  final Map<String, dynamic>? notificationSettings;
  
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
    this.hasCompletedSetup = false,
    this.businessIds = const [],
    this.phoneNumber,
    this.notificationSettings,
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
      hasCompletedSetup: data['hasCompletedSetup'] ?? false,
      businessIds: List<String>.from(data['businessIds'] ?? []),
      phoneNumber: data['phoneNumber'],
      notificationSettings: data['notificationSettings'] as Map<String, dynamic>?,
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
      'hasCompletedSetup': hasCompletedSetup,
      'businessIds': businessIds,
      'phoneNumber': phoneNumber,
      'notificationSettings': notificationSettings,
    };
  }
  
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    bool? isActive,
    String? subscriptionStatus,
    DateTime? subscriptionEndDate,
    DateTime? updatedAt,
    bool? hasCompletedSetup,
    List<String>? businessIds,
    String? phoneNumber,
    Map<String, dynamic>? notificationSettings,
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
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      businessIds: businessIds ?? this.businessIds,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }
}