import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'theme';
  final _themeBox = Hive.box(_boxName);

  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = Colors.deepPurple; // default

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      final savedTheme = _themeBox.get('mode', defaultValue: 'light') as String;
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

      final savedColor =
          _themeBox.get('seedColor', defaultValue: Colors.deepPurple.value)
              as int;
      _seedColor = Color(savedColor);
    } catch (e) {
      _themeMode = ThemeMode.light;
      _seedColor = Colors.deepPurple;
    }
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _themeBox.put('mode', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  void updateSeedColor(Color color) {
    _seedColor = color;
    _themeBox.put('seedColor', color.value);
    notifyListeners();
  }
}
