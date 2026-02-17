import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Default to light mode
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // Toggle function
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // This tells the app to rebuild
  }
}
