import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

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
  final bool emailVerified; // Added this property
  
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
    this.emailVerified = false, // Default to false
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
      emailVerified: data['emailVerified'] ?? false, // Read from Firestore
    );
  }
  
  // Add this factory constructor to create a UserModel from a Firebase Auth user
  factory UserModel.fromFirebaseUser(auth.User user, {UserModel? existingData}) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? existingData?.displayName,
      photoUrl: user.photoURL ?? existingData?.photoUrl,
      createdAt: existingData?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: existingData?.isActive ?? true,
      subscriptionStatus: existingData?.subscriptionStatus,
      subscriptionEndDate: existingData?.subscriptionEndDate,
      hasCompletedSetup: existingData?.hasCompletedSetup ?? false,
      businessIds: existingData?.businessIds ?? [],
      phoneNumber: user.phoneNumber ?? existingData?.phoneNumber,
      notificationSettings: existingData?.notificationSettings,
      emailVerified: user.emailVerified, // Get from Firebase Auth user
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
      'emailVerified': emailVerified, // Save to Firestore
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
    bool? emailVerified, // Add to copyWith
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
      emailVerified: emailVerified ?? this.emailVerified, // Use in copyWith
    );
  }
}