import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxa/core/widgets/app_colors.dart';

class AppTheme {
  static ThemeData get theme {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      scaffoldBackgroundColor: AppColors.headerGreen,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().primaryTextTheme,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.headerGreen,
        primary: AppColors.headerGreen,
        surface: AppColors.contentBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: const BorderSide(
            color: AppColors.headerGreen,
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.headerGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
