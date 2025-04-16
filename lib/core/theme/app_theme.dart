// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Text Styles
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color textSecondary) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: textColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textSecondary,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final ThemeData base = ThemeData.light();
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      // primary: AppColors.primary,
      primary: Colors.indigo,
      onPrimary: Colors.white,
      secondary: AppColors.purple,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightTextPrimary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(base.textTheme, AppColors.lightTextPrimary, AppColors.lightTextSecondary),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme, AppColors.lightTextPrimary, AppColors.lightTextSecondary),
      
      // Component Themes
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 4, 155, 54)),
        centerTitle: false,
        titleTextStyle: _buildTextTheme(base.textTheme, AppColors.lightTextPrimary, AppColors.lightTextSecondary).titleLarge,
      ),
      
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        shadowColor: AppColors.neutral900.withOpacity(0.04),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.lightTextSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.lightTextSecondary),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primary),
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      
      // General Theme Settings
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      splashColor: AppColors.primary.withOpacity(0.05),
      highlightColor: AppColors.primary.withOpacity(0.05),
      canvasColor: AppColors.lightBackground,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final ThemeData base = ThemeData.dark();
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color.fromARGB(255, 255, 255, 255),
      onPrimary: Colors.white,
      secondary: AppColors.purple,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(base.textTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      
      // Component Themes
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        centerTitle: false,
        titleTextStyle: _buildTextTheme(base.textTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary).titleLarge,
      ),
      
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primary),
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      
      // General Theme Settings
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      splashColor: AppColors.primary.withOpacity(0.05),
      highlightColor: AppColors.primary.withOpacity(0.05),
      canvasColor: AppColors.darkBackground,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}