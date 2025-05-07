// lib/features/auth/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Use an alias for Firebase's AuthProvider
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// Your custom AuthProvider
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? mode;
  final String? oobCode;
  final String? continueUrl;
  final bool isHandlingActionUrl;

  const EmailVerificationScreen({
    Key? key, 
    this.mode,
    this.oobCode,
    this.continueUrl,
    this.isHandlingActionUrl = false,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResendingEmail = false;
  bool _isCheckingVerification = false;
  bool _isProcessingLink = false;
  bool _isVerified = false;
  String? _errorMessage;
  Timer? _timer;
  Timer? _cooldownTimer;
  int _timeLeft = 60;  // Cooldown timer for resending verification
  bool _navigationInProgress = false;
  bool _initialVerificationDone = false;

  @override
  void initState() {
    super.initState();
    
    // If we're handling a verification link
    if (widget.isHandlingActionUrl && widget.oobCode != null) {
      _processVerificationLink();
    } else {
      // Start with more frequent checks initially, then fall back to longer intervals
      _immediateVerificationCheck();
    }
  }

  void _immediateVerificationCheck() {
    // Check immediately after mounting
    _checkEmailVerification(initialCheck: true);
    
    // Check again after a short delay to catch quick verifications
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isVerified) {
        _checkEmailVerification();
      }
    });
    
    // Check again after a slightly longer delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isVerified) {
        _checkEmailVerification();
        // Now start the regular timer for ongoing checks
        _startVerificationCheckTimer();
      }
    });
  }

  void _startVerificationCheckTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    
    // Start a timer to periodically check if the email has been verified
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _processVerificationLink() async {
    if (_isProcessingLink) return;
    
    setState(() {
      _isProcessingLink = true;
      _errorMessage = null;
    });

    try {
      // Apply the verification code from the link
      if (widget.mode == 'verifyEmail' && widget.oobCode != null) {
        await firebase_auth.FirebaseAuth.instance.applyActionCode(widget.oobCode!);
        
        // Reload the user to get the updated verification status
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.reloadUser();
        
        // Get the updated verification status
        final user = authProvider.user;
        final isEmailVerified = user?.emailVerified ?? false;
        
        if (isEmailVerified) {
          setState(() {
            _isVerified = true;
            _isProcessingLink = false;
          });
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate after a brief delay
            _navigateAfterVerification();
          }
        } else {
          // This case handles when FirebaseAuth accepts the code but email isn't marked as verified
          setState(() {
            _errorMessage = 'Verification succeeded but email status was not updated. Please try refreshing.';
            _isProcessingLink = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify email: ${e.toString()}';
        _isProcessingLink = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // void _navigateAfterVerification() {
  //   if (!mounted || _navigationInProgress) return;
    
  //   _navigationInProgress = true;
    
  //   // Ensure we give the UI time to update before navigating
  //   Future.delayed(const Duration(milliseconds: 1500), () {
  //     if (mounted) {
  //       // Always use Splash as the target - the router will redirect appropriately
  //       context.go(AppRoutes.splash);
  //     }
  //   });
  // }
  void _navigateAfterVerification() {
  if (!mounted || _navigationInProgress) return;
  
  _navigationInProgress = true;
  
  // Ensure we give the UI time to update before navigating
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (mounted) {
      // Check if user has completed setup
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        // Check if business setup is completed
        final hasCompletedSetup = user.hasCompletedSetup ?? false;
        
        if (hasCompletedSetup) {
          // If setup is complete, go to dashboard
          context.go(AppRoutes.dashboard);
        } else {
          // If setup is not complete, go to onboarding
          context.go(AppRoutes.onboarding);
        }
      } else {
        // If no user is found (rare case), go to splash to handle redirection
        context.go(AppRoutes.splash);
      }
    }
  });
}

  Future<void> _sendVerificationEmail() async {
    if (_isResendingEmail) return;
    
    setState(() {
      _isResendingEmail = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendEmailVerification();
      
      // Start cooldown timer
      setState(() {
        _timeLeft = 60;
      });
      
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() {
            _timeLeft--;
          });
        } else {
          timer.cancel();
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // setState(() {
      //   _errorMessage = 'Failed to send verification email: ${e.toString()}';
      // });
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(_errorMessage!),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    } finally {
      setState(() {
        _isResendingEmail = false;
      });
    }
  }

  Future<void> _checkEmailVerification({bool initialCheck = false}) async {
    if (_isCheckingVerification || _isVerified || _navigationInProgress) return;
    
    setState(() {
      _isCheckingVerification = true;
    });
    
    try {
      // Force reload user in the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.reloadUser();
      
      // Get the updated verification status
      final user = authProvider.user;
      final isEmailVerified = user?.emailVerified ?? false;
      
      if (isEmailVerified) {
        _timer?.cancel();
        
        setState(() {
          _isVerified = true;
          _isCheckingVerification = false;
        });
        
        // Update this flag to avoid double sending
        if (initialCheck) {
          _initialVerificationDone = true;
        }
        
        _navigateAfterVerification();
      } else if (initialCheck && !_initialVerificationDone) {
        // First time check and not verified - send verification email
        _initialVerificationDone = true;
        await _sendVerificationEmail();
      }
    } catch (e) {
      // Silent error - we'll just try again next time
      debugPrint('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.user?.email ?? 'your email';
    final isEmailVerified = authProvider.user?.emailVerified ?? false;
    
    // If email is verified from provider or internal state
    if (_isVerified || isEmailVerified) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Email Verified!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your email has been successfully verified.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // ElevatedButton(
                //   onPressed: _navigationInProgress 
                //     ? null
                //     : () {
                //         _navigationInProgress = true;
                //         context.go(AppRoutes.splash); 
                //       },
                //   style: ElevatedButton.styleFrom(
                //     minimumSize: const Size(double.infinity, 50),
                //   ),
                //   child: _navigationInProgress
                //     ? const SizedBox(
                //         height: 20,
                //         width: 20,
                //         child: CircularProgressIndicator(strokeWidth: 2),
                //       )
                //     : const Text('Continue'),
                // ),
                ElevatedButton(
                  onPressed: _navigationInProgress 
                    ? null
                    : () {
                        _navigationInProgress = true;
                        // Call your navigation method instead of going to splash
                        _navigateAfterVerification();
                      },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _navigationInProgress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // If we're currently processing a verification link
    if (_isProcessingLink) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Email Verification'),
          // Prevent back navigation during verification
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text('Verifying your email...'),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Default state - waiting for verification
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        // Prevent back navigation for verification page
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              context.go(AppRoutes.login);
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:\n$email',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Please check your inbox and click the verification link to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isCheckingVerification
                    ? null
                    : () => _checkEmailVerification(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isCheckingVerification
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text('I\'ve Verified My Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_isResendingEmail || _timeLeft > 0)
                    ? null
                    : _sendVerificationEmail,
                child: _isResendingEmail
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : _timeLeft > 0
                        ? Text('Resend Email (${_timeLeft}s)')
                        : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Didn\'t receive an email? Check your spam folder or try resending.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}