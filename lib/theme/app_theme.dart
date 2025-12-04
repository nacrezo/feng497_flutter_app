import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00E5FF); // Cyan Accent
  static const Color secondaryColor = Color(0xFF2979FF); // Deep Blue Accent
  static const Color backgroundColor = Color(0xFF0A0E21); // Dark Navy
  static const Color surfaceColor = Color(0xFF1D1E33); // Slightly lighter navy
  static const Color errorColor = Color(0xFFFF5252); // Red Accent
  static const Color warningColor = Color(0xFFFFAB40); // Orange Accent

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
