// // lib/features/onboarding/services/onboarding_service.dart

// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class OnboardingService {
//   static const String _onboardingCompletedKey = 'onboarding_completed';
  
//   // Check if onboarding is completed (locally)
//   static Future<bool> isOnboardingCompleted() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_onboardingCompletedKey) ?? false;
//   }
  
//   // Mark onboarding as completed (locally)
//   static Future<void> setOnboardingCompleted() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_onboardingCompletedKey, true);
//   }
  
//   // Check if business setup is completed (from Firestore)
//   static Future<bool> isBusinessSetupCompleted() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return false;
      
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
      
//       if (userDoc.exists) {
//         return userDoc.data()?['hasCompletedSetup'] ?? false;
//       }
//       return false;
//     } catch (e) {
//       // print('Error checking business setup: $e');
//       return false;
//     }
//   }
  
//   // Mark business setup as completed (in Firestore)
//   static Future<void> setBusinessSetupCompleted() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;
      
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .update({
//         'hasCompletedSetup': true,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Also set local flag
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('business_setup_completed', true);
//     } catch (e) {
//       // print('Error marking business setup as completed: $e');
//     }
//   }
  
//   // Reset onboarding status for testing
//   static Future<void> resetOnboardingStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_onboardingCompletedKey, false);
//     await prefs.setBool('business_setup_completed', false);
//   }
// }

// lib/features/onboarding/services/onboarding_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revboostapp/core/services/firebase_service.dart';

/// Service to handle onboarding and business setup related operations
class OnboardingService {
  static final FirebaseAuth _auth = FirebaseService().auth;
  static final FirebaseFirestore _firestore = FirebaseService().firestore;
  
  // Keys for SharedPreferences
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _businessSetupCompletedKey = 'business_setup_completed';
  
  /// Check if onboarding has been completed
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }
  
  /// Check if business setup has been completed
  static Future<bool> hasCompletedBusinessSetup() async {
    try {
      // First, check Firestore for the user's status
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['hasCompletedSetup'] == true) {
        // If completed on Firestore, update local prefs to match
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_businessSetupCompletedKey, true);
        return true;
      }
      
      // If not confirmed in Firestore, check local prefs as fallback
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_businessSetupCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking business setup status: $e');
      return false;
    }
  }
  
  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      
      // Also update Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'hasCompletedOnboarding': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error setting onboarding as completed: $e');
    }
  }
  
  /// Mark business setup as completed
  static Future<void> setBusinessSetupCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_businessSetupCompletedKey, true);
      
      // Also update Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'hasCompletedSetup': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error setting business setup as completed: $e');
    }
  }
  
  /// Reset onboarding and business setup status (for testing or account reset)
  static Future<void> resetOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, false);
      await prefs.setBool(_businessSetupCompletedKey, false);
      
      // Also update Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'hasCompletedOnboarding': false,
          'hasCompletedSetup': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error resetting onboarding status: $e');
    }
  }
}