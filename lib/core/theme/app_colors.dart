// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Brand colors based on revboostapp.com
  static const primaryDark = Color(0xFF1E3A8A);  // Deep blue
  static const primary = Color(0xFF2563EB);      // Main blue
  static const primaryLight = Color(0xFF60A5FA); // Light blue
  
  // Light theme colors
  static const lightBackground = Color(0xFFF9FAFB);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightTextPrimary = Color(0xFF1F2937);
  static const lightTextSecondary = Color(0xFF6B7280);
  
  // Dark theme colors
  static const darkBackground = Color(0xFF1F2937);
  static const darkSurface = Color(0xFF374151);
  static const darkBorder = Color(0xFF4B5563);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFFD1D5DB);
  
  // Accent colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
}