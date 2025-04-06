// // lib/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/business_setup/screens/business_setup_screen.dart';
import 'package:revboostapp/features/onboarding/screens/onboarding_screen.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/features/splash/screens/splash_screen.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/widgets/layout/app_bar_with_theme_toggle.dart';

// Define routes
class AppRoutes {
  static const String splash = '/splash';
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

// Set up placeholder screens (we'll replace these later)
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
  static GoRouter router(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return GoRouter(
      initialLocation: AppRoutes.splash,
      redirect: (context, state) async {
      final isLoggedIn = authProvider.isAuthenticated;
      final isOnLoginPage = state.matchedLocation == AppRoutes.login || 
                           state.matchedLocation == AppRoutes.register ||
                           state.matchedLocation == AppRoutes.forgotPassword;
      final isOnSplashPage = state.matchedLocation == AppRoutes.splash;
      final isOnOnboardingPage = state.matchedLocation == AppRoutes.onboarding;
      final isOnBusinessSetupPage = state.matchedLocation == AppRoutes.businessSetup;
      final isOnReviewPage = state.matchedLocation.startsWith('/r/');
      
      // Allow public routes
      if (isOnSplashPage || isOnReviewPage) {
        return null;
      }
      
      // Handle auth state
      if (!isLoggedIn) {
        // If not logged in and not on auth pages, redirect to login
        return isOnLoginPage ? null : AppRoutes.login;
      } 
      
      // User is logged in, check onboarding status
      final onboardingCompleted = await OnboardingService.isOnboardingCompleted();
      final businessSetupCompleted = await OnboardingService.isBusinessSetupCompleted();
      
      if (!onboardingCompleted && !isOnOnboardingPage) {
        return AppRoutes.onboarding;
      }
      
      if (onboardingCompleted && !businessSetupCompleted && !isOnBusinessSetupPage) {
        return AppRoutes.businessSetup;
      }
      
      // If on auth or onboarding pages but already completed, redirect to dashboard
      if ((isOnLoginPage || isOnOnboardingPage || isOnBusinessSetupPage) && businessSetupCompleted) {
        return AppRoutes.dashboard;
      }
      
      return null;
    },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const PlaceholderScreen(title: 'Login'),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const PlaceholderScreen(title: 'Register'),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const PlaceholderScreen(title: 'Forgot Password'),
        ),
        
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const PlaceholderScreen(title: 'Dashboard'),
        ),
        GoRoute(
          path: AppRoutes.reviewRequests,
          builder: (context, state) => const PlaceholderScreen(title: 'Review Requests'),
        ),
        GoRoute(
          path: AppRoutes.contacts,
          builder: (context, state) => const PlaceholderScreen(title: 'Contacts'),
        ),
        GoRoute(
          path: AppRoutes.qrCode,
          builder: (context, state) => const PlaceholderScreen(title: 'QR Code'),
        ),
        GoRoute(
          path: AppRoutes.templates,
          builder: (context, state) => const PlaceholderScreen(title: 'Templates'),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          builder: (context, state) => const PlaceholderScreen(title: 'Subscription'),
        ),
        GoRoute(
          path: AppRoutes.reviewPage,
          builder: (context, state) {
            final businessId = state.pathParameters['businessId'] ?? '';
            return PlaceholderScreen(title: 'Review Page for $businessId');
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
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
      ],
    );
  }
}

// lib/routing/app_router.dart (update the redirect method)

