// lib/core/services/simple_rate_limiting_service.dart
// Simple monthly rate limiting - 100 for free, 2000 for paid

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RateLimitException implements Exception {
  final String message;
  final int used;
  final int limit;
  
  RateLimitException(this.message, this.used, this.limit);
  
  @override
  String toString() => message;
}

class SimpleRateLimitingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get monthly limit based on plan
  int _getMonthlyLimit(String planType) {
    switch (planType.toLowerCase()) {
      case 'pro':
      case 'monthly':
      case 'yearly':
        return 2000;
      default:
        return 100; // Free plan
    }
  }
  
  /// Check if user can send requests and update usage
  Future<void> checkAndUpdateUsage({
    required String userId,
    required String planType,
    int requestCount = 1,
  }) async {
    final limit = _getMonthlyLimit(planType);
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final userRef = _firestore.collection('userUsage').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      
      Map<String, dynamic> data = {};
      if (userDoc.exists) {
        data = userDoc.data() as Map<String, dynamic>;
      }
      
      // Get current month usage
      final monthlyData = data['monthly'] as Map<String, dynamic>? ?? {};
      final currentUsage = monthlyData[currentMonth] as int? ?? 0;
      
      // Check if adding requests would exceed limit
      if (currentUsage + requestCount > limit) {
        throw RateLimitException(
          'Monthly limit of $limit requests exceeded. Used: $currentUsage',
          currentUsage,
          limit,
        );
      }
      
      // Update usage
      final updatedData = {
        'userId': userId,
        'planType': planType,
        'monthly': {
          ...monthlyData,
          currentMonth: currentUsage + requestCount,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      transaction.set(userRef, updatedData, SetOptions(merge: true));
    });
    
    debugPrint('Usage updated for $userId: +$requestCount requests');
  }
  
  /// Get current usage for user
  Future<Map<String, dynamic>> getUserUsage(String userId, String planType) async {
    final limit = _getMonthlyLimit(planType);
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final userDoc = await _firestore.collection('userUsage').doc(userId).get();
    
    int currentUsage = 0;
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final monthlyData = data['monthly'] as Map<String, dynamic>? ?? {};
      currentUsage = monthlyData[currentMonth] as int? ?? 0;
    }
    
    return {
      'used': currentUsage,
      'limit': limit,
      'remaining': limit - currentUsage,
      'percentage': (currentUsage / limit * 100).round(),
      'planType': planType,
      'month': currentMonth,
    };
  }
  
  /// Rollback usage (in case of failure)
  Future<void> rollbackUsage({
    required String userId,
    int requestCount = 1,
  }) async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('userUsage').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final monthlyData = data['monthly'] as Map<String, dynamic>? ?? {};
          final currentUsage = monthlyData[currentMonth] as int? ?? 0;
          
          final newUsage = (currentUsage - requestCount).clamp(0, double.infinity).toInt();
          
          final updatedData = {
            ...data,
            'monthly': {
              ...monthlyData,
              currentMonth: newUsage,
            },
            'lastUpdated': FieldValue.serverTimestamp(),
          };
          
          transaction.set(userRef, updatedData);
        }
      });
      
      debugPrint('Usage rolled back for $userId: -$requestCount requests');
    } catch (e) {
      debugPrint('Error rolling back usage: $e');
    }
  }
}