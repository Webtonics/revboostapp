// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:revboostapp/models/user_model.dart';
import 'package:revboostapp/models/business_model.dart';

enum SettingsStatus { initial, loading, success, error }

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final FirebaseAuth _auth = FirebaseService().auth;
  
  SettingsStatus _status = SettingsStatus.initial;
  UserModel? _userProfile;
  BusinessModel? _businessProfile;
  String? _errorMessage;
  
  SettingsStatus get status => _status;
  UserModel? get userProfile => _userProfile;
  BusinessModel? get businessProfile => _businessProfile;
  String? get errorMessage => _errorMessage;
  
  SettingsProvider() {
    loadUserSettings();
  }
  
  Future<void> loadUserSettings() async {
    try {
      _status = SettingsStatus.loading;
      notifyListeners();
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Load user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _userProfile = UserModel.fromFirestore(userDoc);
      } else {
        throw Exception('User profile not found');
      }
      
      // Load business profile
      final businessQuery = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (businessQuery.docs.isNotEmpty) {
        _businessProfile = BusinessModel.fromFirestore(businessQuery.docs.first);
      }
      
      _status = SettingsStatus.success;
      notifyListeners();
    } catch (e) {
      _status = SettingsStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> updateUserProfile({
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      _status = SettingsStatus.loading;
      notifyListeners();
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Update fields that are provided
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      
      // Update in Firestore
      await _firestore.collection('users').doc(userId).update(updates);
      
      // Update email in Firebase Auth if provided
      if (email != null && email != _auth.currentUser?.email) {
        await _auth.currentUser?.updateEmail(email);
      }
      
      // Reload user profile
      await loadUserSettings();
      
      _status = SettingsStatus.success;
      notifyListeners();
    } catch (e) {
      _status = SettingsStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> updateBusinessProfile({
    String? name,
    String? description,
    Map<String, String>? reviewLinks,
  }) async {
    try {
      _status = SettingsStatus.loading;
      notifyListeners();
      
      if (_businessProfile == null) {
        throw Exception('No business profile found');
      }
      
      // Update fields that are provided
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (reviewLinks != null) updates['reviewLinks'] = reviewLinks;
      
      // Update in Firestore
      await _firestore.collection('businesses').doc(_businessProfile!.id).update(updates);
      
      // Reload business profile
      await loadUserSettings();
      
      _status = SettingsStatus.success;
      notifyListeners();
    } catch (e) {
      _status = SettingsStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> updateNotificationSettings({
    required bool emailNotifications,
    required bool pushNotifications,
  }) async {
    try {
      _status = SettingsStatus.loading;
      notifyListeners();
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _firestore.collection('users').doc(userId).update({
        'notificationSettings': {
          'emailEnabled': emailNotifications,
          'pushEnabled': pushNotifications,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await loadUserSettings();
      
      _status = SettingsStatus.success;
      notifyListeners();
    } catch (e) {
      _status = SettingsStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      _status = SettingsStatus.loading;
      notifyListeners();
      
      final user = _auth.currentUser;
      final email = user?.email;
      
      if (user == null || email == null) {
        throw Exception('User not authenticated');
      }
      
      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      _status = SettingsStatus.success;
      notifyListeners();
    } catch (e) {
      _status = SettingsStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
}