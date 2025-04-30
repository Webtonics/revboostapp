// lib/features/auth/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? oobCode;
  final String? mode;
  final String? continueUrl;

  const ResetPasswordScreen({
    Key? key,
    this.oobCode,
    this.mode,
    this.continueUrl,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isProcessingLink = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  String? _email;

  @override
  void initState() {
    super.initState();
    _verifyResetCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Verify the password reset code is valid
  Future<void> _verifyResetCode() async {
    if (widget.oobCode == null || widget.mode != 'resetPassword') {
      setState(() {
        _errorMessage = 'Invalid password reset link. Please request a new one.';
      });
      return;
    }

    setState(() {
      _isProcessingLink = true;
      _errorMessage = null;
    });

    try {
      // Verify the password reset code and get the associated email
      final authResult = await firebase_auth.FirebaseAuth.instance
          .verifyPasswordResetCode(widget.oobCode!);
      
      setState(() {
        _email = authResult;
        _isProcessingLink = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'This password reset link is invalid or has expired. Please request a new one.';
        _isProcessingLink = false;
      });
    }
  }

  // Handle the password reset submission
  Future<void> _handleSubmitNewPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Confirm passwords match (though we already validate this in the form)
      if (_passwordController.text != _confirmPasswordController.text) {
        throw Exception('Passwords do not match.');
      }

      // Complete the password reset using the oobCode
      await firebase_auth.FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode!,
        newPassword: _passwordController.text,
      );

      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isProcessingLink,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon and title
                      Icon(
                        Icons.lock_reset_rounded,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Reset Password',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),

                      // Processing Link Indicator
                      if (_isProcessingLink) ...[
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Verifying your reset link...'),
                            ],
                          ),
                        ),
                      ]
                      // Error message
                      else if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                text: 'Request New Reset Link',
                                onPressed: () {
                                  context.go(AppRoutes.forgotPassword);
                                },
                                fullWidth: true,
                              ),
                            ],
                          ),
                        ),
                      ]
                      // Success state
                      else if (_isSuccess) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Password Reset Successful',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your password has been successfully reset. You can now log in with your new password.',
                                style: TextStyle(
                                  color: AppColors.success,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          text: 'Go to Login',
                          onPressed: () {
                            context.go(AppRoutes.login);
                          },
                          fullWidth: true,
                          size: AppButtonSize.large,
                        ),
                      ]
                      // Password reset form 
                      else if (_email != null) ...[
                        Text(
                          'Create a new password for $_email',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  hintText: 'Enter your new password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Confirm password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  hintText: 'Confirm your new password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              
                              // Submit button
                              AppButton(
                                text: 'Reset Password',
                                onPressed: _handleSubmitNewPassword,
                                fullWidth: true,
                                size: AppButtonSize.large,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Cancel button
                              TextButton(
                                onPressed: () {
                                  context.go(AppRoutes.login);
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}