import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SemSeatTheme {
  static ThemeData theme = ThemeData(
    useMaterial3: true,

    // 🌈 Background
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    // 📝 Fonts
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.lexend(
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      bodyMedium: GoogleFonts.inter(
        color: Colors.black,
      ),
    ),

    // 🧱 Neo-brutalist cards
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Colors.black, width: 3),
      ),
      elevation: 0,
      shadowColor: Colors.black,
    ),

    // 🔘 Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 3),
        ),
        textStyle: GoogleFonts.lexend(fontWeight: FontWeight.w700),
      ),
    ),

    // 📦 Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 3),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 3),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 3),
      ),
      labelStyle: GoogleFonts.inter(color: Colors.black),
    ),
  );
}