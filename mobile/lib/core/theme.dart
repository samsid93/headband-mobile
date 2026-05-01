import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color bg = Color(0xFF06060E);
  static const Color s1 = Color(0xFF0E0E1C);
  static const Color s2 = Color(0xFF161626);
  static const Color s3 = Color(0xFF1E1E30);
  static const Color s4 = Color(0xFF282840);

  static const Color acc = Color(0xFFF7C948);
  static const Color acc2 = Color(0xFFFF7A3D);
  static const Color cor = Color(0xFF2EE68A);
  static const Color skp = Color(0xFFFF3F5A);

  static const Color blu = Color(0xFF4A9EFF);
  static const Color pur = Color(0xFF9B7EFF);
  static const Color pnk = Color(0xFFFF6EBC);

  static const Color txt = Color(0xFFEEF0FF);
  static const Color mut = Color(0xFF5E6080);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: acc,
      colorScheme: const ColorScheme.dark(
        primary: acc,
        secondary: pur,
        surface: s2,
        background: bg,
        error: skp,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w900,
          color: txt,
          fontFamily: 'Georgia',
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: txt,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: txt,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: mut,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: acc,
          foregroundColor: bg,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
