// // // lib/core/theme/app_colors.dart

// // import 'package:flutter/material.dart';

// // class AppColors {
// //   // Brand colors based on revboostapp.com
// //   static const primaryDark = Color(0xFF1E3A8A);  // Deep blue
// //   static const primary = Color(0xFF2563EB);      // Main blue
// //   static const primaryLight = Color(0xFF60A5FA); // Light blue
  
// //   // Light theme colors
// //   static const lightBackground = Color(0xFFF9FAFB);
// //   static const lightSurface = Colors.white;
// //   static const lightBorder = Color(0xFFE5E7EB);
// //   static const lightTextPrimary = Color(0xFF1F2937);
// //   static const lightTextSecondary = Color(0xFF6B7280);
  
// //   // Dark theme colors
// //   static const darkBackground = Color(0xFF1F2937);
// //   static const darkSurface = Color(0xFF374151);
// //   static const darkBorder = Color(0xFF4B5563);
// //   static const darkTextPrimary = Color(0xFFF9FAFB);
// //   static const darkTextSecondary = Color(0xFFD1D5DB);
  
// //   // Accent colors
// //   static const success = Color(0xFF10B981);
// //   static const warning = Color(0xFFF59E0B);
// //   static const error = Color(0xFFEF4444);
// //   static const info = Color(0xFF3B82F6);
// // }

// // lib/core/theme/app_colors.dart

// import 'package:flutter/material.dart';

// class AppColors {
//   // Brand colors - Modern blue palette
//   static const primary = Color(0xFF3B82F6);      // Vibrant blue
//   static const primaryDark = Color(0xFF1E40AF);  // Deep blue
//   static const primaryLight = Color(0xFF93C5FD);  // Light blue
  
//   // Neutral palette
//   static const neutral900 = Color(0xFF111827);  // Almost black
//   static const neutral800 = Color(0xFF1F2937);
//   static const neutral700 = Color(0xFF374151);
//   static const neutral600 = Color(0xFF4B5563);
//   static const neutral500 = Color(0xFF6B7280);
//   static const neutral400 = Color(0xFF9CA3AF);
//   static const neutral300 = Color(0xFFD1D5DB);
//   static const neutral200 = Color(0xFFE5E7EB);
//   static const neutral100 = Color(0xFFF3F4F6);
//   static const neutral50 = Color(0xFFF9FAFB);   // Almost white
  
//   // Light theme colors
//   static const lightBackground = neutral50;
//   static const lightBackgroundSecondary = Colors.white;
//   static const lightSurface = Colors.white;
//   static const lightBorder = neutral200;
//   static const lightTextPrimary = neutral900;
//   static const lightTextSecondary = neutral600;
  
//   // Dark theme colors
//   static const darkBackground = neutral900;
//   static const darkBackgroundSecondary = neutral800;
//   static const darkSurface = neutral800;
//   static const darkBorder = neutral700;
//   static const darkTextPrimary = neutral50;
//   static const darkTextSecondary = neutral300;
  
//   // Accent colors
//   static const success = Color(0xFF10B981);     // Green
//   static const warning = Color(0xFFF59E0B);     // Amber
//   static const error = Color(0xFFEF4444);       // Red
//   static const info = Color(0xFF3B82F6);        // Blue
  
