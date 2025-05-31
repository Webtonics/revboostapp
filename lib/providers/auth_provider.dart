// lib/providers/auth_provider.dart - Complete rewrite with proper state management

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/services/auth_service.dart';
import 'package:revboostapp/core/services/firestore_service.dart';
import 'package:revboostapp/models/user_model.dart';

import '../core/utils/auth_error_handler.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _user;
  String? _errorMessage;
  String? _errorCode;
  String? _errorSuggestion;
  
  // Flags to prevent race conditions
  bool _isProcessingAuth = false;
  bool _isInitialized = false;
  
  // Performance optimization: Tracking timestamps for caching and debouncing
  DateTime? _lastUserReloadTime;
  DateTime? _lastUserFetchTime;
  bool _isReloadingUser = false;
  bool _isFetchingUser = false;
  
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorSuggestion => _errorSuggestion;
  
  // Constructor
  AuthProvider() {
    Future.microtask(() => _init());
  }
  
  /// Initialize auth state listener
  Future<void> _init() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        debugPrint('🚀 Initializing AuthProvider');
      }
      
      _authService.authStateChanges.listen((User? user) async {
        if (_isProcessingAuth) {
          if (kDebugMode) {
            debugPrint('⏸️ Auth state change ignored - processing in progress');
          }
          return;
        }
        
        await _handleAuthStateChange(user);
      });
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ AuthProvider initialized');
      }
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      if (kDebugMode) {
        debugPrint('❌ Error in auth initialization: $e');
      }
      notifyListeners();
    }
  }
  
  void _handleError(dynamic error, [String prefix = '']) {
    // Use the enhanced error handler
    _errorMessage = AuthErrorHandler.getReadableAuthError(error);
    _errorSuggestion = AuthErrorHandler.getErrorSuggestion(error);
    
    // Apply prefix if provided
    if (prefix.isNotEmpty && _errorMessage != null) {
      _errorMessage = prefix + _errorMessage!;
    }
    
    // Extract error code for debugging (keep for internal use)
    if (error is FirebaseAuthException) {
      _errorCode = error.code;
    } else {
      _errorCode = 'unknown';
    }
    
    if (kDebugMode) {
      debugPrint('❌ Auth error: $_errorMessage (code: $_errorCode)');
      if (_errorSuggestion != null) {
        debugPrint('💡 Suggestion: $_errorSuggestion');
      }
    }
  }
   void clearError() {
    _errorMessage = null;
    _errorCode = null;
    _errorSuggestion = null;
    notifyListeners();
  }

  /// Check if current error is network-related
  bool get isNetworkError {
    return _errorCode != null && AuthErrorHandler.isNetworkError(_errorCode);
  }
  
  /// Check if error requires user action
  bool get requiresUserAction {
    return _errorCode != null && AuthErrorHandler.requiresUserAction(_errorCode);
  }
  /// Handle auth state changes from Firebase
  Future<void> _handleAuthStateChange(User? user) async {
    if (kDebugMode) {
      debugPrint('🔄 Auth state changed: ${user?.uid ?? 'null'}');
    }
    
    _firebaseUser = user;
    
    if (user == null) {
      // User signed out
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = null;
      _errorCode = null;
      
      if (kDebugMode) {
        debugPrint('👋 User signed out');
      }
    } else {
      // User signed in - but only process if not already processing
      if (_status == AuthStatus.loading || _status == AuthStatus.authenticated) {
        if (kDebugMode) {
          debugPrint('⏭️ Skipping auth state processing - already handled');
        }
        return;
      }
      
      _status = AuthStatus.loading;
      notifyListeners();
      
      try {
        await _loadUserData(user);
        
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        _errorCode = null;
        
        if (kDebugMode) {
          debugPrint('✅ Auth state change processed - user authenticated');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error processing auth state change: $e');
        }
        
        // Try to create user if it doesn't exist
        try {
          await _createUserDocument(user);
          _status = AuthStatus.authenticated;
          _errorMessage = null;
          _errorCode = null;
          
          if (kDebugMode) {
            debugPrint('✅ New user created and authenticated');
          }
        } catch (createError) {
          _status = AuthStatus.error;
          _handleError(createError, 'Failed to create user profile: ');
        }
      }
    }
    
    notifyListeners();
  }
  
  /// Load user data from Firestore
  Future<void> _loadUserData(User firebaseUser) async {
    // Prevent concurrent fetches
    if (_isFetchingUser) {
      if (kDebugMode) {
        debugPrint('🛑 Already fetching user data, waiting...');
      }
      
      // Wait for existing fetch to complete
      while (_isFetchingUser) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    // Check cache
    final now = DateTime.now();
    if (_lastUserFetchTime != null && 
        now.difference(_lastUserFetchTime!).inSeconds < 10 &&
        _user != null &&
        _user!.id == firebaseUser.uid) {
      if (kDebugMode) {
        debugPrint('📋 Using cached user data');
      }
      return;
    }
    
    try {
      _isFetchingUser = true;
      
      if (kDebugMode) {
        debugPrint('📥 Fetching user data for: ${firebaseUser.uid}');
      }
      
      final userDoc = await _firestoreService.getUserById(firebaseUser.uid);
      _lastUserFetchTime = now;
      
      if (userDoc != null) {
        // Update email verification status from Firebase Auth
        final updatedUser = userDoc.copyWith(
          emailVerified: firebaseUser.emailVerified,
          updatedAt: now,
        );
        
        // Only update Firestore if verification status changed
        if (userDoc.emailVerified != firebaseUser.emailVerified) {
          await _firestoreService.updateEmailVerificationStatus(
            firebaseUser.uid, 
            firebaseUser.emailVerified
          );
        }
        
        _user = updatedUser;
        
        if (kDebugMode) {
          debugPrint('✅ User data loaded successfully');
        }
      } else {
        throw Exception('User document not found');
      }
    } finally {
      _isFetchingUser = false;
    }
  }
  
  /// Create a new user document
  Future<void> _createUserDocument(User firebaseUser) async {
    if (kDebugMode) {
      debugPrint('📝 Creating user document for: ${firebaseUser.uid}');
    }
    
    final newUser = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      hasCompletedSetup: false,
      emailVerified: firebaseUser.emailVerified,
    );
    
    await _firestoreService.createUser(newUser);
    _user = newUser;
    
    if (kDebugMode) {
      debugPrint('✅ User document created');
    }
  }
  
  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    if (_isProcessingAuth) {
      if (kDebugMode) {
        debugPrint('🛑 Sign in already in progress');
      }
      return;
    }
    
    try {
      _isProcessingAuth = true;
      _status = AuthStatus.loading;
      _errorMessage = null;
      _errorCode = null;
      _errorSuggestion = null; // Clear suggestion
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('🔐 Attempting to sign in with email: $email');
      }
      
      // Enhanced input validation with user-friendly messages
      if (email.trim().isEmpty) {
        throw Exception('Please enter your email address');
      }
      
      if (password.isEmpty) {
        throw Exception('Please enter your password');
      }
      
      // Basic email format validation
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address');
      }
      
      // Authenticate with Firebase
      final userCredential = await _authService.signInWithEmailAndPassword(
        email.trim(), 
        password
      );
      final user = userCredential.user;
      
      if (user == null) {
        throw Exception('Sign in failed. Please try again');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Firebase authentication successful: ${user.uid}');
      }
      
      // Set firebase user immediately
      _firebaseUser = user;
      
      // Load or create user data
      try {
        await _loadUserData(user);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('📝 User data not found, creating new document');
        }
        await _createUserDocument(user);
      }
      
      // Set authenticated status
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _errorCode = null;
      _errorSuggestion = null;
      
      if (kDebugMode) {
        debugPrint('🎉 Sign in completed successfully');
      }
      
      notifyListeners();
      
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('❌ Sign in error: $e');
      }
      
      rethrow;
    } finally {
      _isProcessingAuth = false;
    }
  }
  
  // Enhanced sign up method with better error handling
  Future<void> signUp(String email, String password, String displayName) async {
    if (_isProcessingAuth) {
      if (kDebugMode) {
        debugPrint('🛑 Sign up already in progress');
      }
      return;
    }
    
    try {
      _isProcessingAuth = true;
      _status = AuthStatus.loading;
      _errorMessage = null;
      _errorCode = null;
      _errorSuggestion = null;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('📝 Attempting to sign up with email: $email');
      }
      
      // Enhanced input validation
      if (email.trim().isEmpty) {
        throw Exception('Please enter your email address');
      }
      
      if (password.isEmpty) {
        throw Exception('Please enter a password');
      }
      
      if (displayName.trim().isEmpty) {
        throw Exception('Please enter your full name');
      }
      
      // Email format validation
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address');
      }
      
      // Password strength validation
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters long');
      }
      
      // Create account
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email.trim(), 
        password
      );
      final user = userCredential.user;
      
      if (user == null) {
        throw Exception('Account creation failed. Please try again');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Firebase account created: ${user.uid}');
      }
      
      // Update display name
      await _authService.updateUserProfile(displayName: displayName.trim());
      
      // Send email verification
      await user.sendEmailVerification();
      
      // Set firebase user
      _firebaseUser = user;
      
      // Create user document
      await _createUserDocument(user);
      
      // Set authenticated status
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _errorCode = null;
      _errorSuggestion = null;
      
      if (kDebugMode) {
        debugPrint('🎉 Sign up completed successfully');
      }
      
      notifyListeners();
      
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('❌ Sign up error: $e');
      }
      
      rethrow;
    } finally {
      _isProcessingAuth = false;
    }
  }
  
  // Enhanced reset password method
  Future<void> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        throw Exception('Please enter your email address');
      }
      
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address');
      }
      
      await _authService.sendPasswordResetEmail(email.trim());
      
      if (kDebugMode) {
        debugPrint('📧 Password reset email sent to: $email');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  /// Sign out
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        debugPrint('👋 Signing out user');
      }
      
      // Reset cached data
      _lastUserReloadTime = null;
      _lastUserFetchTime = null;
      _errorMessage = null;
      _errorCode = null;
      _isProcessingAuth = false;
      
      await _authService.signOut();
      
      // Auth state listener will handle the rest
      
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      notifyListeners();
      rethrow;
    }
  }
  
  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      if (_user == null || _firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
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
      _errorMessage = null;
      _errorCode = null;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Profile updated successfully');
      }
    } catch (e) {
      _handleError(e);
      notifyListeners();
      rethrow;
    }
  }
  
  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (_firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      await _firebaseUser!.sendEmailVerification();
      
      if (kDebugMode) {
        debugPrint('📧 Verification email sent to: ${_firebaseUser!.email}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Reload user from Firebase
  Future<void> reloadUser() async {
    if (_isReloadingUser) {
      if (kDebugMode) {
        debugPrint('🛑 Already reloading user');
      }
      return;
    }
    
    // Check cooldown
    final now = DateTime.now();
    if (_lastUserReloadTime != null && 
        now.difference(_lastUserReloadTime!).inSeconds < 15) {
      if (kDebugMode) {
        debugPrint('⏱️ User reload on cooldown');
      }
      return;
    }
    
    try {
      _isReloadingUser = true;
      
      if (_firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Reload Firebase user
      await _firebaseUser!.reload();
      _lastUserReloadTime = now;
      
      // Update reference
      final freshUser = _authService.currentUser;
      if (freshUser != null) {
        _firebaseUser = freshUser;
        
        // Update user model with fresh data
        if (_user != null) {
          final updatedUser = _user!.copyWith(
            emailVerified: freshUser.emailVerified,
            updatedAt: now,
          );
          
          // Update Firestore if verification status changed
          if (_user!.emailVerified != freshUser.emailVerified) {
            await _firestoreService.updateEmailVerificationStatus(
              freshUser.uid, 
              freshUser.emailVerified
            );
          }
          
          _user = updatedUser;
          notifyListeners();
        }
        
        if (kDebugMode) {
          debugPrint('🔄 User reloaded. Email verified: ${freshUser.emailVerified}');
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('❌ Error reloading user: $e');
      }
      rethrow;
    } finally {
      _isReloadingUser = false;
    }
  }
  
  /// Update user setup completion status
  Future<void> updateUserSetupStatus(bool hasCompleted) async {
    try {
      if (_user == null || _firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Update local user model
      _user = _user!.copyWith(
        hasCompletedSetup: hasCompleted,
        updatedAt: DateTime.now(),
      );
      
      // Update Firestore document
      await _firestoreService.updateUser(_user!);
      
      if (kDebugMode) {
        debugPrint('✅ User setup status updated: $hasCompleted');
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('❌ Error updating user setup status: $e');
      }
      rethrow;
    }
  }
  
  /// Persist auth state (for app startup)
  Future<void> persistAuthState() async {
    if (_firebaseUser != null) {
      try {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          _firebaseUser = currentUser;
          
          // Load user data if needed
          if (_user == null || _lastUserFetchTime == null || 
              DateTime.now().difference(_lastUserFetchTime!).inMinutes > 5) {
            await _loadUserData(currentUser);
          }
          
          _status = AuthStatus.authenticated;
          notifyListeners();
          
          if (kDebugMode) {
            debugPrint('✅ Auth state persisted');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error persisting auth state: $e');
        }
      }
    }
  }
  
  /// Reload auth state (for debugging/manual refresh)
  Future<void> reloadAuthState() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _firebaseUser = currentUser;
        _status = AuthStatus.authenticated;
        
        // Reload user data
        if (_user == null || _lastUserFetchTime == null || 
            DateTime.now().difference(_lastUserFetchTime!).inMinutes > 5) {
          try {
            await _loadUserData(currentUser);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Error loading user data during reload: $e');
            }
          }
        }
        
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('🔄 Auth state reloaded: Authenticated');
        }
      } else {
        _status = AuthStatus.unauthenticated;
        _firebaseUser = null;
        _user = null;
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('🔄 Auth state reloaded: Unauthenticated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error reloading auth state: $e');
      }
    }
  }
  
  /// Handle errors with user-friendly messages
  // void _handleError(dynamic error, [String prefix = '']) {
  //   _errorCode = _extractErrorCode(error);
  //   _errorMessage = _getUserFriendlyErrorMessage(_errorCode);
    
  //   if (_errorMessage == null) {
  //     _errorMessage = prefix + error.toString();
  //   } else if (prefix.isNotEmpty) {
  //     _errorMessage = prefix + _errorMessage!;
  //   }
    
  //   if (kDebugMode) {
  //     debugPrint('❌ Auth error: $_errorMessage (code: $_errorCode)');
  //   }
  // }
  
  // /// Extract Firebase error code
  // // String? _extractErrorCode(dynamic error) {
  // //   if (error is FirebaseAuthException) {
  // //     return error.code;
  // //   } else if (error is String && error.contains('firebase_auth/')) {
  // //     final RegExp regExp = RegExp(r'firebase_auth\/([\w-]+)');
  // //     final match = regExp.firstMatch(error);
  // //     if (match != null && match.groupCount >= 1) {
  // //       return match.group(1);
  // //     }
  // //   }
  // //   return null;
  // // }
  
  // // /// Get user-friendly error messages
  // // String? _getUserFriendlyErrorMessage(String? errorCode) {
  //   if (errorCode == null) return null;
    
  //   switch (errorCode) {
  //     // Sign in errors
  //     case 'invalid-email':
  //       return 'Please enter a valid email address';
  //     case 'user-disabled':
  //       return 'This account has been disabled. Please contact support';
  //     case 'user-not-found':
  //       return 'No account found with this email. Please check or create a new account';
  //     case 'wrong-password':
  //       return 'Incorrect password. Please try again or reset your password';
  //     case 'invalid-credential':
  //       return 'Invalid login credentials. Please check your email and password';
  //     case 'invalid-verification-code':
  //       return 'Invalid verification code';
  //     case 'invalid-verification-id':
  //       return 'Invalid verification ID';
        
  //     // Sign up errors
  //     case 'email-already-in-use':
  //       return 'An account already exists with this email address';
  //     case 'operation-not-allowed':
  //       return 'This operation is not allowed. Please contact support';
  //     case 'weak-password':
  //       return 'Your password is too weak. Please use a stronger password';
        
  //     // Reset password errors
  //     case 'missing-email':
  //       return 'Please provide an email address';
  //     case 'expired-action-code':
  //       return 'The password reset link has expired. Please request a new one';
  //     case 'invalid-action-code':
  //       return 'The password reset link is invalid. Please request a new one';
        
  //     // Network errors
  //     case 'network-request-failed':
  //       return 'Network error. Please check your internet connection and try again';
  //     case 'too-many-requests':
  //       return 'Too many unsuccessful attempts. Please try again later';
  //     case 'timeout':
  //       return 'Request timeout. Please check your internet connection and try again';
        
  //     default:
  //       return null;
  //   }
  // }
}