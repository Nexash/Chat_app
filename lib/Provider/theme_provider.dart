import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  final _themeBox = Hive.box('theme');
  // Default to light mode
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }
  void _loadTheme() {
    String savedTheme = _themeBox.get('mode', defaultValue: 'light');
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Toggle function
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _themeBox.put('mode', isDark ? 'dark' : 'light');
    notifyListeners(); // This tells the app to rebuild
  }
}
