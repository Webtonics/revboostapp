// lib/features/onboarding/services/onboarding_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  
  // Check if onboarding is completed (locally)
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }
  
  // Mark onboarding as completed (locally)
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }
  
  // Check if business setup is completed (from Firestore)
  static Future<bool> isBusinessSetupCompleted() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data()?['hasCompletedSetup'] ?? false;
      }
      return false;
    } catch (e) {
      // print('Error checking business setup: $e');
      return false;
    }
  }
  
  // Mark business setup as completed (in Firestore)
  static Future<void> setBusinessSetupCompleted() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'hasCompletedSetup': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also set local flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('business_setup_completed', true);
    } catch (e) {
      // print('Error marking business setup as completed: $e');
    }
  }
  
  // Reset onboarding status for testing
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.setBool('business_setup_completed', false);
  }
}