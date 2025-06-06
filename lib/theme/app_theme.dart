// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: Color(0xFF2D6A4F),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Color(0xFFA98467),
      tertiary: Color(0xFFDDA15E),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineSmall:
          GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.inter(fontSize: 14),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    scaffoldBackgroundColor: Colors.white,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 10,
    ),
  );
}
