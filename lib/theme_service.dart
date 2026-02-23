import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Colori Brand
  static const Color brandColor = Color(0xFF4A7D91);
  static const Color darkBackground = Color(0xFF121212);
  static const Color lightBackground = Color(0xFFF5F5F5);

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Questo avvisa tutta l'app di ridisegnarsi
  }

  // Definiamo il tema Light
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: brandColor,
    appBarTheme: const AppBarTheme(backgroundColor: lightBackground, elevation: 0),
  );

  // Definiamo il tema Dark
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: brandColor,
    appBarTheme: const AppBarTheme(backgroundColor: darkBackground, elevation: 0),
  );
}