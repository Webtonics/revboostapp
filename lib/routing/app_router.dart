// lib/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/auth/screens/email_verification_screen.dart';
import 'package:revboostapp/features/auth/screens/forgot_password_screen.dart';
import 'package:revboostapp/features/auth/screens/login_screen.dart';
import 'package:revboostapp/features/auth/screens/register_screen.dart';
import 'package:revboostapp/features/auth/screens/reset_password_screen.dart';
import 'package:revboostapp/features/business_setup/screens/business_setup_screen.dart';
import 'package:revboostapp/features/dashboard/screens/dashboard_screen.dart';
import 'package:revboostapp/features/feedback/screens/feedback_screen.dart';
import 'package:revboostapp/features/onboarding/screens/onboarding_screen.dart';
import 'package:revboostapp/features/qr_code/screens/qr_code_screen.dart';
import 'package:revboostapp/features/review_requests/screens/review_requests_screen.dart';
import 'package:revboostapp/features/reviews/screens/public_review_screen.dart';
import 'package:revboostapp/features/settings/settings_screen.dart';
import 'package:revboostapp/features/splash/screens/splash_screen.dart';
import 'package:revboostapp/features/subscription/screens/subscription_screen.dart';
import 'package:revboostapp/features/subscription/screens/subscription_success_screen.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/widgets/layout/app_bar_with_theme_toggle.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';

/// Defines all application routes
class AppRoutes {
  // Public routes (accessible without auth)
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String authAction = '/auth/action';
  static const String reviewPage = '/r/:businessId';
  static const String resetPassword = '/reset-password';

  // Auth-required routes
  static const String emailVerification = '/email-verification';
  static const String onboarding = '/onboarding';
  static const String businessSetup = '/business-setup';
  
  // Main application routes (require auth and setup)
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String feedback = '/feedback';
  
  // Premium routes (require subscription)
  static const String reviewRequests = '/review-requests';
  static const String contacts = '/contacts';
  static const String qrCode = '/qr-code';
  static const String templates = '/templates';
  static const String subscription = '/subscription';
  static const String subscriptionSuccess = '/subscription/success';
  
  // Returns all public routes that don't require authentication
  static final List<String> publicRoutes = [
    splash,
    login,
    register,
    forgotPassword,
    authAction,
    resetPassword,
    reviewPage,
  ];

  // Routes that are accessible without email verification
  static final List<String> noVerificationRequiredRoutes = [
    ...publicRoutes,
    emailVerification,
  ];

  // Routes that require subscription or free trial
  static final List<String> premiumRoutes = [
    reviewRequests,
    contacts,
    qrCode,
    templates,
  ];
  
  // Returns true if the route starts with a path segment that matches a public review page
  static bool isPublicReviewRoute(String path) {
    return path.startsWith('/r/');
  }
}

