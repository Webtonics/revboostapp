// lib/providers/business_setup_provider.dart

import 'package:flutter/foundation.dart';
import 'package:revboostapp/features/business_setup/services/business_setup_service.dart';

enum BusinessSetupStatus {
  initial,
  loading,
  success,
  error,
}

class BusinessSetupProvider with ChangeNotifier {
  final BusinessSetupService _businessSetupService = BusinessSetupService();
  
  BusinessSetupStatus _status = BusinessSetupStatus.initial;
  String? _businessId;
  String? _errorMessage;
  
  // Business information
  String _name = '';
  String _description = '';
  Uint8List? _logoData;
  Map<String, String> _reviewLinks = {};
  
  // Getters
  BusinessSetupStatus get status => _status;
  String? get businessId => _businessId;
  String? get errorMessage => _errorMessage;
  
  String get name => _name;
  String get description => _description;
  Uint8List? get logoData => _logoData;
  Map<String, String> get reviewLinks => _reviewLinks;
  
  // Check if business setup has been completed
  Future<bool> checkSetupCompletion() async {
    try {
      final completed = await _businessSetupService.hasCompletedSetup();
      return completed;
    } catch (e) {
      debugPrint('Error checking setup completion: $e');
      return false;
    }
  }
  
  // Set business information
  void setBusinessInfo({
    required String name,
    required String description,
  }) {
    _name = name;
    _description = description;
    notifyListeners();
  }
  
  // Set business logo
  void setLogo(Uint8List logoData) {
    _logoData = logoData;
    notifyListeners();
  }
  
  // Set review platform link
  void setReviewLink(String platform, String link) {
    _reviewLinks[platform] = link;
    notifyListeners();
  }
  
  // Remove review platform link
  void removeReviewLink(String platform) {
    _reviewLinks.remove(platform);
    notifyListeners();
  }
  
  // Save all business information
  // In your BusinessSetupProvider class, modify the saveBusinessSetup method:
Future<void> saveBusinessSetup() async {
  if (_name.isEmpty) {
    _errorMessage = 'Business name is required';
    notifyListeners();
    return;
  }
  
  try {
    _status = BusinessSetupStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    // Save business info (without logo)
    final businessId = await _businessSetupService.saveBusinessInfo(
      name: _name,
      description: _description,
      reviewLinks: _reviewLinks,
      // Skip logo upload for now
    );
    
    _businessId = businessId;
    
    // Skip logo upload
    /*
    if (_logoData != null) {
      await _businessSetupService.uploadLogo(businessId, _logoData!);
    }
    */
    
    _status = BusinessSetupStatus.success;
    notifyListeners();
  } catch (e) {
    _status = BusinessSetupStatus.error;
    _errorMessage = e.toString();
    notifyListeners();
    throw Exception(_errorMessage);
  }
}

  void clearLogo() {
  _logoData = null;
  notifyListeners();
}
  
  // Reset the provider state
  void reset() {
    _status = BusinessSetupStatus.initial;
    _businessId = null;
    _errorMessage = null;
    _name = '';
    _description = '';
    _logoData = null;
    _reviewLinks = {};
    notifyListeners();
  }
}