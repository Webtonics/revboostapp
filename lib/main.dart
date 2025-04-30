// lib/main.dart with secure configuration

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/config/api_config.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
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
  
  // Initialize API config
  final apiConfig = ApiConfig();
  await apiConfig.initialize();
  
  // Optionally load from remote config
  // await apiConfig.loadFromRemoteConfig();
  await dotenv.load(fileName: ".env");
  debugPrint('RESEND_API_KEY: ${dotenv.env['RESEND_API_KEY']}');
  debugPrint('EMAIL_FROM_ADDRESS: ${dotenv.env['EMAIL_FROM_ADDRESS']}');
  
  setPathUrlStrategy();

  // Create the email service with secure config
  final emailService = EmailService(
    apiKey: apiConfig.resendApiKey,
    fromEmail: apiConfig.emailFromAddress, 
    fromName: apiConfig.emailFromName,
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
        
        
        // Provide the EmailService
        Provider.value(value: emailService),
      ],
      child: Builder(
        builder: (context) {
          // final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp.router(
            title: 'RevBoost',
            theme: AppTheme.lightTheme,
            // darkTheme: AppTheme.darkTheme,
            // themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}