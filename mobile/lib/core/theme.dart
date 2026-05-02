import 'package:flutter/material.dart';

class AppTheme {
  // Colors from CSS root variables
  static const Color background = Color(0xFF06060E);
  static const Color surface1 = Color(0xFF0E0E1C);
  static const Color surface2 = Color(0xFF161626);
  static const Color surface3 = Color(0xFF1E1E30);
  static const Color surface4 = Color(0xFF282840);
  
  static const Color accent = Color(0xFFF7C948);
  static const Color accent2 = Color(0xFFFF7A3D);
  static const Color correct = Color(0xFF2EE68A);
  static const Color skip = Color(0xFFFF3F5A);
  
  static const Color blue = Color(0xFF4A9EFF);
  static const Color purple = Color(0xFF9B7EFF);
  static const Color pink = Color(0xFFFF6EBC);
  
  static const Color text = Color(0xFFEEF0FF);
  static const Color muted = Color(0xFF5E6080);
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color border2 = Color(0x26FFFFFF); // rgba(255,255,255,0.15)

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: 'Trebuchet MS',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent2,
        surface: surface1,
        background: background,
      ),
    );
  }
}
