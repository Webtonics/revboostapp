// lib/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/auth/screens/email_verification_screen.dart';
import 'package:revboostapp/features/auth/screens/forgot_password_screen.dart';
import 'package:revboostapp/features/auth/screens/login_screen.dart';
import 'package:revboostapp/features/auth/screens/register_screen.dart';
import 'package:revboostapp/features/business_setup/screens/business_setup_screen.dart';
import 'package:revboostapp/features/dashboard/screens/dashboard_screen.dart';
import 'package:revboostapp/features/feedback/screens/feedback_screen.dart';
import 'package:revboostapp/features/onboarding/screens/onboarding_screen.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/features/qr_code/screens/qr_code_screen.dart';
import 'package:revboostapp/features/review_requests/screens/review_requests_screen.dart';
import 'package:revboostapp/features/reviews/screens/public_review_screen.dart';
import 'package:revboostapp/features/settings/settings_screen.dart';
import 'package:revboostapp/features/splash/screens/splash_screen.dart';
import 'package:revboostapp/features/subscription/screens/subscription_screen.dart';
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
  
  // Returns all public routes that don't require authentication
  static final List<String> publicRoutes = [
    splash,
    login,
    register,
    forgotPassword,
    authAction,
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
  
  /// Get the configured GoRouter instance
  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      
      /// Primary redirect logic to handle authentication and route protection
      redirect: (context, state) async {
        // Extract important data
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        final currentPath = state.matchedLocation;

        // Logging to help with debugging
        _logRouteAttempt(currentPath, state.uri);
        
        // Skip redirect for these special cases
        if (_shouldSkipRedirect(authProvider, currentPath)) {
          return null;
        }
        
        // AUTHENTICATION CHECK
        final isAuthenticated = authProvider.status == AuthStatus.authenticated;
        final user = authProvider.user;
        final isPublicRoute = AppRoutes.publicRoutes.contains(currentPath);
        
        // Not logged in -> redirect to login unless on a public route
        if (!isAuthenticated) {
          return isPublicRoute ? null : AppRoutes.login;
        }
        
        // User is authenticated but on a public route (login, register, etc.)
        // Redirect to appropriate next step
        if (isPublicRoute) {
          return AppRoutes.emailVerification; // Always start at email verification
        }
        
        // EMAIL VERIFICATION CHECK
        final isEmailVerified = user?.emailVerified ?? false;
        if (!isEmailVerified && !AppRoutes.noVerificationRequiredRoutes.contains(currentPath)) {
          return AppRoutes.emailVerification;
        }
        
        // FLOW CHECK: Once email is verified, enforce onboarding -> business setup -> dashboard flow
        if (isEmailVerified) {
          final flowResult = await _enforceUserFlowProgression(user, currentPath, context);
          if (flowResult != null) {
            return flowResult;
          }
        }
        
        // SUBSCRIPTION CHECK for premium routes
        if (AppRoutes.premiumRoutes.contains(currentPath)) {
          // Force reload subscription status to avoid stale data
          await subscriptionProvider.reloadSubscriptionStatus();
          
          final hasActiveSubscription = subscriptionProvider.isSubscribed;
          final isFreeTrial = subscriptionProvider.isFreeTrial;
          
          if (!hasActiveSubscription && !isFreeTrial && currentPath != AppRoutes.subscription) {
            debugPrint('Premium route access attempted without subscription: $currentPath');
            return AppRoutes.subscription;
          }
        }
        
        // Allow access to the requested route if all checks pass
        return null;
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
          builder: (context, state) => const EmailVerificationScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.businessSetup,
          builder: (context, state) => const BusinessSetupScreen(),
        ),
        
        // MAIN APPLICATION ROUTES
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.feedback,
          builder: (context, state) => const BusinessFeedbackPage(),
        ),
        
        // PREMIUM ROUTES
        GoRoute(
          path: AppRoutes.reviewRequests,
          builder: (context, state) => const ReviewRequestsScreen(),
        ),
        GoRoute(
          path: AppRoutes.contacts,
          builder: (context, state) => const AppLayout(
            title: "Contacts", 
            child: PlaceholderScreen(title: 'Contacts')
          ), 
        ),
        GoRoute(
          path: AppRoutes.qrCode,
          builder: (context, state) => const QrCodeScreen(),
        ),
        GoRoute(
          path: AppRoutes.templates,
          builder: (context, state) => const AppLayout(
            title: "Templates", 
            child: PlaceholderScreen(title: 'Templates')
          ),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          builder: (context, state) => const SubscriptionScreen(),
        ),
        
        // PUBLIC REVIEW PAGE
        GoRoute(
          path: AppRoutes.reviewPage,
          builder: (context, state) {
            final businessId = state.pathParameters['businessId'] ?? '';
            return PublicReviewScreen(businessId: businessId);
          },
        ),
        
        // AUTH ACTION ROUTES (Email verification, password reset)
        GoRoute(
          path: AppRoutes.authAction,
          builder: (context, state) => _buildAuthActionScreen(context, state),
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

  /// Check if we should skip the redirect logic for certain routes
  static bool _shouldSkipRedirect(AuthProvider authProvider, String currentPath) {
    // Skip if auth is loading, on splash screen, or for public review pages
    if (authProvider.status == AuthStatus.loading || 
        authProvider.status == AuthStatus.initial ||
        currentPath == AppRoutes.splash ||
        AppRoutes.isPublicReviewRoute(currentPath)) {
      return true;
    }
    
    // Skip auth check for direct auth action links
    if (currentPath == AppRoutes.authAction) {
      debugPrint('Auth action URL detected - proceeding without redirect');
      return true;
    }
    
    return false;
  }
  
  /// Enforce the proper progression through onboarding and business setup
  static Future<String?> _enforceUserFlowProgression(
      dynamic user, String currentPath, BuildContext context) async {
    
    // Get onboarding and business setup status
    final onboardingCompleted = await OnboardingService.isOnboardingCompleted();
    final businessSetupCompleted = user?.hasCompletedSetup ?? false;
    
    debugPrint('Flow status check: onboarding=${onboardingCompleted}, businessSetup=${businessSetupCompleted}');
    
    // Apply the strict flow progression logic
    if (!onboardingCompleted) {
      // If onboarding not completed, only allow access to onboarding screen
      if (currentPath != AppRoutes.onboarding) {
        debugPrint('Redirecting to onboarding: onboarding not completed');
        return AppRoutes.onboarding;
      }
    } else if (!businessSetupCompleted) {
      // If onboarding completed but business setup not completed,
      // only allow access to business setup screen
      if (currentPath != AppRoutes.businessSetup) {
        debugPrint('Redirecting to business setup: onboarding completed but business setup not completed');
        return AppRoutes.businessSetup;
      }
    }
    
    // If trying to access onboarding after completing it, redirect to next step
    if (currentPath == AppRoutes.onboarding && onboardingCompleted) {
      return businessSetupCompleted ? AppRoutes.dashboard : AppRoutes.businessSetup;
    }
    
    // If trying to access business setup after completing it, redirect to dashboard
    if (currentPath == AppRoutes.businessSetup && businessSetupCompleted) {
      return AppRoutes.dashboard;
    }
    
    // No redirection needed, allow current path
    return null;
  }
  
  /// Build the appropriate screen for auth action URLs (verification, password reset)
  static Widget _buildAuthActionScreen(BuildContext context, GoRouterState state) {
    // Extract parameters
    final mode = state.uri.queryParameters['mode'];
    final oobCode = state.uri.queryParameters['oobCode'];
    final continueUrl = state.uri.queryParameters['continueUrl'];
    
    // Log debug info
    debugPrint('Auth action handling: mode=$mode, code=${oobCode != null ? 'present' : 'missing'}');
    
    // Handle each auth action mode
    switch (mode) {
      case 'verifyEmail':
        if (oobCode != null) {
          return EmailVerificationScreen(
            mode: mode,
            oobCode: oobCode,
            continueUrl: continueUrl,
            isHandlingActionUrl: true,
          );
        }
        break;
        
      // case 'resetPassword':
      //   if (oobCode != null) {
      //     return ForgotPasswordScreen(
      //       mode: mode,
      //       oobCode: oobCode,
      //       continueUrl: continueUrl,
      //     ); 
      //   }
      //   break;
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
  }
  
  /// Helper method to log route navigation attempts for debugging
  static void _logRouteAttempt(String path, Uri uri) {
    debugPrint('⚡ Route requested: $path (${uri.toString()})');
  }
  
  /// Helper method for string minimum length
  static int min(int a, int b) => a < b ? a : b;
}