// lib/providers/dashboard_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revboostapp/models/dashboard_model.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _errorMessage;
  DashboardStats _stats = DashboardStats.empty();
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardStats get stats => _stats;
  
  // Load dashboard data
  Future<void> loadDashboardData() async {
    if (_auth.currentUser == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final userId = _auth.currentUser!.uid;
      
      // For now, we'll use placeholder data
      // In the next step, we'll connect to real Firebase data
      _stats = await _getPlaceholderData();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading dashboard data: $e';
      notifyListeners();
    }
  }
  
  // Placeholder data method - we'll replace this with Firebase data next
  Future<DashboardStats> _getPlaceholderData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return DashboardStats(
      totalReviewRequests: 156,
      reviewsReceived: 89,
      qrCodeScans: 234,
      clickThroughRate: 0.68,
      recentActivity: [
        ReviewActivity(
          title: 'New review from John D.',
          subtitle: '5 stars on Google',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          type: ActivityType.newReview,
        ),
        ReviewActivity(
          title: 'Feedback received',
          subtitle: 'Private feedback from customer',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: ActivityType.feedback,
        ),
        ReviewActivity(
          title: 'Review request sent',
          subtitle: 'To jane@example.com',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          type: ActivityType.requestSent,
        ),
        ReviewActivity(
          title: 'QR code scanned',
          subtitle: '3 new scans today',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          type: ActivityType.qrScan,
        ),
      ],
      ratingDistribution: {
        '5': 45,
        '4': 30,
        '3': 10,
        '2': 3,
        '1': 1,
      },
      platformDistribution: {
        'Google': 48,
        'Facebook': 23,
        'Yelp': 18,
      },
    );
  }
}