/// Placeholder screen for routes still under development
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithThemeToggle(title: title),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<AuthProvider>().signOut();
                context.go(AppRoutes.splash);
              },
              child: const Text('Sign Out (Test)'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified router configuration for the application
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  // Improved redirect state management
  static bool _isRedirecting = false;
  static DateTime _lastRedirectTime = DateTime.now().subtract(const Duration(seconds: 1));
  
  // Track if we're coming from registration flow to prevent premature dashboard redirection
  static bool _isAfterRegistration = false;
  
  // Track subscription status check to avoid redirect loops
  static Map<String, bool> _subscriptionCheckCache = {};
  
  /// Get the configured GoRouter instance
  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode, // Only enable in debug mode
      
      /// Redirect logic with fixed issue handling
      redirect: (context, state) async {
        final currentPath = state.uri.path;
        final now = DateTime.now();
        
        // Skip redirect if already redirecting but only if very recent
        if (_isRedirecting && now.difference(_lastRedirectTime).inMilliseconds < 300) {
          return null;
        }
        
        _isRedirecting = true;
        _lastRedirectTime = now;
        
        try {
          // Clear the subscription check cache for non-premium routes
          // This ensures we always check subscription status on premium route navigation
          if (!AppRoutes.premiumRoutes.contains(currentPath)) {
            _subscriptionCheckCache.clear();
          }
          
          // Get auth state
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final isAuthenticated = authProvider.status == AuthStatus.authenticated;
          final user = authProvider.user;
          
          // Debug logging
          debugPrint('Router check: path=$currentPath, authenticated=$isAuthenticated');
          
          // Skip all redirects for splash screen - let the splash handle navigation
          if (currentPath == AppRoutes.splash) {
            return null;
          }
          
          // Handle public routes
          final isPublicRoute = AppRoutes.publicRoutes.contains(currentPath) || 
                               AppRoutes.isPublicReviewRoute(currentPath);
          
          // Skip redirects for public review pages
          if (AppRoutes.isPublicReviewRoute(currentPath)) {
            return null;
          }
          
          // If not authenticated, redirect to login (unless on a public route)
          if (!isAuthenticated) {
            debugPrint('User not authenticated, redirecting to: ${isPublicRoute ? 'staying on public route' : AppRoutes.login}');
            
            // Reset registration flow tracking when logging out
            _isAfterRegistration = false;
            
            return isPublicRoute ? null : AppRoutes.login;
          }

          // Add this special case for sign-out from dashboard-related pages
          if (!isAuthenticated && 
              (currentPath.startsWith(AppRoutes.dashboard) || 
              currentPath.startsWith(AppRoutes.settings) || 
              currentPath == '/' || 
              currentPath.contains('/dashboard'))) {
            debugPrint('⚠️ Special case: User not authenticated on protected route - forcing login redirect');
            return AppRoutes.login;
          }
          
          // From here, user is authenticated
          
          // If on login or register page, redirect appropriately based on setup status
          if (currentPath == AppRoutes.login || currentPath == AppRoutes.register) {
            // Check if user just registered (this flag is set in the RegisterScreen)
            if (_isAfterRegistration) {
              debugPrint('User just registered, directing to onboarding flow');
              _isAfterRegistration = false; // Reset the flag
              return AppRoutes.onboarding;
            }
            
            // For normal login, check setup status
            final businessSetupCompleted = user?.hasCompletedSetup ?? false;
            
            if (!businessSetupCompleted) {
              debugPrint('User logged in but needs to complete setup, directing to onboarding');
              return AppRoutes.onboarding;
            }
            
            debugPrint('User logged in with completed setup, directing to dashboard');
            return AppRoutes.dashboard;
          }
          
          // Email verification check
          final isEmailVerified = user?.emailVerified ?? false;
          
          // Need email verification
          if (!isEmailVerified && !AppRoutes.noVerificationRequiredRoutes.contains(currentPath)) {
            debugPrint('Email not verified, redirecting to verification screen');
            return AppRoutes.emailVerification;
          }
          
          // Business setup check
          final businessSetupCompleted = user?.hasCompletedSetup ?? false;
          
          if (!businessSetupCompleted) {
            if (currentPath != AppRoutes.onboarding && currentPath != AppRoutes.businessSetup) {
              debugPrint('Business setup not completed, redirecting to onboarding');
              return AppRoutes.onboarding;
            }
          } else if (currentPath == AppRoutes.onboarding) {
            // Skip onboarding if setup is already complete
            debugPrint('Setup already complete, skipping onboarding');
            return AppRoutes.dashboard;
          }
          
          // Subscription check (only for premium routes)
          if (AppRoutes.premiumRoutes.contains(currentPath)) {
            // Check if we've already verified subscription status for this route
            // to prevent redirect loops
            if (!_subscriptionCheckCache.containsKey(currentPath)) {
              final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
              
              // Force refresh subscription status on first premium route access
              await subscriptionProvider.refreshSubscriptionStatus();
              
              final hasActiveSubscription = subscriptionProvider.isSubscribed;
              final isFreeTrial = subscriptionProvider.isFreeTrial;
              
              // Cache the result to prevent loops
              _subscriptionCheckCache[currentPath] = hasActiveSubscription || isFreeTrial;
              
              debugPrint('Premium route check: hasSubscription=$hasActiveSubscription, isFreeTrial=$isFreeTrial');
              
              if (!hasActiveSubscription && !isFreeTrial) {
                debugPrint('No active subscription, redirecting to subscription page');
                return AppRoutes.subscription;
              }
            } else {
              // Use cached result
              if (!_subscriptionCheckCache[currentPath]!) {
                debugPrint('Using cached subscription check: no subscription');
                return AppRoutes.subscription;
              }
            }
          }
          
          // Allow the navigation
          return null;
        } catch (e) {
          debugPrint('Router error: $e');
          return null;
        } finally {
          // Reset redirecting flag with a slight delay
          Future.delayed(const Duration(milliseconds: 200), () {
            _isRedirecting = false;
          });
        }
      },
      
      // Define all application routes
      routes: [
        // PUBLIC ROUTES
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) {
            // Wrap the RegisterScreen in a builder that can set the registration flag
            return RegisterScreen(
              onRegisterSuccess: () {
                // Set the flag when registration is successful
                _isAfterRegistration = true;
                debugPrint('Registration successful, setting flag for onboarding flow');
              },
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        
        // AUTHENTICATION FLOW ROUTES
        GoRoute(
          path: AppRoutes.emailVerification,
          builder: (context, state) {
            // Extract query parameters for direct verification links
            final mode = state.uri.queryParameters['mode'];
            final oobCode = state.uri.queryParameters['oobCode'];
            final continueUrl = state.uri.queryParameters['continueUrl'];
            
            // If this is a direct verification link, pass the parameters
            if (mode == 'verifyEmail' && oobCode != null) {
              return EmailVerificationScreen(
                mode: mode,
                oobCode: oobCode,
                continueUrl: continueUrl,
                isHandlingActionUrl: true,
              );
            }
            
            // Standard email verification screen
            return const EmailVerificationScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.authAction,
          builder: (context, state) {
            // Extract parameters
            final mode = state.uri.queryParameters['mode'];
            final oobCode = state.uri.queryParameters['oobCode'];
            final continueUrl = state.uri.queryParameters['continueUrl'];
            
            // Log debug info
            debugPrint('Auth action handling: mode=$mode, code=${oobCode != null ? 'present' : 'missing'}');
            
            // Handle each auth action mode
            if (mode == 'verifyEmail' && oobCode != null) {
              return EmailVerificationScreen(
                mode: mode,
                oobCode: oobCode,
                continueUrl: continueUrl,
                isHandlingActionUrl: true,
              );
            } else if (mode == 'resetPassword' && oobCode != null) {
              return ResetPasswordScreen(
                mode: mode,
                oobCode: oobCode,
                continueUrl: continueUrl,
              );
            }
            
            // Fall back to error screen for invalid parameters
            return Scaffold(
              appBar: AppBar(title: const Text('Authentication')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Invalid or expired action link'),
                    if (kDebugMode) Text('Debug info: mode=$mode, oobCode=${oobCode?.substring(0, min(5, oobCode.length)) ?? "null"}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Return to Login'),
                    )
                  ],
                ),
              ),
            );
          },
        ),
        
        // MAIN APP ROUTES - Use shell route for shared layout
        ShellRoute(
          builder: (context, state, child) {
            // Get title from the route or use a default
            final path = state.uri.path;
            String title = 'RevBoost';
            
            if (path.contains(AppRoutes.dashboard)) title = 'Dashboard';
            else if (path.contains(AppRoutes.settings)) title = 'Settings';
            else if (path.contains(AppRoutes.feedback)) title = 'Feedback';
            else if (path.contains(AppRoutes.reviewRequests)) title = 'Review Requests';
            else if (path.contains(AppRoutes.contacts)) title = 'Contacts';
            else if (path.contains(AppRoutes.qrCode)) title = 'QR Code';
            else if (path.contains(AppRoutes.templates)) title = 'Templates';
            
            // Skip the shell for certain paths that should have their own layout
            if (path == AppRoutes.onboarding || 
                path == AppRoutes.businessSetup ||
                path == AppRoutes.subscription ||
                path == AppRoutes.subscriptionSuccess ||
                AppRoutes.isPublicReviewRoute(path)) {
              return child;
            }
            
            // Apply the common layout to main app routes
            return AppLayout(
              title: title,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: AppRoutes.feedback,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const BusinessFeedbackPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: AppRoutes.reviewRequests,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ReviewRequestsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
              onExit: (context) {
                // Clear subscription cache when exiting this route
                _subscriptionCheckCache.remove(AppRoutes.reviewRequests);
                return true;
              },
            ),
            GoRoute(
              path: AppRoutes.contacts,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PlaceholderScreen(title: 'Contacts'),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
              onExit: (context) {
                // Clear subscription cache when exiting this route
                _subscriptionCheckCache.remove(AppRoutes.contacts);
                return true;
              },
            ),
            GoRoute(
              path: AppRoutes.qrCode,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const QrCodeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
              onExit: (context) {
                // Clear subscription cache when exiting this route
                _subscriptionCheckCache.remove(AppRoutes.qrCode);
                return true;
              },
            ),
            GoRoute(
              path: AppRoutes.templates,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PlaceholderScreen(title: 'Templates'),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
              onExit: (context) {
                // Clear subscription cache when exiting this route
                _subscriptionCheckCache.remove(AppRoutes.templates);
                return true;
              },
            ),
          ],
        ),
        
        // Non-Shell Routes (need their own layout)
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'];
            final oobCode = state.uri.queryParameters['oobCode'];
            final continueUrl = state.uri.queryParameters['continueUrl'];
            
            return ResetPasswordScreen(
              mode: mode,
              oobCode: oobCode,
              continueUrl: continueUrl,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.businessSetup,
          builder: (context, state) => const BusinessSetupScreen(),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          builder: (context, state) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: AppRoutes.subscriptionSuccess,
          builder: (context, state) {
            String? planId;
            
            if (state.extra != null && state.extra is Map) {
              final extras = state.extra as Map;
              planId = extras['planId'] as String?;
            }
            
            planId ??= state.uri.queryParameters['planId'];
            
            return SubscriptionSuccessScreen(planId: planId);
          },
        ),
        
        // PUBLIC REVIEW PAGE
        GoRoute(
          path: AppRoutes.reviewPage,
          builder: (context, state) {
            final businessId = state.pathParameters['businessId'] ?? '';
            return PublicReviewScreen(businessId: businessId);
          },
        ),
      ],
      
      // Error handler for routes that don't match
      errorBuilder: (context, state) {
        debugPrint('Route not found: ${state.uri}');
        return Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('The page "${state.uri}" could not be found.', 
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Helper method for string minimum length
  static int min(int a, int b) => a < b ? a : b;
}