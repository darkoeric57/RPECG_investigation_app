import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A); 
  static const Color secondary = Color(0xFFFDE047); 
  static const Color error = Color(0xFFBA1A1A);
  
  // Background Colors
  static const Color background = Color(0xFFF9F9FB);
  static const Color surfaceContainer = Color(0xFFEEEEF0);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFF64748B); // Slate 500
  static const Color textMedium = Color(0xFF475569); // Slate 600
  
  // UI Element Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputFill = Colors.white;

  // Legacy Compatibility (Aliases)
  static const Color accent = secondary;
  static const Color backgroundLight = background;
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color sidebarBg = Color(0xFF0F172A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), 
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: accent,
        surface: Colors.white,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: textDark, letterSpacing: -1),
          headlineMedium: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5),
          headlineSmall: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: primary),
          titleLarge: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: textDark),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textDark),
          bodyLarge: TextStyle(color: textDark, fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF444651)), 
          labelLarge: TextStyle(fontWeight: FontWeight.bold, color: textLight, fontSize: 12, letterSpacing: 1.1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        error: accent,
        surface: const Color(0xFF1E293B), // Slate 800
      ),
      textTheme: GoogleFonts.publicSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Colors.white54, 
          fontWeight: FontWeight.bold, 
          fontSize: 12,
          letterSpacing: 1.2,
        ),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white54,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24, width: 2),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white, 
          fontSize: 18, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
