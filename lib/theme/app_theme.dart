import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  const primaryGreen = Color(0xFF2D6A4F);
  const softBrown = Color(0xFFA98467);
  const warmAccent = Color(0xFFDDA15E);
  const pageBackground = Color(0xFFF7FAF7);

  final baseTextTheme = GoogleFonts.interTextTheme().copyWith(
    headlineSmall: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.18,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.25,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.3,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.25,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.grey[600],
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    primaryColor: primaryGreen,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryGreen,
      secondary: softBrown,
      tertiary: warmAccent,
    ),
    textTheme: baseTextTheme,
    scaffoldBackgroundColor: pageBackground,
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: baseTextTheme.labelLarge,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        foregroundColor: primaryGreen,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: baseTextTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: baseTextTheme.bodyLarge?.copyWith(
        color: const Color(0xFF7A857F),
      ),
      labelStyle: baseTextTheme.bodyLarge?.copyWith(
        color: const Color(0xFF5D695F),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedLabelStyle: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: baseTextTheme.labelMedium,
      selectedItemColor: primaryGreen,
      unselectedItemColor: const Color(0xFF66736B),
    ),
    chipTheme: ChipThemeData(
      labelStyle: baseTextTheme.labelMedium ?? const TextStyle(fontSize: 12.5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}