//   // Additional functional colors
//   static const purple = Color(0xFF8B5CF6);
//   static const teal = Color(0xFF0D9488);
//   static const orange = Color(0xFFF97316);
//   static const pink = Color(0xFFEC4899);
// }
// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // === PREMIUM BRAND COLORS ===
  
  // Primary Brand - Sophisticated Blue Gradient
  static const primary = Color(0xFF1E40AF);        // Deep Royal Blue
  static const primaryDark = Color(0xFF1E3A8A);    // Deeper Blue
  static const primaryLight = Color(0xFF3B82F6);   // Bright Blue
  static const primaryAccent = Color(0xFF60A5FA);  // Light Blue Accent
  
  // Secondary Brand - Elegant Purple
  static const secondary = Color(0xFF7C3AED);      // Vibrant Purple
  static const secondaryDark = Color(0xFF5B21B6);  // Deep Purple
  static const secondaryLight = Color(0xFFA78BFA); // Light Purple
  
  // === PREMIUM NEUTRAL PALETTE ===
  
  // Ultra Dark to Light Neutrals
  static const neutral950 = Color(0xFF0F0F0F);    // Almost Black
  static const neutral900 = Color(0xFF171717);    // Rich Black
  static const neutral800 = Color(0xFF262626);    // Dark Charcoal
  static const neutral700 = Color(0xFF404040);    // Medium Charcoal
  static const neutral600 = Color(0xFF525252);    // Warm Gray
  static const neutral500 = Color(0xFF737373);    // Balanced Gray
  static const neutral400 = Color(0xFFA3A3A3);    // Light Gray
  static const neutral300 = Color(0xFFD4D4D8);    // Soft Gray
  static const neutral200 = Color(0xFFE4E4E7);    // Lighter Gray
  static const neutral100 = Color(0xFFF4F4F5);    // Very Light Gray
  static const neutral50 = Color(0xFFFAFAFB);     // Off White
  
  // === PREMIUM SURFACE COLORS ===
  
  // Light Theme - Elegant and Clean
  static const lightBackground = Color(0xFFFDFDFD);        // Pure White with hint of warmth
  static const lightBackgroundSecondary = Color(0xFFFAFAFB); // Subtle off-white
  static const lightSurface = Color(0xFFFFFFFF);           // Pure white for cards
  static const lightSurfaceElevated = Color(0xFFFBFBFC);  // Slightly elevated surfaces
  static const lightBorder = Color(0xFFE8E9EA);           // Soft borders
  static const lightBorderLight = Color(0xFFF1F2F3);      // Very light borders
  static const lightTextPrimary = Color(0xFF0F172A);      // Rich black for text
  static const lightTextSecondary = Color(0xFF475569);    // Sophisticated gray
  static const lightTextTertiary = Color(0xFF64748B);     // Lighter text
  
  // Dark Theme - Sophisticated and Modern
  static const darkBackground = Color(0xFF0F0F0F);         // Deep black
  static const darkBackgroundSecondary = Color(0xFF171717); // Slightly lighter
  static const darkSurface = Color(0xFF1A1A1A);           // Card surfaces
  static const darkSurfaceElevated = Color(0xFF262626);   // Elevated surfaces
  static const darkBorder = Color(0xFF2A2A2A);            // Subtle borders
  static const darkBorderLight = Color(0xFF404040);       // Lighter borders
  static const darkTextPrimary = Color(0xFFFAFAFB);       // Pure white text
  static const darkTextSecondary = Color(0xFFE2E8F0);     // Light gray text
  static const darkTextTertiary = Color(0xFFCBD5E1);      // Medium gray text
  
  // === SEMANTIC COLORS ===
  
  // Success - Fresh and Natural
  static const success = Color(0xFF059669);        // Forest Green
  static const successLight = Color(0xFF10B981);   // Emerald
  static const successDark = Color(0xFF047857);    // Deep Green
  static const successBg = Color(0xFFF0FDF4);      // Light green background
  
  // Warning - Warm and Attention-grabbing
  static const warning = Color(0xFFD97706);        // Amber Orange
  static const warningLight = Color(0xFFF59E0B);   // Bright Amber
  static const warningDark = Color(0xFFB45309);    // Deep Amber
  static const warningBg = Color(0xFFFEFBF0);      // Light amber background
  
  // Error - Clear and Decisive
  static const error = Color(0xFFDC2626);          // Clear Red
  static const errorLight = Color(0xFFEF4444);     // Bright Red
  static const errorDark = Color(0xFFB91C1C);      // Deep Red
  static const errorBg = Color(0xFFFEF2F2);        // Light red background
  
  // Info - Professional and Trustworthy
  static const info = Color(0xFF0EA5E9);           // Sky Blue
  static const infoLight = Color(0xFF38BDF8);      // Light Blue
  static const infoDark = Color(0xFF0284C7);       // Deep Blue
  static const infoBg = Color(0xFFF0F9FF);         // Light blue background
  
  // === ACCENT COLORS ===
  
  // Premium Accent Palette
  static const purple = Color(0xFF8B5CF6);         // Rich Purple
  static const indigo = Color(0xFF6366F1);         // Deep Indigo
  static const teal = Color(0xFF14B8A6);           // Modern Teal
  static const cyan = Color(0xFF06B6D4);           // Fresh Cyan
  static const pink = Color(0xFFEC4899);           // Vibrant Pink
  static const rose = Color(0xFFF43F5E);           // Elegant Rose
  static const orange = Color(0xFFF97316);         // Energetic Orange
  static const yellow = Color(0xFFFBBF24);         // Warm Yellow
  
  // === GRADIENT COLORS ===
  
  // Primary Gradients
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, purple],
  );
  
  static const gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, teal],
  );
  
  // === SPECIAL EFFECTS ===
  
  // Glassmorphism and Premium Effects
  static const glassBg = Color(0x1AFFFFFF);        // Translucent white
  static const glassBgDark = Color(0x1A000000);    // Translucent black
  
  // Shadow Colors
  static const shadowLight = Color(0x08000000);    // Subtle light shadow
  static const shadowMedium = Color(0x15000000);   // Medium shadow
  static const shadowStrong = Color(0x25000000);   // Strong shadow
  
  // Overlay Colors
  static const overlayLight = Color(0x40000000);   // Light overlay
  static const overlayMedium = Color(0x60000000);  // Medium overlay
  static const overlayStrong = Color(0x80000000);  // Strong overlay
  
  // === UTILITY METHODS ===
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Get appropriate text color for background
  static Color getTextColorForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  }
  
  /// Get surface color based on elevation
  static Color getSurfaceColor(bool isDark, {int elevation = 0}) {
    if (isDark) {
      switch (elevation) {
        case 0: return darkSurface;
        case 1: return darkSurfaceElevated;
        case 2: return Color.lerp(darkSurfaceElevated, neutral700, 0.3)!;
        default: return Color.lerp(darkSurfaceElevated, neutral600, 0.5)!;
      }
    } else {
      switch (elevation) {
        case 0: return lightSurface;
        case 1: return lightSurfaceElevated;
        case 2: return Color.lerp(lightSurfaceElevated, neutral100, 0.5)!;
        default: return Color.lerp(lightSurfaceElevated, neutral200, 0.3)!;
      }
    }
  }
}