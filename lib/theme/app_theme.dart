import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme([Brightness brightness = Brightness.light]) {
  const primaryGreen = Color(0xFF2D6A4F);
  const softBrown = Color(0xFFA98467);
  const warmAccent = Color(0xFFDDA15E);
  const lightBackground = Color(0xFFF7FAF7);
  const darkBackground = Color(0xFF0F1713);

  final isDark = brightness == Brightness.dark;
  final scaffoldColor = isDark ? darkBackground : lightBackground;
  final cardColor = isDark ? const Color(0xFF17211C) : Colors.white;
  final baseForeground =
      isDark ? const Color(0xFFF2F5F1) : const Color(0xFF1B2320);
  final subduedForeground =
      isDark ? const Color(0xFFAFBBB4) : const Color(0xFF66736B);

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
      color: subduedForeground,
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
  ).apply(
    bodyColor: baseForeground,
    displayColor: baseForeground,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    primaryColor: primaryGreen,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: brightness,
      primary: primaryGreen,
      secondary: softBrown,
      tertiary: warmAccent,
      surface: cardColor,
    ),
    textTheme: baseTextTheme,
    scaffoldBackgroundColor: scaffoldColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: baseForeground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: isDark ? const Color(0xFF27332C) : const Color(0xFFE6ECE7),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
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
        side: BorderSide(
          color: isDark ? const Color(0xFF33423A) : const Color(0xFFD6DED8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF18231D) : Colors.white,
      hintStyle: baseTextTheme.bodyLarge?.copyWith(
        color: isDark ? const Color(0xFF92A098) : const Color(0xFF7A857F),
      ),
      labelStyle: baseTextTheme.bodyLarge?.copyWith(
        color: isDark ? const Color(0xFFAAB7B0) : const Color(0xFF5D695F),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF314038) : const Color(0xFFDDE6E0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      elevation: 0,
      selectedLabelStyle: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: baseTextTheme.labelMedium,
      selectedItemColor: primaryGreen,
      unselectedItemColor: subduedForeground,
    ),
    chipTheme: ChipThemeData(
      labelStyle: baseTextTheme.labelMedium ?? const TextStyle(fontSize: 12.5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: subduedForeground,
      textColor: baseForeground,
    ),
  );
}
