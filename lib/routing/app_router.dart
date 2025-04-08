// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/auth/screens/forgot_password_screen.dart';
import 'package:revboostapp/features/auth/screens/login_screen.dart';
import 'package:revboostapp/features/auth/screens/register_screen.dart';
import 'package:revboostapp/features/business_setup/screens/business_setup_screen.dart';
import 'package:revboostapp/features/onboarding/screens/onboarding_screen.dart';
import 'package:revboostapp/features/splash/screens/splash_screen.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/widgets/layout/app_bar_with_theme_toggle.dart';

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
      
      redirect: (context, state) {
        // Get auth provider without listening to it
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentPath = state.matchedLocation;
        
        debugPrint('GoRouter redirect: path=$currentPath, auth=${authProvider.status}');
        
        // Always allow access to splash screen
        if (currentPath == AppRoutes.splash) {
          debugPrint('Allowing access to splash screen');
          return null;
        }
        
        // Always allow access to public review pages
        if (currentPath.startsWith('/r/')) {
          debugPrint('Allowing access to review page');
          return null;
        }
        
        // During loading, don't redirect
        if (authProvider.status == AuthStatus.loading || 
            authProvider.status == AuthStatus.initial) {
          debugPrint('Auth is loading or initial, not redirecting');
          return null;
        }
        
        // Check if on an auth page
        final isOnAuthPage = 
            currentPath == AppRoutes.login || 
            currentPath == AppRoutes.register || 
            currentPath == AppRoutes.forgotPassword;
        
        // If not authenticated and not on an auth page, go to login
        if (authProvider.status == AuthStatus.unauthenticated) {
          debugPrint('Not authenticated, redirecting to login');
          return isOnAuthPage ? null : AppRoutes.login;
        }
        
        // If authenticated but on an auth page, go to onboarding
        if (authProvider.status == AuthStatus.authenticated && isOnAuthPage) {
          debugPrint('Authenticated but on auth page, redirecting to onboarding');
          return AppRoutes.onboarding;
        }
        
        // In all other cases, allow navigation
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
      ],
    );
  }
}