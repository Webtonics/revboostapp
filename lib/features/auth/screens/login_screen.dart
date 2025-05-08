// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/theme_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // In _handleLogin of LoginScreen
// Future<void> _handleLogin() async {
//   if (!_formKey.currentState!.validate()) {
//     return;
//   }

//   setState(() {
//     _isLoading = true;
//     _errorMessage = null;
//   });

//   try {
//     await Provider.of<AuthProvider>(context, listen: false).signIn(
//       _emailController.text.trim(),
//       _passwordController.text,
//     );
//     // Don't do anything here - the router will handle navigation
//   } catch (e) {
//     setState(() {
//       _errorMessage = e.toString();
//       _isLoading = false;
//     });
//   }
// }
// In LoginScreen's _handleLogin method
// In your login screen's _handleLogin method:

Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Attempt login
    await Provider.of<AuthProvider>(context, listen: false).signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    // Check auth status after login attempt
    if (mounted) {
      final authStatus = Provider.of<AuthProvider>(context, listen: false).status;
      
      if (authStatus == AuthStatus.authenticated) {
        // Set the flag to trigger email verification check in the router
        // AppRouter.setJustLoggedIn();
        debugPrint('Login successful - marked user as just logged in');
        
        // Navigate to dashboard - router will handle redirection to verification if needed
        context.go(AppRoutes.dashboard);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication failed';
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
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
                      // Logo and App name
                      Column(
                        children: [
                          Image.asset(
                            theme.isDarkMode  ? 'assets/splash_logo_dark.png' : 'assets/splash_logo_light.png', 
                          
                          width: 100, height: 100),
                          const SizedBox(height: 16),
                          Text(
                            'RevBoostApp',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your account',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Error message if there is one
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Login form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
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
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  context.go(AppRoutes.forgotPassword);
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Login button
                            AppButton(
                              text: 'Sign In',
                              onPressed: _handleLogin,
                              fullWidth: true,
                              size: AppButtonSize.large,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Or divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Sign in with Google button
                            // OutlinedButton.icon(
                            //   onPressed: () {
                            //     // Implement Google Sign In
                            //   },
                            //   icon: Image.asset(
                            //     'assets/icons/google_icon.png',
                            //     height: 18,
                            //   ),
                            //   label: const Text('Sign in with Google'),
                            //   style: OutlinedButton.styleFrom(
                            //     padding: const EdgeInsets.symmetric(vertical: 12),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              context.go(AppRoutes.register);
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
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