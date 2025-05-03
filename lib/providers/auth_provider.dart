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
  
  // Performance optimization: Tracking timestamps for caching and debouncing
  DateTime? _lastUserReloadTime;
  DateTime? _lastUserFetchTime;
  bool _isReloadingUser = false;
  bool _isFetchingUser = false;
  
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
              if (kDebugMode) {
                debugPrint('Created new user document and authenticated');
              }
            } catch (createError) {
              _status = AuthStatus.error;
              _errorMessage = 'Failed to create user profile: $createError';
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
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('Error in auth initialization: $e');
      }
      notifyListeners();
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
      notifyListeners();
      
      // Log authentication attempt
      if (kDebugMode) {
        debugPrint('Attempting to sign in with email: $email');
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
        }
        
        notifyListeners();
      } else {
        throw Exception('Login failed - no user returned');
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
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
      notifyListeners();
      
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
      // Reset cached data on signout
      _lastUserReloadTime = null;
      _lastUserFetchTime = null;
      
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
  
  // OPTIMIZED: Email verification with improved error handling
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
      _errorMessage = e.toString();
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