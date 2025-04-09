// // lib/core/theme/app_colors.dart

// import 'package:flutter/material.dart';

// class AppColors {
//   // Brand colors based on revboostapp.com
//   static const primaryDark = Color(0xFF1E3A8A);  // Deep blue
//   static const primary = Color(0xFF2563EB);      // Main blue
//   static const primaryLight = Color(0xFF60A5FA); // Light blue
  
//   // Light theme colors
//   static const lightBackground = Color(0xFFF9FAFB);
//   static const lightSurface = Colors.white;
//   static const lightBorder = Color(0xFFE5E7EB);
//   static const lightTextPrimary = Color(0xFF1F2937);
//   static const lightTextSecondary = Color(0xFF6B7280);
  
//   // Dark theme colors
//   static const darkBackground = Color(0xFF1F2937);
//   static const darkSurface = Color(0xFF374151);
//   static const darkBorder = Color(0xFF4B5563);
//   static const darkTextPrimary = Color(0xFFF9FAFB);
//   static const darkTextSecondary = Color(0xFFD1D5DB);
  
//   // Accent colors
//   static const success = Color(0xFF10B981);
//   static const warning = Color(0xFFF59E0B);
//   static const error = Color(0xFFEF4444);
//   static const info = Color(0xFF3B82F6);
// }

// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Brand colors - Modern blue palette
  static const primary = Color(0xFF3B82F6);      // Vibrant blue
  static const primaryDark = Color(0xFF1E40AF);  // Deep blue
  static const primaryLight = Color(0xFF93C5FD);  // Light blue
  
  // Neutral palette
  static const neutral900 = Color(0xFF111827);  // Almost black
  static const neutral800 = Color(0xFF1F2937);
  static const neutral700 = Color(0xFF374151);
  static const neutral600 = Color(0xFF4B5563);
  static const neutral500 = Color(0xFF6B7280);
  static const neutral400 = Color(0xFF9CA3AF);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral200 = Color(0xFFE5E7EB);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral50 = Color(0xFFF9FAFB);   // Almost white
  
  // Light theme colors
  static const lightBackground = neutral50;
  static const lightBackgroundSecondary = Colors.white;
  static const lightSurface = Colors.white;
  static const lightBorder = neutral200;
  static const lightTextPrimary = neutral900;
  static const lightTextSecondary = neutral600;
  
  // Dark theme colors
  static const darkBackground = neutral900;
  static const darkBackgroundSecondary = neutral800;
  static const darkSurface = neutral800;
  static const darkBorder = neutral700;
  static const darkTextPrimary = neutral50;
  static const darkTextSecondary = neutral300;
  
  // Accent colors
  static const success = Color(0xFF10B981);     // Green
  static const warning = Color(0xFFF59E0B);     // Amber
  static const error = Color(0xFFEF4444);       // Red
  static const info = Color(0xFF3B82F6);        // Blue
  
  // Additional functional colors
  static const purple = Color(0xFF8B5CF6);
  static const teal = Color(0xFF0D9488);
  static const orange = Color(0xFFF97316);
  static const pink = Color(0xFFEC4899);
}