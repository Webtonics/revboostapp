// lib/core/services/onboarding_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _businessSetupCompletedKey = 'business_setup_completed';
  
  // Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }
  
  // Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }
  
  // Check if business setup is completed
  static Future<bool> isBusinessSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_businessSetupCompletedKey) ?? false;
  }
  
  // Mark business setup as completed
  static Future<void> setBusinessSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_businessSetupCompletedKey, true);
  }
  
  // Reset onboarding status (useful for testing)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.setBool(_businessSetupCompletedKey, false);
  }
}