// lib/main.dart (rollback to previous version)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/firebase_service.dart';
import 'package:revboostapp/core/theme/app_theme.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/theme_provider.dart';
import 'package:revboostapp/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
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