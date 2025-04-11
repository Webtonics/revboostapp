// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/auth/screens/forgot_password_screen.dart';
import 'package:revboostapp/features/auth/screens/login_screen.dart';
import 'package:revboostapp/features/auth/screens/register_screen.dart';
import 'package:revboostapp/features/business_setup/screens/business_setup_screen.dart';
import 'package:revboostapp/features/dashboard/screens/dashboard_screen.dart';
import 'package:revboostapp/features/onboarding/screens/onboarding_screen.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/features/qr_code/screens/qr_code_screen.dart';
import 'package:revboostapp/features/reviews/screens/public_review_screen.dart';
import 'package:revboostapp/features/settings/settings_screen.dart';
import 'package:revboostapp/features/splash/screens/splash_screen.dart';
import 'package:revboostapp/features/subscription/screens/subscription_screen.dart';
// import 'package:revboostapp/features/subscription/screens/subscription_success_screen.dart';
import 'package:revboostapp/providers/auth_provider.dart';
// import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/widgets/layout/app_bar_with_theme_toggle.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';

// Define routes
class AppRoutes {
  static const String splash = '/';  // Changed to root for simplicity
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String businessSetup = '/business-setup';
  static const String dashboard = '/dashboard';
  static const String reviewRequests = '/review-requests';
  static const String contacts = '/contacts';
  static const String qrCode = '/qr-code';
  static const String templates = '/templates';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  
  // Customer-facing routes
  static const String reviewPage = '/r/:businessId';
}

// Set up placeholder screens
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
                context.go( AppRoutes.splash);
              },
              child: const Text('Sign Out (Test)'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      
      // Update redirect in app_router.dart

  // In your app_router.dart redirect method:
// In app_router.dart
redirect: (context, state) async {
  // Get auth provider
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentPath = state.matchedLocation;
  
  // Don't redirect during loading or on splash
  if (authProvider.status == AuthStatus.loading || 
      authProvider.status == AuthStatus.initial ||
      currentPath == AppRoutes.splash) {
    return null;
  }
  
  // Always allow public review pages
  if (currentPath.startsWith('/r/')) {
    return null;
  }
  
  // Check auth status
  final isAuthenticated = authProvider.status == AuthStatus.authenticated;
  final user = authProvider.user;
  
  // Check if on auth-related page
  final isOnAuthPage = 
      currentPath == AppRoutes.login || 
      currentPath == AppRoutes.register || 
      currentPath == AppRoutes.forgotPassword;
  
  // Not logged in -> go to login
  if (!isAuthenticated) {
    return isOnAuthPage ? null : AppRoutes.login;
  }
  
  // Check for onboarding and business setup completion
  final onboardingCompleted = await OnboardingService.isOnboardingCompleted();
  final businessSetupCompleted = user?.hasCompletedSetup ?? false;
  
  // Determine where to send the authenticated user
  if (isOnAuthPage) {
    // If logged in but on auth page, where to go next?
    if (!onboardingCompleted) {
      return AppRoutes.onboarding;
    } else if (!businessSetupCompleted) {
      return AppRoutes.businessSetup;
    } else {
      return AppRoutes.dashboard;
    }
  }
  
  // Handle other cases
  if (currentPath == AppRoutes.onboarding) {
    if (onboardingCompleted) {
      return businessSetupCompleted 
          ? AppRoutes.dashboard 
          : AppRoutes.businessSetup;
    }
    return null; // Allow access to onboarding if not completed
  }
  
  if (currentPath == AppRoutes.businessSetup) {
    if (businessSetupCompleted) {
      return AppRoutes.dashboard;
    }
    if (!onboardingCompleted) {
      return AppRoutes.onboarding;
    }
    return null; // Allow access to business setup if onboarding completed
  }
  
  // If trying to access dashboard or other protected routes
  if (!onboardingCompleted) {
    return AppRoutes.onboarding;
  } else if (!businessSetupCompleted) {
    return AppRoutes.businessSetup;
  }
  
  // Allow access to all other routes for authenticated users
  return null;
},
      
      routes: [
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
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.businessSetup,
          builder: (context, state) => const BusinessSetupScreen(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const  DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.reviewRequests,
          builder: (context, state) => const AppLayout(title: "Review Requests", child:   PlaceholderScreen(title: 'Review Requests')),
        ),
        GoRoute(
          path: AppRoutes.contacts,
          builder: (context, state) => const AppLayout(title: "Contacts", child:   PlaceholderScreen(title: 'Contacts')), 
        ),
        GoRoute(
          path: AppRoutes.qrCode,
          builder: (context, state) => const QrCodeScreen(),
        ),
        GoRoute(
          path: AppRoutes.templates,
          builder: (context, state) => const AppLayout(title: "Templates", child:   PlaceholderScreen(title: 'Templates')),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) =>const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          builder: (context, state) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: AppRoutes.reviewPage,
          builder: (context, state) {
            final businessId = state.pathParameters['businessId'] ?? '';
            return PublicReviewScreen(businessId: businessId);
          },
        ),
        // GoRoute(
        //   path: '/subscription-success',
        //   builder: (context, state) {
        //     // Extract parameters from URL
        //     final orderId = state.uri.queryParameters['order_id'];
        //     final planId = state.uri.queryParameters['plan_id'];
        //     final userId = state.uri.queryParameters['user_id'];
            
        //     // Process subscription if possible
        //     if (orderId != null && planId != null) {
        //       final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        //       subscriptionProvider.processSuccessfulSubscription(orderId, planId);
        //     }
            
        //     // Show success page
        //     return SubscriptionSuccessScreen(
        //       orderId: orderId,
        //       planId: planId,
        //     );
        //   },
        // ),

        // Add the subscription route
      GoRoute(
          path: AppRoutes.subscription,
          builder: (context, state) => const SubscriptionScreen(),
        ),
              ],
            );
          }
        }