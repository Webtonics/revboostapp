// lib/providers/auth_provider.dart - Updated with improved error handling

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
  String? _errorCode; // Added to store error codes
  
  // Performance optimization: Tracking timestamps for caching and debouncing
  DateTime? _lastUserReloadTime;
  DateTime? _lastUserFetchTime;
  bool _isReloadingUser = false;
  bool _isFetchingUser = false;
  
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode; // Getter for error code
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  // Constructor without direct Firebase access
  AuthProvider() {
    // Schedule initialization for the next microtask to avoid constructor issues
    Future.microtask(() => _init());
  }
  
  Future<void> _init() async {
    try {
      _authService.authStateChanges.listen((User? user) async {
        if (kDebugMode) {
          debugPrint('Auth state changed: ${user?.uid}');
        }
        _firebaseUser = user;
        
        if (user == null) {
          _status = AuthStatus.unauthenticated;
          _user = null;
          if (kDebugMode) {
            debugPrint('AuthStatus set to: unauthenticated');
          }
        } else {
          _status = AuthStatus.loading;
          if (kDebugMode) {
            debugPrint('AuthStatus set to: loading');
          }
          notifyListeners();
          
          try {
            // Try to get the user document with optimized fetching
            await _fetchUserData(user.uid);
            _status = AuthStatus.authenticated;
            // Clear any existing error messages on successful authentication
            _errorMessage = null;
            _errorCode = null;
            if (kDebugMode) {
              debugPrint('AuthStatus set to: authenticated');
            }
          } catch (e) {
            // Create user document if needed
            if (kDebugMode) {
              debugPrint('Error fetching user data, creating new document: $e');
            }
            try {
              final newUser = UserModel(
                id: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? 'User',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isActive: true,
                emailVerified: user.emailVerified, // Add email verification status
              );
              
              await _firestoreService.createUser(newUser);
              _user = newUser;
              _status = AuthStatus.authenticated;
              // Clear any existing error messages
              _errorMessage = null;
              _errorCode = null;
              if (kDebugMode) {
                debugPrint('Created new user document and authenticated');
              }
            } catch (createError) {
              _status = AuthStatus.error;
              _handleError(createError, 'Failed to create user profile: ');
              if (kDebugMode) {
                debugPrint('Failed to create user document: $createError');
              }
            }
          }
        }
        
        notifyListeners();
      });
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      if (kDebugMode) {
        debugPrint('Error in auth initialization: $e');
      }
      notifyListeners();
    }
  }
  
  // NEW: Improved error handling method
  void _handleError(dynamic error, [String prefix = '']) {
    _errorCode = _extractErrorCode(error);
    _errorMessage = _getUserFriendlyErrorMessage(_errorCode);
    
    if (_errorMessage == null) {
      // If we don't have a user-friendly message, use the raw error
      _errorMessage = prefix + error.toString();
    } else if (prefix.isNotEmpty) {
      _errorMessage = prefix + _errorMessage!;
    }
  }
  
  // NEW: Extract Firebase error code from exception
  String? _extractErrorCode(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code;
    } else if (error is String && error.contains('firebase_auth/')) {
      // Extract code from error string like [firebase_auth/invalid-email]
      final RegExp regExp = RegExp(r'firebase_auth\/([\w-]+)');
      final match = regExp.firstMatch(error);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }
  
  // NEW: Get user-friendly error messages based on Firebase error codes
  String? _getUserFriendlyErrorMessage(String? errorCode) {
    if (errorCode == null) return null;
    
    switch (errorCode) {
      // Sign in errors
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support';
      case 'user-not-found':
        return 'No account found with this email. Please check or create a new account';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
        
      // Sign up errors
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support';
      case 'weak-password':
        return 'Your password is too weak. Please use a stronger password';
        
      // Reset password errors
      case 'missing-email':
        return 'Please provide an email address';
      case 'expired-action-code':
        return 'The password reset link has expired. Please request a new one';
      case 'invalid-action-code':
        return 'The password reset link is invalid. Please request a new one';
        
      // General network errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later';
      case 'operation-not-supported-in-this-environment':
        return 'This operation is not supported in your current environment';
        
      // Timeout errors
      case 'timeout':
        return 'Request timeout. Please check your internet connection and try again';
        
      // Default case for unknown errors
      default:
        return null;
    }
  }
    
  // OPTIMIZED: User data fetching with debounce and caching
  Future<void> _fetchUserData(String userId) async {
    // Prevent concurrent fetches
    if (_isFetchingUser) {
      if (kDebugMode) {
        debugPrint('🛑 Already fetching user data, skipping request');
      }
      return;
    }
    
    // Check if we need to fetch (cooldown period)
    final now = DateTime.now();
    if (_lastUserFetchTime != null && 
        now.difference(_lastUserFetchTime!).inSeconds < 10 &&
        _user != null) {
      if (kDebugMode) {
        debugPrint('⏱️ Using cached user data (fetched ${now.difference(_lastUserFetchTime!).inSeconds}s ago)');
      }
      return;
    }
    
    try {
      _isFetchingUser = true;
      
      final userDoc = await _firestoreService.getUserById(userId);
      _lastUserFetchTime = now;
      
      if (userDoc != null) {
        // Update email verification status from Firebase Auth to the user model
        if (_firebaseUser != null) {
          final updatedUser = userDoc.copyWith(
            emailVerified: _firebaseUser!.emailVerified,
            updatedAt: now,
          );
          
          // Only update Firestore if verification status changed
          if (userDoc.emailVerified != _firebaseUser!.emailVerified) {
            await _firestoreService.updateEmailVerificationStatus(
              userId, 
              _firebaseUser!.emailVerified
            );
          }
          
          _user = updatedUser;
        } else {
          _user = userDoc;
        }
      } else {
        // If user document doesn't exist, create a new one with setup not completed
        final authUser = _firebaseUser;
        if (authUser != null) {
          final newUser = UserModel(
            id: authUser.uid,
            email: authUser.email ?? '',
            displayName: authUser.displayName,
            photoUrl: authUser.photoURL,
            createdAt: now,
            updatedAt: now,
            isActive: true,
            hasCompletedSetup: false, // Important: default to false
            emailVerified: authUser.emailVerified, // Add email verification status
          );
          
          await _firestoreService.createUser(newUser);
          _user = newUser;
        } else {
          throw Exception('User data not found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user data: $e');
      }
      rethrow;
    } finally {
      _isFetchingUser = false;
    }
  }
  
  Future<void> signIn(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _errorCode = null;
      notifyListeners();
      
      // Log authentication attempt
      if (kDebugMode) {
        debugPrint('Attempting to sign in with email: $email');
      }
      
      // Validate input before attempting to sign in
      if (email.isEmpty) {
        _status = AuthStatus.error;
        _errorMessage = 'Please enter your email address';
        notifyListeners();
        throw Exception(_errorMessage);
      }
      
      if (password.isEmpty) {
        _status = AuthStatus.error;
        _errorMessage = 'Please enter your password';
        notifyListeners();
        throw Exception(_errorMessage);
      }
      
      // Authenticate with Firebase
      final userCredential = await _authService.signInWithEmailAndPassword(
        email, 
        password,
      );
      
      // If we get here, auth was successful
      final user = userCredential.user;
      
      if (user != null) {
        if (kDebugMode) {
          debugPrint('Successfully authenticated user: ${user.uid}');
        }
        
        try {
          // Try to fetch user data
          await _fetchUserData(user.uid);
          _status = AuthStatus.authenticated;
          // Clear any error messages on success
          _errorMessage = null;
          _errorCode = null;
        } catch (e) {
          // Create user document if not found
          if (kDebugMode) {
            debugPrint('Creating user document for new authentication: ${user.uid}');
          }
          
          final newUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            emailVerified: user.emailVerified, // Add email verification status
          );
          
          await _firestoreService.createUser(newUser);
          _user = newUser;
          _status = AuthStatus.authenticated;
          // Clear any error messages on success
          _errorMessage = null;
          _errorCode = null;
        }
        
        notifyListeners();
      } else {
        throw Exception('Login failed - no user returned');
      }
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Sign in error: $e');
      }
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> signUp(String email, String password, String displayName) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _errorCode = null;
      notifyListeners();
      
      // Validate input
      if (email.isEmpty) {
        _status = AuthStatus.error;
        _errorMessage = 'Please enter your email address';
        notifyListeners();
        throw Exception(_errorMessage);
      }
      
      if (password.isEmpty) {
        _status = AuthStatus.error;
        _errorMessage = 'Please enter a password';
        notifyListeners();
        throw Exception(_errorMessage);
      }
      
      if (displayName.isEmpty) {
        _status = AuthStatus.error;
        _errorMessage = 'Please enter your name';
        notifyListeners();
        throw Exception(_errorMessage);
      }
      
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      
      final user = userCredential.user;
      if (user != null) {
        // Update display name
        await _authService.updateUserProfile(displayName: displayName);
        
        // Send email verification
        await user.sendEmailVerification();
        
        // Create user document
        final newUser = UserModel(
          id: user.uid,
          email: user.email!,
          displayName: displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          emailVerified: false, // New users start with unverified email
        );
        
        await _firestoreService.createUser(newUser);
        
        // Clear any error messages on success
        _errorMessage = null;
        _errorCode = null;
        
        // Auth state changes listener will handle updating the status
      }
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> signOut() async {
    try {
      // Reset cached data on signout
      _lastUserReloadTime = null;
      _lastUserFetchTime = null;
      _errorMessage = null;
      _errorCode = null;
      
      await _authService.signOut();
      // Auth state changes listener will handle updating the status
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _handleError(e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      // Validate input
      if (email.isEmpty) {
        throw Exception('Please enter your email address');
      }
      
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _handleError(e);
      throw Exception(_errorMessage);
    }
  }
  
  // Future<void> updateProfile({String? displayName, String? photoUrl}) async {
  //   try {
  //     if (_user == null) return;
      
  //     // Update Firebase Auth profile
  //     await _authService.updateUserProfile(
  //       displayName: displayName,
  //       photoURL: photoUrl,
  //     );
      
  //     // Update Firestore user document
  //     final updatedUser = _user!.copyWith(
  //       displayName: displayName,
  //       photoUrl: photoUrl,
  //       updatedAt: DateTime.now(),
  //     );
      
  //     await _firestoreService.updateUser(updatedUser);
      
  //     // Update local user model
  //     _user = updatedUser;
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //     throw Exception(_errorMessage);
  //   }
  // }
  
  // // OPTIMIZED: Email verification with improved error handling
  // Future<void> sendEmailVerification() async {
  //   try {
  //     if (_firebaseUser == null) {
  //       throw Exception('No authenticated user found');
  //     }
      
  //     await _firebaseUser!.sendEmailVerification();
  //     if (kDebugMode) {
  //       debugPrint('Verification email sent to: ${_firebaseUser!.email}');
  //     }
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     if (kDebugMode) {
  //       debugPrint('Error sending verification email: $e');
  //     }
  //     throw Exception(_errorMessage);
  //   }
  // }
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
      _errorMessage = null;
      _errorCode = null;
      notifyListeners();
    } catch (e) {
      _handleError(e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
  
  Future<void> sendEmailVerification() async {
    try {
      if (_firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      await _firebaseUser!.sendEmailVerification();
      if (kDebugMode) {
        debugPrint('Verification email sent to: ${_firebaseUser!.email}');
      }
    } catch (e) {
      _handleError(e);
      if (kDebugMode) {
        debugPrint('Error sending verification email: $e');
      }
      throw Exception(_errorMessage);
    }
  }
  // OPTIMIZED: User reload with debounce and caching
  Future<void> reloadUser() async {
    // Prevent concurrent reloads
    if (_isReloadingUser) {
      if (kDebugMode) {
        debugPrint('🛑 Already reloading user, skipping duplicate request');
      }
      return;
    }
    
    // Check if we need to reload (cooldown period)
    final now = DateTime.now();
    if (_lastUserReloadTime != null && 
        now.difference(_lastUserReloadTime!).inSeconds < 15) {
      if (kDebugMode) {
        debugPrint('⏱️ Using cached user data (reloaded ${now.difference(_lastUserReloadTime!).inSeconds}s ago)');
      }
      return;
    }
    
    try {
      _isReloadingUser = true;
      
      if (_firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Reload the user to get the latest email verification status
      await _firebaseUser!.reload();
      _lastUserReloadTime = now;
      
      // Update the current Firebase user reference
      final freshUser = _authService.currentUser;
      if (freshUser != null) {
        _firebaseUser = freshUser;
        
        // If we have a user model, update its email verification status
        if (_user != null) {
          final updatedUser = _user!.copyWith(
            emailVerified: freshUser.emailVerified,
            updatedAt: now,
          );
          
          // Only update Firestore if verification status changed
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
          debugPrint('User reloaded. Email verified: ${freshUser.emailVerified}');
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('Error reloading user: $e');
      }
      throw Exception(_errorMessage);
    } finally {
      _isReloadingUser = false;
    }
  }
  
  Future<void> persistAuthState() async {
    if (_firebaseUser != null) {
      try {
        // Get the current user from Firebase Auth
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          _firebaseUser = currentUser;
          
          // Only fetch user data if we don't have it or it's stale
          if (_user == null || _lastUserFetchTime == null || 
              DateTime.now().difference(_lastUserFetchTime!).inMinutes > 5) {
            await _fetchUserData(currentUser.uid);
          }
          
          _status = AuthStatus.authenticated;
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error persisting auth state: $e');
        }
      }
    }
  }
  
  Future<void> reloadAuthState() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _firebaseUser = currentUser;
        _status = AuthStatus.authenticated;
        
        // Only fetch user data if we don't have it or it's stale
        if (_user == null || _lastUserFetchTime == null || 
            DateTime.now().difference(_lastUserFetchTime!).inMinutes > 5) {
          try {
            await _fetchUserData(currentUser.uid);
          } catch (e) {
            // If user document not found but we have Firebase auth,
            // consider them authenticated anyway
            if (kDebugMode) {
              debugPrint('Error fetching user data, but Firebase user exists: $e');
            }
          }
        }
        
        notifyListeners();
        if (kDebugMode) {
          debugPrint('Auth state reloaded: Authenticated');
        }
      } else {
        _status = AuthStatus.unauthenticated;
        _firebaseUser = null;
        _user = null;
        notifyListeners();
        if (kDebugMode) {
          debugPrint('Auth state reloaded: Unauthenticated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reloading auth state: $e');
      }
    }
  }
  
  /// Updates the user's business setup completion status
  Future<void> updateUserSetupStatus(bool hasCompleted) async {
    try {
      if (_user == null || _firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Update local user model first
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
      throw Exception(_errorMessage);
    }
  }
}