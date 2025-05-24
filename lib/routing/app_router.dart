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
  ];

  // Routes that are accessible without email verification
  static final List<String> noVerificationRequiredRoutes = [
    ...publicRoutes,
    emailVerification,
    onboarding,
    businessSetup,
    dashboard,
    settings,
    subscription,
    subscriptionSuccess,
  ];

  // Routes that require subscription or free trial
  static final List<String> premiumRoutes = [
    reviewRequests,
    contacts,
    qrCode,
    templates,
  ];
  
  // Routes that require completed business setup
  static final List<String> setupRequiredRoutes = [
    dashboard,
    settings,
    feedback,
    reviewRequests,
    contacts,
    qrCode,
    templates,
    subscription,
    subscriptionSuccess,
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
  
  // Simple redirect throttling - prevent rapid redirects
  static DateTime _lastRedirectTime = DateTime.now().subtract(const Duration(seconds: 10));
  
  /// Get the configured GoRouter instance
  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode,
      
      /// Simplified redirect logic that focuses on core flows
      redirect: (context, state) async {
        final currentPath = state.uri.path;
        final now = DateTime.now();
        
        // Throttle redirects to prevent infinite loops
        if (now.difference(_lastRedirectTime).inMilliseconds < 100) {
          return null;
        }
        _lastRedirectTime = now;
        
        if (kDebugMode) {
          debugPrint('🔄 Router redirect check: $currentPath');
        }
        
        try {
          // Always allow public routes and review pages
          if (AppRoutes.publicRoutes.contains(currentPath) || 
              AppRoutes.isPublicReviewRoute(currentPath)) {
            if (kDebugMode) {
              debugPrint('✅ Public route allowed: $currentPath');
            }
            return null;
          }
          
          // Get auth state
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final authStatus = authProvider.status;
          final user = authProvider.user;
          
          if (kDebugMode) {
            debugPrint('🔐 Auth status: $authStatus, User: ${user?.email}');
          }
          
          // Handle authentication loading state
          if (authStatus == AuthStatus.loading || authStatus == AuthStatus.initial) {
            if (kDebugMode) {
              debugPrint('⏳ Auth loading, staying on current route');
            }
            return null; // Stay on current route while loading
          }
          
          // Handle unauthenticated users
          if (authStatus != AuthStatus.authenticated || user == null) {
            if (kDebugMode) {
              debugPrint('❌ Not authenticated, redirecting to login');
            }
            return AppRoutes.login;
          }
          
          // From here, user is authenticated
          if (kDebugMode) {
            debugPrint('✅ User authenticated: ${user.email}');
            debugPrint('📧 Email verified: ${user.emailVerified}');
            debugPrint('🏢 Setup completed: ${user.hasCompletedSetup}');
          }
          
          // Handle business setup flow
          if (!user.hasCompletedSetup) {
            // Allow setup-related routes
            if (currentPath == AppRoutes.onboarding || 
                currentPath == AppRoutes.businessSetup ||
                currentPath == AppRoutes.emailVerification) {
              if (kDebugMode) {
                debugPrint('✅ Setup route allowed: $currentPath');
              }
              return null;
            }
            
            // Redirect to onboarding for any other route
            if (kDebugMode) {
              debugPrint('🔄 Setup not complete, redirecting to onboarding');
            }
            return AppRoutes.onboarding;
          }
          
          // Handle subscription check for premium routes
          if (AppRoutes.premiumRoutes.contains(currentPath)) {
            final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
            
            // Only check subscription if we have valid subscription data
            if (subscriptionProvider.subscriptionStatus.isActive || 
                subscriptionProvider.isFreeTrial) {
              if (kDebugMode) {
                debugPrint('✅ Premium route allowed: $currentPath');
              }
              return null;
            } else {
              if (kDebugMode) {
                debugPrint('💰 No subscription, redirecting to subscription page');
              }
              return AppRoutes.subscription;
            }
          }
          
          // Allow all other authenticated routes
          if (kDebugMode) {
            debugPrint('✅ Route allowed: $currentPath');
          }
          return null;
          
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Router error: $e');
          }
          // On error, allow the route to prevent infinite redirects
          return null;
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
          builder: (context, state) => const RegisterScreen(),
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
        
        // SETUP FLOW ROUTES
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.businessSetup,
          builder: (context, state) => const BusinessSetupScreen(),
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
            if (path == AppRoutes.subscription ||
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
            ),
          ],
        ),
        
        // SUBSCRIPTION ROUTES (outside shell for custom layout)
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
        
        // RESET PASSWORD ROUTE
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
        if (kDebugMode) {
          debugPrint('❌ Route not found: ${state.uri}');
        }
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
}