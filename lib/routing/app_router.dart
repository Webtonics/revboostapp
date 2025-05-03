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

/// Unified router configuration for the application - OPTIMIZED VERSION
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  // Improved redirect control with debounce
  static bool _isRedirecting = false;
  static DateTime _lastRedirectTime = DateTime.now().subtract(const Duration(seconds: 1));
  
  // Cache the last path to avoid redundant checks
  static String? _lastCheckedPath;
  static String? _lastRedirectResult;
  
  // Cache timestamps for critical reload operations
  static DateTime? _lastUserReloadTime;
  static DateTime? _lastSubscriptionCheckTime;
  
  /// Get the configured GoRouter instance
  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode, // Only enable in debug mode
      
      /// Optimized redirect logic with caching and minimal reloads
      redirect: (context, state) async {
        // More robust redirect prevention with caching
        final now = DateTime.now();
        final currentPath = state.uri.path;
        
        // Quick return if we recently checked this exact path with the same result
        if (currentPath == _lastCheckedPath && 
            now.difference(_lastRedirectTime).inMilliseconds < 2000) {
          debugPrint('🔄 Using cached redirect result for: $currentPath');
          return _lastRedirectResult;
        }
        
        // Prevent redirect loops with improved debounce
        if (_isRedirecting && now.difference(_lastRedirectTime).inMilliseconds < 300) {
          debugPrint('❌ Skipping redirect - already in progress');
          return null;
        }
        
        _isRedirecting = true;
        _lastRedirectTime = now;
        _lastCheckedPath = currentPath;
        String? redirectPath;
        
        try {
          // Extract providers without triggering rebuilds
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
  
          // Debug logging only in debug mode
          if (kDebugMode) {
            _logRouteAttempt(currentPath, state.uri);
          }
          
          // Skip redirect for special cases
          if (_shouldSkipRedirect(authProvider, currentPath)) {
            _lastRedirectResult = null;
            return null;
          }
          
          // AUTHENTICATION CHECK - Simplified
          final isAuthenticated = authProvider.status == AuthStatus.authenticated;
          final user = authProvider.user;
          final isPublicRoute = AppRoutes.publicRoutes.contains(currentPath) || 
                               AppRoutes.isPublicReviewRoute(currentPath);
          
          // Not logged in -> redirect to login unless on a public route
          if (!isAuthenticated) {
            _lastRedirectResult = isPublicRoute ? null : AppRoutes.login;
            return _lastRedirectResult;
          }
          
          // User is authenticated but on a public route (login, register, etc.)
          if (isPublicRoute && currentPath != AppRoutes.splash) {
            _lastRedirectResult = AppRoutes.splash;
            return _lastRedirectResult;
          }
          
          // EMAIL VERIFICATION CHECK - Only reload when necessary
          final shouldReloadUser = _shouldReloadUser(currentPath);
          if (shouldReloadUser) {
            await authProvider.reloadUser();
          }
          
          final isEmailVerified = user?.emailVerified ?? false;
          
          // If on verification screen but already verified, move forward
          if (currentPath == AppRoutes.emailVerification && isEmailVerified) {
            redirectPath = await _determineNextPathInFlow(user!, context);
            debugPrint('⚡ Email already verified, moving to next flow step: $redirectPath');
            _lastRedirectResult = redirectPath;
            return redirectPath;
          }
          
          // Enforce verification for protected routes
          if (!isEmailVerified && !AppRoutes.noVerificationRequiredRoutes.contains(currentPath)) {
            debugPrint('⚡ Redirecting to email verification: email not verified');
            _lastRedirectResult = AppRoutes.emailVerification;
            return _lastRedirectResult;
          }
          
          // If on splash and authenticated, determine next appropriate screen
          if (currentPath == AppRoutes.splash) {
            redirectPath = await _determineNextPathInFlow(user!, context);
            debugPrint('⚡ Splash redirect decision: $redirectPath');
            _lastRedirectResult = redirectPath;
            return redirectPath;
          }
          
          // BUSINESS SETUP & ONBOARDING FLOW - Simplified
          final businessSetupCompleted = user?.hasCompletedSetup ?? false;
          
          // If business setup is not completed
          if (!businessSetupCompleted) {
            if (currentPath != AppRoutes.onboarding && currentPath != AppRoutes.businessSetup) {
              debugPrint('⚡ Redirecting to onboarding: business setup not completed');
              _lastRedirectResult = AppRoutes.onboarding;
              return _lastRedirectResult;
            }
          } else {
            if (currentPath == AppRoutes.onboarding || currentPath == AppRoutes.businessSetup) {
              debugPrint('⚡ Business setup completed, redirecting to dashboard');
              _lastRedirectResult = AppRoutes.dashboard;
              return _lastRedirectResult;
            }
          }
          
          // SUBSCRIPTION CHECK - Only for premium routes and only when necessary
          if (AppRoutes.premiumRoutes.contains(currentPath)) {
            // Check if we need to reload subscription status
            final shouldCheckSubscription = _shouldCheckSubscription();
            
            if (shouldCheckSubscription) {
              await subscriptionProvider.reloadSubscriptionStatus();
              _lastSubscriptionCheckTime = DateTime.now();
            }
            
            final hasActiveSubscription = subscriptionProvider.isSubscribed;
            final isFreeTrial = subscriptionProvider.isFreeTrial;
            
            if (!hasActiveSubscription && !isFreeTrial) {
              debugPrint('Premium route access attempted without subscription: $currentPath');
              _lastRedirectResult = AppRoutes.subscription;
              return _lastRedirectResult;
            }
          }
          
          // Allow access to the requested route if all checks pass
          _lastRedirectResult = null;
          return null;
        } catch (e) {
          debugPrint('❌ Error in redirect logic: $e');
          _lastRedirectResult = null;
          return null; // In case of error, don't redirect to avoid loops
        } finally {
          // Reset the redirect flag with a slight delay
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

  /// Determine the next appropriate route in the user flow - OPTIMIZED
  static Future<String> _determineNextPathInFlow(dynamic user, BuildContext context) async {
    // Check if business setup is completed
    final businessSetupCompleted = user.hasCompletedSetup ?? false;
    
    // Email verification check
    if (!(user.emailVerified ?? false)) {
      return AppRoutes.emailVerification;
    }
    
    // After email verification, check business setup status
    if (!businessSetupCompleted) {
      return AppRoutes.onboarding;
    }
    
    // All steps completed, go to dashboard
    return AppRoutes.dashboard;
  }

  /// Check if we should skip the redirect logic for certain routes
  static bool _shouldSkipRedirect(AuthProvider authProvider, String currentPath) {
    // Skip if auth is loading
    if (authProvider.status == AuthStatus.loading || 
        authProvider.status == AuthStatus.initial) {
      return true;
    }
    
    // Skip for public review pages
    if (AppRoutes.isPublicReviewRoute(currentPath)) {
      debugPrint('Public review route - skipping auth checks');
      return true;
    }
    
    return false;
  }
  
  /// New method to determine if user reload is necessary
  static bool _shouldReloadUser(String currentPath) {
    // These paths definitely need fresh user data
    final criticalPaths = [
      AppRoutes.emailVerification,
      AppRoutes.onboarding,
      AppRoutes.businessSetup,
    ];
    
    if (criticalPaths.contains(currentPath)) {
      return true;
    }
    
    // Avoid frequent reloads with a cooldown period
    if (_lastUserReloadTime != null) {
      final timeSinceLastReload = DateTime.now().difference(_lastUserReloadTime!);
      // Only reload if it's been at least 30 seconds since last reload
      if (timeSinceLastReload.inSeconds < 30) {
        return false;
      }
    }
    
    // No recent reload, so a reload is needed
    return true;
  }
  
  /// New method to check if subscription status needs to be reloaded
  static bool _shouldCheckSubscription() {
    if (_lastSubscriptionCheckTime == null) {
      return true; // First check
    }
    
    final timeSinceLastCheck = DateTime.now().difference(_lastSubscriptionCheckTime!);
    // Only check subscription if it's been at least 5 minutes
    return timeSinceLastCheck.inMinutes >= 5;
  }
  
  /// Helper method to log route navigation attempts for debugging
  static void _logRouteAttempt(String path, Uri uri) {
    debugPrint('⚡ Route requested: $path (${uri.toString()})');
  }
  
  /// Helper method for string minimum length
  static int min(int a, int b) => a < b ? a : b;
}