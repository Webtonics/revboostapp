// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        // Default to system or light mode
        _themeMode = ThemeMode.system;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode == ThemeMode.dark 
          ? 'dark' 
          : mode == ThemeMode.light 
              ? 'light' 
              : 'system');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
  
  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark);
  }
}