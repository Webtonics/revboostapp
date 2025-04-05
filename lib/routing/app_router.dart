import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:revboostapp/widgets/layout/app_bar_with_theme_toggle.dart';

// Define routes for all our screens
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
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
            const Text('Try the theme toggle in the app bar!'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated Button'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined Button'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const PlaceholderScreen(title: 'Home'),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const PlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: AppRoutes.businessSetup,
        builder: (context, state) => const PlaceholderScreen(title: 'Business Setup'),
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