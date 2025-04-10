// lib/providers/dashboard_provider.dart - simplified version
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revboostapp/models/business_model.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _errorMessage;
  BusinessModel? _businessData;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BusinessModel? get businessData => _businessData;
  
  // Load basic dashboard data
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
      
      // Fetch the user's business
      final businessesSnapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (businessesSnapshot.docs.isEmpty) {
        _errorMessage = 'No business found. Please complete business setup first.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get business data
      _businessData = BusinessModel.fromFirestore(businessesSnapshot.docs.first);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading dashboard data: $e';
      notifyListeners();
    }
  }
}

// // lib/providers/dashboard_provider.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:revboostapp/models/dashboard_model.dart';

// class DashboardProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   bool _isLoading = false;
//   String? _errorMessage;
//   DashboardStats _stats = DashboardStats.empty();
  
//   // Getters
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   DashboardStats get stats => _stats;
  
//   // Load dashboard data
//   // lib/providers/dashboard_provider.dart
// // Update the loadDashboardData method to fetch real data

// Future<void> loadDashboardData() async {
//   if (_auth.currentUser == null) {
//     _errorMessage = 'User not authenticated';
//     notifyListeners();
//     return;
//   }
  
//   try {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
    
//     final userId = _auth.currentUser!.uid;
    
//     // Fetch the user's business
//     final businessesSnapshot = await _firestore
//         .collection('businesses')
//         .where('ownerId', isEqualTo: userId)
//         .limit(1)
//         .get();
    
//     if (businessesSnapshot.docs.isEmpty) {
//       _errorMessage = 'No business found. Please complete business setup first.';
//       _isLoading = false;
//       notifyListeners();
//       return;
//     }
    
//     final businessId = businessesSnapshot.docs.first.id;
    
//     // Parallel fetching for better performance
//     final reviewRequestsFuture = _firestore
//         .collection('reviewRequests')
//         .where('businessId', isEqualTo: businessId)
//         .get();
        
//     final reviewsFuture = _firestore
//         .collection('reviews')
//         .where('businessId', isEqualTo: businessId)
//         .get();
        
//     final qrScansFuture = _firestore
//         .collection('qrScans')
//         .where('businessId', isEqualTo: businessId)
//         .get();
        
//     final feedbackFuture = _firestore
//         .collection('feedback')
//         .where('businessId', isEqualTo: businessId)
//         .get();
        
//     final recentActivityFuture = _firestore
//         .collection('activity')
//         .where('businessId', isEqualTo: businessId)
//         .orderBy('timestamp', descending: true)
//         .limit(10)
//         .get();
    
//     // Wait for all queries to complete
//     final results = await Future.wait([
//       reviewRequestsFuture,
//       reviewsFuture,
//       qrScansFuture,
//       feedbackFuture,
//       recentActivityFuture,
//     ]);
    
//     final reviewRequestsSnapshot = results[0] as QuerySnapshot;
//     final reviewsSnapshot = results[1] as QuerySnapshot;
//     final qrScansSnapshot = results[2] as QuerySnapshot;
//     final feedbackSnapshot = results[3] as QuerySnapshot;
//     final recentActivitySnapshot = results[4] as QuerySnapshot;
    
//     // Calculate basic stats
//     final totalReviewRequests = reviewRequestsSnapshot.docs.length;
//     final reviewsReceived = reviewsSnapshot.docs.length;
//     final qrCodeScans = qrScansSnapshot.docs.length;
    
//     // Calculate click-through rate
//     final clickThroughRate = totalReviewRequests > 0
//         ? reviewsReceived / totalReviewRequests
//         : 0.0;
    
//     // Calculate rating distribution
//     // Calculate rating distribution
// final ratingDistribution = <String, int>{
//   '5': 0, '4': 0, '3': 0, '2': 0, '1': 0,
// };

// for (final doc in reviewsSnapshot.docs) {
//   // Safely access the rating field with a fallback
//   final data = doc.data() as Map<String, dynamic>;
//   final rating = data['rating']?.toString() ?? 'unknown';
  
//   if (ratingDistribution.containsKey(rating)) {
//     ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
//   }
// }

// // Calculate platform distribution
// final platformDistribution = <String, int>{};

// for (final doc in reviewsSnapshot.docs) {
//   final data = doc.data() as Map<String, dynamic>;
//   final platform = data['platform']?.toString() ?? 'Unknown';
//   platformDistribution[platform] = (platformDistribution[platform] ?? 0) + 1;
// }
//     // Build recent activity
//     final recentActivity = <ReviewActivity>[];
    
//     for (final doc in recentActivitySnapshot.docs) {
//       final data = doc.data() as Map<String, dynamic>;
      
//       ActivityType activityType;
//       switch (data['type']) {
//         case 'new_review':
//           activityType = ActivityType.newReview;
//           break;
//         case 'feedback':
//           activityType = ActivityType.feedback;
//           break;
//         case 'request_sent':
//           activityType = ActivityType.requestSent;
//           break;
//         case 'qr_scan':
//           activityType = ActivityType.qrScan;
//           break;
//         default:
//           continue; // Skip unknown types
//       }
      
//       recentActivity.add(ReviewActivity(
//         title: data['title'] ?? 'Activity',
//         subtitle: data['subtitle'] ?? '',
//         timestamp: (data['timestamp'] as Timestamp).toDate(),
//         type: activityType,
//       ));
//     }
    
//     // Create dashboard stats
//     _stats = DashboardStats(
//       totalReviewRequests: totalReviewRequests,
//       reviewsReceived: reviewsReceived,
//       qrCodeScans: qrCodeScans,
//       clickThroughRate: clickThroughRate,
//       recentActivity: recentActivity,
//       ratingDistribution: ratingDistribution,
//       platformDistribution: platformDistribution,
//     );
    
//     _isLoading = false;
//     notifyListeners();
//   } catch (e) {
//     _isLoading = false;
//     _errorMessage = 'Error loading dashboard data: $e';
//     notifyListeners();
//   }
// }
  
// }