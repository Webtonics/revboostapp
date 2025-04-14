// lib/core/config/api_config.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this dependency to pubspec.yaml
import 'package:firebase_remote_config/firebase_remote_config.dart'; // Optional for remote config

class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  
  factory ApiConfig() => _instance;
  
  ApiConfig._internal();
  
  String? _resendApiKey;
  String? _emailFromAddress;
  String? _emailFromName;
  
  String get resendApiKey => _resendApiKey ?? '';
  String get emailFromAddress => _emailFromAddress ?? 'reviewme@revboostapp.com';
  String get emailFromName => _emailFromName ?? 'RevBoostApp';
  
  /// Initialize API configuration
  Future<void> initialize() async {
    try {
      // Load from environment variables for production builds
      if (const bool.fromEnvironment('dart.vm.product')) {
        _loadFromEnvironment();
        return;
      }
      
      // For development, try to load from .env file
      await dotenv.load(fileName: ".env");
      _loadFromDotEnv();
    } catch (e) {
      debugPrint('Error loading API config: $e');
      _loadDefaults();
    }
  }
  
  void _loadFromEnvironment() {
    _resendApiKey = const String.fromEnvironment('RESEND_API_KEY');
    _emailFromAddress = const String.fromEnvironment('EMAIL_FROM_ADDRESS', 
                                                   defaultValue: 'reviewme@revboostapp.com');
    _emailFromName = const String.fromEnvironment('EMAIL_FROM_NAME', 
                                                defaultValue: 'RevBoost');
  }
  
  void _loadFromDotEnv() {
    _resendApiKey = dotenv.env['RESEND_API_KEY'];
    _emailFromAddress = dotenv.env['EMAIL_FROM_ADDRESS'] ?? 'reviewme@revboostapp.com';
    _emailFromName = dotenv.env['EMAIL_FROM_NAME'] ?? 'RevBoost';
  }
  
  void _loadDefaults() {
    _resendApiKey = '';  // You should set this before deploying
    _emailFromAddress = 'reviewme@revboostapp.com';
    _emailFromName = 'RevBoost';
  }
  
  // Optional: Load from Firebase Remote Config
  Future<void> loadFromRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      
      // Only override if the values are not empty
      final remoteApiKey = remoteConfig.getString('resend_api_key');
      if (remoteApiKey.isNotEmpty) {
        _resendApiKey = remoteApiKey;
      }
      
      final fromAddress = remoteConfig.getString('email_from_address');
      if (fromAddress.isNotEmpty) {
        _emailFromAddress = fromAddress;
      }
      
      final fromName = remoteConfig.getString('email_from_name');
      if (fromName.isNotEmpty) {
        _emailFromName = fromName;
      }
    } catch (e) {
      debugPrint('Error loading from remote config: $e');
    }
  }
}