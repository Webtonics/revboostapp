// lib/core/utils/auth_error_handler.dart

class AuthErrorHandler {
  /// Get user-friendly error message from Firebase Auth exception
  static String getReadableAuthError(dynamic error) {
    if (error == null) return 'An unexpected error occurred';
    
    // Extract error code from different error types
    String? errorCode = _extractErrorCode(error);
    String errorMessage = error.toString();
    
    // If we have a code, use it for better messaging
    if (errorCode != null) {
      return _getMessageFromCode(errorCode);
    }
    
    // Fallback to parsing the error message
    return _parseErrorMessage(errorMessage);
  }
  
  /// Extract error code from various error formats
  static String? _extractErrorCode(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Firebase Auth exception patterns
    final patterns = [
      RegExp(r'\[firebase_auth/([^\]]+)\]'),
      RegExp(r'firebase_auth/([^\s,\]]+)'),
      RegExp(r'auth/([^\s,\]]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(errorString);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    
    return null;
  }
  
  /// Get user-friendly message from error code
  static String _getMessageFromCode(String code) {
    switch (code) {
      // Sign in errors
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'Your account has been temporarily disabled. Please contact support for assistance';
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'The email or password you entered is incorrect. Please try again';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please wait a few minutes before trying again';
      case 'network-request-failed':
        return 'Connection problem. Please check your internet connection and try again';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support';
        
      // Sign up errors
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in or use a different email';
      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger password with at least 8 characters';
      case 'missing-password':
        return 'Please enter a password';
      case 'missing-email':
        return 'Please enter an email address';
        
      // Password reset errors
      case 'expired-action-code':
        return 'This password reset link has expired. Please request a new one';
      case 'invalid-action-code':
        return 'This password reset link is invalid. Please request a new one';
      case 'user-token-expired':
        return 'Your session has expired. Please sign in again';
        
      // Email verification errors
      case 'invalid-verification-code':
        return 'The verification code is invalid';
      case 'invalid-verification-id':
        return 'The verification ID is invalid';
        
      // Account management errors
      case 'requires-recent-login':
        return 'For security reasons, please sign in again to complete this action';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials';
        
      // Generic errors
      case 'internal-error':
        return 'Something went wrong on our end. Please try again in a moment';
      case 'timeout':
        return 'The request timed out. Please check your connection and try again';
      case 'quota-exceeded':
        return 'Too many requests. Please wait a moment before trying again';
        
      default:
        return 'Authentication failed. Please try again';
    }
  }
  
  /// Parse error message for user-friendly content
  static String _parseErrorMessage(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();
    
    // Common error patterns and their friendly messages
    if (lowerMessage.contains('password') && lowerMessage.contains('wrong')) {
      return 'Incorrect password. Please try again';
    }
    
    if (lowerMessage.contains('email') && lowerMessage.contains('invalid')) {
      return 'Please enter a valid email address';
    }
    
    if (lowerMessage.contains('user') && lowerMessage.contains('not found')) {
      return 'No account found with this email address';
    }
    
    if (lowerMessage.contains('email') && lowerMessage.contains('already')) {
      return 'An account with this email already exists';
    }
    
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Connection problem. Please check your internet and try again';
    }
    
    if (lowerMessage.contains('timeout')) {
      return 'Request timed out. Please try again';
    }
    
    if (lowerMessage.contains('credential')) {
      return 'Invalid login credentials. Please check your email and password';
    }
    
    // If no specific pattern matches, return a generic friendly message
    return 'We couldn\'t sign you in right now. Please check your details and try again';
  }
  
  /// Check if error is related to network issues
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') || 
           errorString.contains('connection') ||
           errorString.contains('dns');
  }
  
  /// Check if error requires user action
  static bool requiresUserAction(dynamic error) {
    final errorCode = _extractErrorCode(error);
    if (errorCode == null) return true;
    
    final noActionCodes = [
      'network-request-failed',
      'internal-error',
      'timeout',
      'quota-exceeded',
    ];
    
    return !noActionCodes.contains(errorCode);
  }
  
  /// Get suggestion for resolving the error
  static String? getErrorSuggestion(dynamic error) {
    final errorCode = _extractErrorCode(error);
    if (errorCode == null) return null;
    
    switch (errorCode) {
      case 'wrong-password':
        return 'Try using the "Forgot Password" link to reset your password';
      case 'user-not-found':
        return 'Double-check your email address or create a new account';
      case 'too-many-requests':
        return 'Wait 15-30 minutes before attempting to sign in again';
      case 'network-request-failed':
        return 'Check your internet connection and try again';
      case 'weak-password':
        return 'Use a mix of letters, numbers, and symbols for a stronger password';
      case 'email-already-in-use':
        return 'Try signing in instead, or use the "Forgot Password" option';
      default:
        return null;
    }
  }
}