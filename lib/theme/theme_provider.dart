import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeProvider({bool isDark = true}) {
    _isDark = isDark;
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDark(bool isDark) {
    if (_isDark != isDark) {
      _isDark = isDark;
      notifyListeners();
    }
  }
}