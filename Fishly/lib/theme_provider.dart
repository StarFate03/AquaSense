import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider(this._isDarkMode);

  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }
}
