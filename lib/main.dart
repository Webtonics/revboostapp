// lib/main.dart (rollback to previous version)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:revboostapp/core/theme/app_theme.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/business_setup_provider.dart';
import 'package:revboostapp/providers/dashboard_provider.dart';
import 'package:revboostapp/providers/settings_provider.dart';
import 'package:revboostapp/providers/theme_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
   setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessSetupProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
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