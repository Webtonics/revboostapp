// lib/features/business_setup/services/business_setup_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:revboostapp/models/business_model.dart';

class BusinessSetupService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final FirebaseAuth _auth = FirebaseService().auth;
  
  // Check if the current user has completed business setup
  Future<bool> hasCompletedSetup() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      final userBusinesses = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: user.uid)
          .get();
      
      return userBusinesses.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking business setup status: $e');
      return false;
    }
  }
  
  // Save business information to Firestore
  // Future<String> saveBusinessInfo({
  //   required String name,
  //   required String description,
  //   String? logoUrl,
  //   Map<String, String> reviewLinks = const {},
  // }) async {
  //   try {
  //     final user = _auth.currentUser;
  //     if (user == null) {
  //       throw Exception('User not authenticated');
  //     }
      
  //     final newBusiness = BusinessModel(
  //       id: '', // Will be set after document creation
  //       ownerId: user.uid,
  //       name: name,
  //       description: description,
  //       logoUrl: logoUrl,
  //       reviewLinks: reviewLinks,
  //       createdAt: DateTime.now(),
  //       updatedAt: DateTime.now(),
  //     );
      
  //     // Save to Firestore
  //     final docRef = await _firestore.collection('businesses').add(
  //       newBusiness.toFirestore(),
  //     );
      
  //     // Update the user's profile with business info
  //     await _firestore.collection('users').doc(user.uid).update({
  //       'hasCompletedSetup': true,
  //       'businessIds': FieldValue.arrayUnion([docRef.id]),
  //       'updatedAt': Timestamp.now(),
  //     });
      
  //     return docRef.id;
  //   } catch (e) {
  //     debugPrint('Error saving business info: $e');
  //     throw Exception('Failed to save business information: $e');
  //   }
  // }
  // In the saveBusinessInfo method of BusinessSetupService:
Future<String> saveBusinessInfo({
  required String name,
  required String description,
  Map<String, String> reviewLinks = const {},
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Create business document
    final newBusiness = BusinessModel(
      id: '', // Will be set after document creation
      ownerId: user.uid,
      name: name,
      description: description,
      reviewLinks: reviewLinks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Save to Firestore
    final docRef = await _firestore.collection('businesses').add(
      newBusiness.toFirestore(),
    );
    
    // Update the user's profile to mark setup as completed
    await _firestore.collection('users').doc(user.uid).update({
      'hasCompletedSetup': true,
      'updatedAt': Timestamp.now(),
    });
    
    return docRef.id;
  } catch (e) {
    debugPrint('Error saving business info: $e');
    throw Exception('Failed to save business information: $e');
  }
}
  
  // Update business review links
  Future<void> updateReviewLinks(String businessId, Map<String, String> links) async {
    try {
      await _firestore.collection('businesses').doc(businessId).update({
        'reviewLinks': links,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating review links: $e');
      throw Exception('Failed to update review links: $e');
    }
  }
  
  // Upload business logo
  Future<String> uploadLogo(String businessId, Uint8List logoData) async {
    try {
      final storage = FirebaseService().storage;
      final path = 'business_logos/$businessId.png';
      
      final uploadTask = storage.ref(path).putData(
        logoData,
        SettableMetadata(contentType: 'image/png'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update business with logo URL
      await _firestore.collection('businesses').doc(businessId).update({
        'logoUrl': downloadUrl,
        'updatedAt': Timestamp.now(),
      });
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading logo: $e');
      throw Exception('Failed to upload business logo: $e');
    }
  }
}