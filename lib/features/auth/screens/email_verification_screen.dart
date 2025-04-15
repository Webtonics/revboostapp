// lib/features/auth/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResendingEmail = false;
  bool _isCheckingVerification = false;
  Timer? _timer;
  int _timeLeft = 60;  // Cooldown timer for resending verification

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    // Start a timer to periodically check if the email has been verified
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isResendingEmail = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendEmailVerification();
      
      // Start cooldown timer
      setState(() {
        _timeLeft = 60;
      });
      
      Timer.periodic(const Duration(seconds: 1), (timer) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResendingEmail = false;
      });
    }
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;
    
    setState(() {
      _isCheckingVerification = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.reloadUser();
      
      if (authProvider.user?.emailVerified ?? false) {
        _timer?.cancel();
        // Email is verified, redirect to the next appropriate screen
        // The redirect logic in the router will handle where to go next
        context.go(AppRoutes.splash);
      }
    } catch (e) {
      // Silent error - we'll just try again next time
    } finally {
      setState(() {
        _isCheckingVerification = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.user?.email ?? 'your email';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
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
              const SizedBox(height: 24),
              Text(
                'Please check your inbox and click the verification link to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isCheckingVerification
                    ? null
                    : _checkEmailVerification,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isCheckingVerification
                    ? const CircularProgressIndicator()
                    : const Text('I\'ve Verified My Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_isResendingEmail || _timeLeft > 0)
                    ? null
                    : _sendVerificationEmail,
                child: _isResendingEmail
                    ? const CircularProgressIndicator(strokeWidth: 2)
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