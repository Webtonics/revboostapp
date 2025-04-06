// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  
  // Collections
  CollectionReference<Map<String, dynamic>> get usersCollection => 
      _firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> get businessesCollection => 
      _firestore.collection('businesses');
  
  CollectionReference<Map<String, dynamic>> get reviewRequestsCollection => 
      _firestore.collection('reviewRequests');
  
  // User operations
  // In createUser method of FirestoreService
Future<void> createUser(UserModel user) async {
  try {
    print("Creating user document for ${user.id}");
    await usersCollection.doc(user.id).set(user.toFirestore());
    print("User document created successfully");
  } catch (e) {
    print("Error creating user document: $e");
    debugPrint('Error creating user: $e');
    rethrow;
  }
}
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }
  
  Future<void> updateUser(UserModel user) async {
    try {
      await usersCollection.doc(user.id).update(user.toFirestore());
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }
  
  // Business operations
  Future<String> createBusiness(BusinessModel business) async {
    try {
      final docRef = await businessesCollection.add(business.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating business: $e');
      rethrow;
    }
  }
  
  Future<BusinessModel?> getBusinessById(String businessId) async {
    try {
      final doc = await businessesCollection.doc(businessId).get();
      if (doc.exists) {
        return BusinessModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting business: $e');
      rethrow;
    }
  }
  
  Future<List<BusinessModel>> getBusinessesByOwnerId(String ownerId) async {
    try {
      final snapshot = await businessesCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      return snapshot.docs
          .map((doc) => BusinessModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting businesses: $e');
      rethrow;
    }
  }
  
  Future<void> updateBusiness(BusinessModel business) async {
    try {
      await businessesCollection.doc(business.id).update(business.toFirestore());
    } catch (e) {
      debugPrint('Error updating business: $e');
      rethrow;
    }
  }
  
  Future<void> deleteBusiness(String businessId) async {
    try {
      await businessesCollection.doc(businessId).delete();
    } catch (e) {
      debugPrint('Error deleting business: $e');
      rethrow;
    }
  }
  
  // Transaction example (use for operations that need to be atomic)
  Future<void> updateUserSubscription(String userId, String status, DateTime endDate) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(usersCollection.doc(userId));
        
        if (!userDoc.exists) {
          throw Exception('User does not exist!');
        }
        
        transaction.update(usersCollection.doc(userId), {
          'subscriptionStatus': status,
          'subscriptionEndDate': Timestamp.fromDate(endDate),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }
  
  // Batch write example (use for multiple operations that can fail independently)
  Future<void> deleteUserAndRelatedData(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Get all businesses owned by this user
      final businessesSnapshot = await businessesCollection
          .where('ownerId', isEqualTo: userId)
          .get();
      
      // Add delete operations to batch
      batch.delete(usersCollection.doc(userId));
      
      for (var doc in businessesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting user and related data: $e');
      rethrow;
    }
  }
}