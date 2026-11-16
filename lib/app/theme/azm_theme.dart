import 'package:flutter/material.dart';

class AzmTheme {
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color brightTeal = Color(0xFF14B8A6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color alertCoral = Color(0xFFEF4444);

  static ThemeData darkTheme() {
    const bg = Color(0xFF0B1120);
    const surface = Color(0xFF131C31);
    const card = Color(0xFF19243D);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: brightTeal,
        secondary: accentAmber,
        error: alertCoral,
        surface: surface,
        onPrimary: Colors.black,
        onSurface: Color(0xFFF1F5F9),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF263554), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF263554)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF263554)),
        ),
      ),
    );
  }

  static ThemeData lightTheme() {
    const bg = Color(0xFFF4F7FA);
    const surface = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: accentAmber,
        error: alertCoral,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}
