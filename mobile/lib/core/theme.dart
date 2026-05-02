import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant Neon Palette
  static const Color background = Color(0xFF06060E);
  static const Color surface1 = Color(0xFF0E0E1C);
  static const Color surface2 = Color(0xFF161626);
  static const Color surface3 = Color(0xFF1E1E30);
  
  static const Color accent = Color(0xFFF7C948); // Golden Yellow
  static const Color accent2 = Color(0xFFFF7A3D); // Electric Orange
  static const Color primary = Color(0xFF7B61FF); // Vibrant Purple
  static const Color secondary = Color(0xFFFF4D94); // Hot Pink
  
  static const Color correct = Color(0xFF00FFA3); // Neon Green
  static const Color skip = Color(0xFFFF2D55); // Neon Red
  
  static const Color blue = Color(0xFF00B2FF);
  static const Color purple = Color(0xFF9B7EFF);
  static const Color pink = Color(0xFFFF6EBC);
  
  static const Color text = Color(0xFFEEF0FF);
  static const Color muted = Color(0xFF7E81A6);
  static const Color border = Color(0x1F7B61FF); // Glowing purple border
  static const Color border2 = Color(0x3D7B61FF);

  // Aliases
  static const Color bg = background;
  static const Color s1 = surface1;
  static const Color s2 = surface2;
  static const Color s3 = surface3;
  static const Color acc = accent;
  static const Color cor = correct;
  static const Color skp = skip;
  static const Color mut = muted;
  static const Color pur = purple;

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      fontFamily: 'Trebuchet MS',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text, fontSize: 16),
        bodyMedium: TextStyle(color: text),
        displayLarge: TextStyle(color: text, fontWeight: FontWeight.w900),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface1,
        background: background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: primary.withOpacity(0.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border2, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}
