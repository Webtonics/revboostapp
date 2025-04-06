// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseService().auth;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
  
  // Email & Password Registration
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
  
  // Get readable error message
  String getReadableAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'email-already-in-use':
          return 'This email address is already in use';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        case 'weak-password':
          return 'The password is too weak';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        case 'requires-recent-login':
          return 'This operation requires recent authentication. Please log in again.';
        default:
          return error.message ?? 'An unknown error occurred';
      }
    }
    return error.toString();
  }
}