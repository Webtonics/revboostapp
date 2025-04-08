// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Text Styles
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color textSecondary) {
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
        fontFamily: 'Inter',
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontFamily: 'Inter',
        fontSize: 45,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        color: textColor,
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineLarge: base.headlineLarge!.copyWith(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textColor,
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: textColor,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textSecondary,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: base.labelMedium!.copyWith(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final ThemeData base = ThemeData.light();
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(base.textTheme, AppColors.lightTextPrimary, AppColors.lightTextSecondary),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme, AppColors.lightTextPrimary, AppColors.lightTextSecondary),
      
      // Component Themes
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: _buildTextTheme(base.textTheme, AppColors.lightTextPrimary, AppColors.lightTextSecondary).titleLarge,
      ),
      
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        shadowColor: AppColors.lightTextPrimary.withOpacity(0.1),
      ),
      
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.lightBackground,
        disabledColor: AppColors.lightBorder,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primaryLight,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: AppColors.lightTextPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 4,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
      
      // General Theme Settings
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      canvasColor: AppColors.lightBackground,
      brightness: Brightness.light,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final ThemeData base = ThemeData.dark();
    final ColorScheme colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
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
        titleTextStyle: _buildTextTheme(base.textTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary).titleLarge,
      ),
      
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withOpacity(0.4),
      ),
      
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        disabledColor: AppColors.darkBorder,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primaryLight,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: AppColors.darkTextPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        brightness: Brightness.dark,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 4,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.darkTextSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
      
      // General Theme Settings
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      canvasColor: AppColors.darkBackground,
      brightness: Brightness.dark,
    );
  }
}