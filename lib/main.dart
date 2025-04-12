// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:revboostapp/core/services/email_service.dart'; // Add this import
import 'package:revboostapp/core/theme/app_theme.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/business_setup_provider.dart';
import 'package:revboostapp/providers/dashboard_provider.dart';
import 'package:revboostapp/providers/settings_provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/providers/theme_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  setPathUrlStrategy();

  // Create the email service
  final emailService = EmailService(
    apiKey: const String.fromEnvironment('RESEND_API_KEY', defaultValue: ''),
    fromEmail: 'reviews@revboostapp.com', 
    fromName: 'RevBoost',
  );

  runApp(MyApp(emailService: emailService));
}

class MyApp extends StatelessWidget {
  final EmailService emailService;
  
  const MyApp({super.key, required this.emailService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessSetupProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        
        // Provide the EmailService for use in the review request screen
        Provider.value(value: emailService),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp.router(
            title: 'RevBoost',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}