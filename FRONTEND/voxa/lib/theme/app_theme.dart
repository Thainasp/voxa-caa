import 'package:flutter/material.dart';
import 'package:voxa/theme/app_colors.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.headerGreen, //cor de fundo padrão dos Scaffold do aplicativo.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.headerGreen,
        primary: AppColors.headerGreen,
        surface: AppColors.contentBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(// campos de entrada.
        filled: true,
        fillColor: AppColors.fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(//espaçamento
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(//bordas
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
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.headerGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
