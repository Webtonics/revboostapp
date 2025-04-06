// lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/auth_service.dart';
import 'package:revboostapp/core/services/firestore_service.dart';
import 'package:revboostapp/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _user;
  String? _errorMessage;
  
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  // Constructor without direct Firebase access
  AuthProvider() {
    // Schedule initialization for the next microtask to avoid constructor issues
    Future.microtask(() => _init());
  }
  
  Future<void> _init() async {
    try {
      // Now safe to access Firebase services
      _authService.authStateChanges.listen((User? user) async {
        _firebaseUser = user;
        
        if (user == null) {
          _status = AuthStatus.unauthenticated;
          _user = null;
        } else {
          _status = AuthStatus.loading;
          notifyListeners();
          
          try {
            await _fetchUserData(user.uid);
            _status = AuthStatus.authenticated;
          } catch (e) {
            _status = AuthStatus.error;
            _errorMessage = e.toString();
            debugPrint('Error fetching user data: $e');
          }
        }
        
        notifyListeners();
      });
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      debugPrint('Error in auth initialization: $e');
      notifyListeners();
    }
  }
  
  Future<void> _fetchUserData(String userId) async {
    final userModel = await _firestoreService.getUserById(userId);
    
    if (userModel != null) {
      _user = userModel;
    } else {
      _user = null;
      throw Exception('User data not found');
    }
  }
  
  Future<void> signIn(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _authService.signInWithEmailAndPassword(email, password);
      
      // Auth state changes listener will handle updating the status
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _authService.getReadableAuthError(e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> signUp(String email, String password, String displayName) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      
      final user = userCredential.user;
      if (user != null) {
        // Update display name
        await _authService.updateUserProfile(displayName: displayName);
        
        // Create user document
        final newUser = UserModel(
          id: user.uid,
          email: user.email!,
          displayName: displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
        
        await _firestoreService.createUser(newUser);
        
        // Auth state changes listener will handle updating the status
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _authService.getReadableAuthError(e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      // Auth state changes listener will handle updating the status
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception(_authService.getReadableAuthError(e));
    }
  }
  
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      if (_user == null) return;
      
      // Update Firebase Auth profile
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoUrl,
      );
      
      // Update Firestore user document
      final updatedUser = _user!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateUser(updatedUser);
      
      // Update local user model
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
}